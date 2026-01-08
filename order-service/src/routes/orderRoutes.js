const express = require('express');
const { pool } = require('../models/database');
const { v4: uuidv4 } = require('uuid');
const axios = require('axios');

const router = express.Router();

const PRODUCT_SERVICE_URL = process.env.PRODUCT_SERVICE_URL || 'http://localhost:4002';
const USER_SERVICE_URL = process.env.USER_SERVICE_URL || 'http://localhost:4001';

// Create new order
router.post('/', async (req, res) => {
  const { user_id, items } = req.body;

  if (!user_id || !items || items.length === 0) {
    return res.status(400).json({ error: 'user_id and items are required' });
  }

  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');

    // Validate user exists
    try {
      await axios.get(`${USER_SERVICE_URL}/users/${user_id}`);
    } catch (error) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'Invalid user_id' });
    }

    // Calculate total and validate products
    let totalAmount = 0;
    const validatedItems = [];

    for (const item of items) {
      try {
        const productResponse = await axios.get(`${PRODUCT_SERVICE_URL}/products/${item.product_id}`);
        const product = productResponse.data;

        if (product.stock_quantity < item.quantity) {
          await client.query('ROLLBACK');
          return res.status(400).json({ error: `Insufficient stock for product ${product.name}` });
        }

        const subtotal = product.price * item.quantity;
        totalAmount += subtotal;

        validatedItems.push({
          product_id: item.product_id,
          quantity: item.quantity,
          price: product.price,
          subtotal: subtotal
        });
      } catch (error) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: `Invalid product_id: ${item.product_id}` });
      }
    }

    // Create order
    const orderId = uuidv4();
    await client.query(
      'INSERT INTO orders (id, user_id, total_amount, status) VALUES ($1, $2, $3, $4)',
      [orderId, user_id, totalAmount, 'pending']
    );

    // Create order items
    for (const item of validatedItems) {
      const itemId = uuidv4();
      await client.query(
        'INSERT INTO order_items (id, order_id, product_id, quantity, price, subtotal) VALUES ($1, $2, $3, $4, $5, $6)',
        [itemId, orderId, item.product_id, item.quantity, item.price, item.subtotal]
      );
    }

    // Clear user's cart
    await client.query('DELETE FROM cart WHERE user_id = $1', [user_id]);

    await client.query('COMMIT');

    res.status(201).json({
      id: orderId,
      user_id,
      total_amount: totalAmount,
      status: 'pending',
      items: validatedItems,
      message: 'Order created successfully'
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Order creation error:', error);
    res.status(500).json({ error: 'Failed to create order' });
  } finally {
    client.release();
  }
});

// Get order by ID
router.get('/:id', async (req, res) => {
  try {
    const orderResult = await pool.query(
      'SELECT * FROM orders WHERE id = $1',
      [req.params.id]
    );

    if (orderResult.rows.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }

    const order = orderResult.rows[0];

    // Get order items
    const itemsResult = await pool.query(
      'SELECT * FROM order_items WHERE order_id = $1',
      [req.params.id]
    );

    order.items = itemsResult.rows;

    res.json(order);
  } catch (error) {
    console.error('Get order error:', error);
    res.status(500).json({ error: 'Failed to get order' });
  }
});

// Get user's orders
router.get('/user/:userId', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM orders WHERE user_id = $1 ORDER BY created_at DESC',
      [req.params.userId]
    );

    res.json(result.rows);
  } catch (error) {
    console.error('Get user orders error:', error);
    res.status(500).json({ error: 'Failed to get orders' });
  }
});

// Update order status
router.put('/:id/status', async (req, res) => {
  const { status } = req.body;
  const validStatuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled'];

  if (!validStatuses.includes(status)) {
    return res.status(400).json({ error: 'Invalid status' });
  }

  try {
    const result = await pool.query(
      'UPDATE orders SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *',
      [status, req.params.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Update order status error:', error);
    res.status(500).json({ error: 'Failed to update order status' });
  }
});

module.exports = router;
