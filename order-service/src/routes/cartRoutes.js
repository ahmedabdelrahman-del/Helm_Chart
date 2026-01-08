const express = require('express');
const { pool } = require('../models/database');
const { v4: uuidv4 } = require('uuid');
const axios = require('axios');

const router = express.Router();

const PRODUCT_SERVICE_URL = process.env.PRODUCT_SERVICE_URL || 'http://localhost:4002';

// Get user's cart
router.get('/:userId', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM cart WHERE user_id = $1',
      [req.params.userId]
    );

    // Fetch product details for each cart item
    const cartItems = await Promise.all(
      result.rows.map(async (item) => {
        try {
          const productResponse = await axios.get(`${PRODUCT_SERVICE_URL}/products/${item.product_id}`);
          return {
            ...item,
            product: productResponse.data
          };
        } catch (error) {
          return {
            ...item,
            product: null
          };
        }
      })
    );

    res.json(cartItems);
  } catch (error) {
    console.error('Get cart error:', error);
    res.status(500).json({ error: 'Failed to get cart' });
  }
});

// Add item to cart
router.post('/:userId/items', async (req, res) => {
  const { product_id, quantity } = req.body;
  const userId = req.params.userId;

  if (!product_id || !quantity || quantity < 1) {
    return res.status(400).json({ error: 'product_id and valid quantity are required' });
  }

  try {
    // Validate product exists
    try {
      await axios.get(`${PRODUCT_SERVICE_URL}/products/${product_id}`);
    } catch (error) {
      return res.status(400).json({ error: 'Invalid product_id' });
    }

    // Check if item already in cart
    const existingItem = await pool.query(
      'SELECT * FROM cart WHERE user_id = $1 AND product_id = $2',
      [userId, product_id]
    );

    let result;
    if (existingItem.rows.length > 0) {
      // Update quantity
      result = await pool.query(
        'UPDATE cart SET quantity = quantity + $1, updated_at = CURRENT_TIMESTAMP WHERE user_id = $2 AND product_id = $3 RETURNING *',
        [quantity, userId, product_id]
      );
    } else {
      // Insert new item
      const cartId = uuidv4();
      result = await pool.query(
        'INSERT INTO cart (id, user_id, product_id, quantity) VALUES ($1, $2, $3, $4) RETURNING *',
        [cartId, userId, product_id, quantity]
      );
    }

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Add to cart error:', error);
    res.status(500).json({ error: 'Failed to add item to cart' });
  }
});

// Remove item from cart
router.delete('/:userId/items/:itemId', async (req, res) => {
  try {
    const result = await pool.query(
      'DELETE FROM cart WHERE id = $1 AND user_id = $2 RETURNING *',
      [req.params.itemId, req.params.userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Cart item not found' });
    }

    res.json({ message: 'Item removed from cart' });
  } catch (error) {
    console.error('Remove from cart error:', error);
    res.status(500).json({ error: 'Failed to remove item from cart' });
  }
});

// Clear user's cart
router.delete('/:userId', async (req, res) => {
  try {
    await pool.query('DELETE FROM cart WHERE user_id = $1', [req.params.userId]);
    res.json({ message: 'Cart cleared successfully' });
  } catch (error) {
    console.error('Clear cart error:', error);
    res.status(500).json({ error: 'Failed to clear cart' });
  }
});

module.exports = router;
