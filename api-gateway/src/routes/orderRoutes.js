const express = require('express');
const axios = require('axios');
const router = express.Router();

const ORDER_SERVICE_URL = process.env.ORDER_SERVICE_URL || 'http://localhost:4003';

// Create order
router.post('/', async (req, res, next) => {
  try {
    const response = await axios.post(`${ORDER_SERVICE_URL}/orders`, req.body, {
      headers: { Authorization: req.headers.authorization }
    });
    res.status(response.status).json(response.data);
  } catch (error) {
    if (error.response) {
      res.status(error.response.status).json(error.response.data);
    } else {
      next(error);
    }
  }
});

// Get order by ID
router.get('/:id', async (req, res, next) => {
  try {
    const response = await axios.get(`${ORDER_SERVICE_URL}/orders/${req.params.id}`, {
      headers: { Authorization: req.headers.authorization }
    });
    res.status(response.status).json(response.data);
  } catch (error) {
    if (error.response) {
      res.status(error.response.status).json(error.response.data);
    } else {
      next(error);
    }
  }
});

// Get user's orders
router.get('/user/:userId', async (req, res, next) => {
  try {
    const response = await axios.get(`${ORDER_SERVICE_URL}/orders/user/${req.params.userId}`, {
      headers: { Authorization: req.headers.authorization }
    });
    res.status(response.status).json(response.data);
  } catch (error) {
    if (error.response) {
      res.status(error.response.status).json(error.response.data);
    } else {
      next(error);
    }
  }
});

// Update order status
router.put('/:id/status', async (req, res, next) => {
  try {
    const response = await axios.put(
      `${ORDER_SERVICE_URL}/orders/${req.params.id}/status`,
      req.body,
      { headers: { Authorization: req.headers.authorization } }
    );
    res.status(response.status).json(response.data);
  } catch (error) {
    if (error.response) {
      res.status(error.response.status).json(error.response.data);
    } else {
      next(error);
    }
  }
});

// Get cart
router.get('/cart/:userId', async (req, res, next) => {
  try {
    const response = await axios.get(`${ORDER_SERVICE_URL}/cart/${req.params.userId}`, {
      headers: { Authorization: req.headers.authorization }
    });
    res.status(response.status).json(response.data);
  } catch (error) {
    if (error.response) {
      res.status(error.response.status).json(error.response.data);
    } else {
      next(error);
    }
  }
});

// Add to cart
router.post('/cart/:userId/items', async (req, res, next) => {
  try {
    const response = await axios.post(
      `${ORDER_SERVICE_URL}/cart/${req.params.userId}/items`,
      req.body,
      { headers: { Authorization: req.headers.authorization } }
    );
    res.status(response.status).json(response.data);
  } catch (error) {
    if (error.response) {
      res.status(error.response.status).json(error.response.data);
    } else {
      next(error);
    }
  }
});

// Remove from cart
router.delete('/cart/:userId/items/:itemId', async (req, res, next) => {
  try {
    const response = await axios.delete(
      `${ORDER_SERVICE_URL}/cart/${req.params.userId}/items/${req.params.itemId}`,
      { headers: { Authorization: req.headers.authorization } }
    );
    res.status(response.status).json(response.data);
  } catch (error) {
    if (error.response) {
      res.status(error.response.status).json(error.response.data);
    } else {
      next(error);
    }
  }
});

module.exports = router;
