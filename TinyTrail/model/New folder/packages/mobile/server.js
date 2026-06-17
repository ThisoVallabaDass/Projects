#!/usr/bin/env node

/**
 * TinyTrail Mobile Demo Server
 * Simulates mobile app functionality through a web interface
 * Runs on http://localhost:3001
 */

const express = require('express');
const path = require('path');
const axios = require('axios');
const app = express();
const PORT = 3001;

const API_URL = 'http://localhost:8080/api';

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// In-memory session storage
let sessionUser = null;
let sessionToken = null;

// Login endpoint
app.post('/api/login', async (req, res) => {
  const { username, password } = req.body;
  try {
    const response = await axios.post(`${API_URL}/auth/login`, {
      username,
      password,
    });
    sessionUser = response.data.user;
    sessionToken = response.data.token;
    res.json({ success: true, user: response.data.user });
  } catch (error) {
    res.status(401).json({ error: 'Login failed' });
  }
});

// Register endpoint
app.post('/api/register', async (req, res) => {
  const { username, email, phone, password } = req.body;
  try {
    const response = await axios.post(`${API_URL}/auth/register`, {
      username,
      email,
      phone,
      password,
    });
    sessionUser = response.data.user;
    sessionToken = response.data.token;
    res.json({ success: true, user: response.data.user });
  } catch (error) {
    res.status(400).json({ error: error.response?.data?.error || 'Registration failed' });
  }
});

// Get current user
app.get('/api/user', (req, res) => {
  if (!sessionUser) {
    return res.status(401).json({ error: 'Not authenticated' });
  }
  res.json(sessionUser);
});

// Logout
app.post('/api/logout', (req, res) => {
  sessionUser = null;
  sessionToken = null;
  res.json({ success: true });
});

// Products proxy
app.get('/api/products', async (req, res) => {
  try {
    const response = await axios.get(`${API_URL}/products`, { params: req.query });
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch products' });
  }
});

// Cart endpoints
app.get('/api/cart', async (req, res) => {
  if (!sessionToken) {
    return res.status(401).json({ error: 'Not authenticated' });
  }
  try {
    const response = await axios.get(`${API_URL}/cart`, {
      headers: { Authorization: `Bearer ${sessionToken}` },
    });
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch cart' });
  }
});

app.post('/api/cart/add', async (req, res) => {
  if (!sessionToken) {
    return res.status(401).json({ error: 'Not authenticated' });
  }
  try {
    const response = await axios.post(`${API_URL}/cart/add`, req.body, {
      headers: { Authorization: `Bearer ${sessionToken}` },
    });
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: 'Failed to add to cart' });
  }
});

app.post('/api/cart/remove', async (req, res) => {
  if (!sessionToken) {
    return res.status(401).json({ error: 'Not authenticated' });
  }
  try {
    const response = await axios.post(`${API_URL}/cart/remove`, req.body, {
      headers: { Authorization: `Bearer ${sessionToken}` },
    });
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: 'Failed to remove from cart' });
  }
});

// Orders endpoints
app.get('/api/orders', async (req, res) => {
  if (!sessionToken) {
    return res.status(401).json({ error: 'Not authenticated' });
  }
  try {
    const response = await axios.get(`${API_URL}/orders`, {
      headers: { Authorization: `Bearer ${sessionToken}` },
    });
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch orders' });
  }
});

app.post('/api/orders', async (req, res) => {
  if (!sessionToken) {
    return res.status(401).json({ error: 'Not authenticated' });
  }
  try {
    const response = await axios.post(`${API_URL}/orders`, req.body, {
      headers: { Authorization: `Bearer ${sessionToken}` },
    });
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: 'Failed to create order' });
  }
});

app.listen(PORT, () => {
  console.log(`\n🎉 TinyTrail Mobile Demo Server running!`);
  console.log(`📱 Mobile Simulator: http://localhost:${PORT}`);
  console.log(`\n📝 Demo Credentials:`);
  console.log(`   Username: admin OR john_buyer OR jane_seller`);
  console.log(`   Password: password123\n`);
});
