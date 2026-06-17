require('express-async-errors');
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const sqlite3 = require('sqlite3').verbose();
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 8080;
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';
const DB_PATH = process.env.DB_PATH || path.join(__dirname, 'tinytrail.db');

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Database initialization
const db = new sqlite3.Database(DB_PATH, (err) => {
  if (err) {
    console.error('❌ Database connection error:', err);
  } else {
    console.log('✅ Connected to SQLite database');
    initializeDatabase();
  }
});

// Promisified database calls
const dbRun = (sql, params = []) => {
  return new Promise((resolve, reject) => {
    db.run(sql, params, function(err) {
      if (err) reject(err);
      else resolve(this);
    });
  });
};

const dbGet = (sql, params = []) => {
  return new Promise((resolve, reject) => {
    db.get(sql, params, (err, row) => {
      if (err) reject(err);
      else resolve(row);
    });
  });
};

const dbAll = (sql, params = []) => {
  return new Promise((resolve, reject) => {
    db.all(sql, params, (err, rows) => {
      if (err) reject(err);
      else resolve(rows);
    });
  });
};

// Initialize database schema
function initializeDatabase() {
  db.serialize(() => {
    // Users table
    db.run(`CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL,
      email TEXT UNIQUE NOT NULL,
      phone TEXT,
      role TEXT DEFAULT 'BUYER',
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);

    // Sellers table
    db.run(`CREATE TABLE IF NOT EXISTS sellers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL UNIQUE,
      shop_name TEXT NOT NULL,
      shop_description TEXT,
      pincode TEXT NOT NULL,
      address TEXT NOT NULL,
      avatar_url TEXT,
      verified INTEGER DEFAULT 0,
      rating REAL DEFAULT 5.0,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id)
    )`);

    // Products table
    db.run(`CREATE TABLE IF NOT EXISTS products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      seller_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      description TEXT NOT NULL,
      price REAL NOT NULL,
      pincode TEXT NOT NULL,
      category TEXT,
      image_url TEXT,
      in_stock INTEGER DEFAULT 1,
      rating REAL DEFAULT 5.0,
      reviews_count INTEGER DEFAULT 0,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (seller_id) REFERENCES sellers(id)
    )`);

    // Cart items table
    db.run(`CREATE TABLE IF NOT EXISTS cart_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      product_id INTEGER NOT NULL,
      quantity INTEGER NOT NULL DEFAULT 1,
      added_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id),
      FOREIGN KEY (product_id) REFERENCES products(id)
    )`);

    // Orders table
    db.run(`CREATE TABLE IF NOT EXISTS orders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      buyer_id INTEGER NOT NULL,
      seller_id INTEGER NOT NULL,
      total REAL NOT NULL,
      status TEXT DEFAULT 'PENDING',
      payment_method TEXT,
      delivery_address TEXT NOT NULL,
      phone TEXT NOT NULL,
      tracking_id TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (buyer_id) REFERENCES users(id),
      FOREIGN KEY (seller_id) REFERENCES sellers(id)
    )`);

    // Order items table
    db.run(`CREATE TABLE IF NOT EXISTS order_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      order_id INTEGER NOT NULL,
      product_id INTEGER NOT NULL,
      quantity INTEGER NOT NULL,
      price REAL NOT NULL,
      FOREIGN KEY (order_id) REFERENCES orders(id),
      FOREIGN KEY (product_id) REFERENCES products(id)
    )`);

    // Seed sample data
    seedDatabase();
  });
}

async function seedDatabase() {
  try {
    const userCount = await dbGet('SELECT COUNT(*) as count FROM users');
    
    if (userCount.count === 0) {
      console.log('🌱 Seeding sample data...');
      
      const hashedPassword = await bcrypt.hash('password123', 10);
      
      // Create sample users
      const adminRes = await dbRun(
        'INSERT INTO users (username, password, email, phone, role) VALUES (?, ?, ?, ?, ?)',
        ['admin', hashedPassword, 'admin@tinytrail.com', '9000000000', 'ADMIN']
      );
      
      const buyerRes = await dbRun(
        'INSERT INTO users (username, password, email, phone, role) VALUES (?, ?, ?, ?, ?)',
        ['john_buyer', hashedPassword, 'john@example.com', '9876543210', 'BUYER']
      );
      
      const sellerRes = await dbRun(
        'INSERT INTO users (username, password, email, phone, role) VALUES (?, ?, ?, ?, ?)',
        ['jane_seller', hashedPassword, 'jane@example.com', '9876543212', 'SELLER']
      );

      // Create seller profile
      await dbRun(
        `INSERT INTO sellers (user_id, shop_name, shop_description, pincode, address, avatar_url, verified, rating)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [sellerRes.lastID, "Jane's Fresh Market", 'Fresh organic produce from local farms', '600001', 
         '123 Main Street, Chennai', 'https://via.placeholder.com/200', 1, 4.8]
      );

      // Create sample products
      const products = [
        { name: 'Fresh Tomatoes', desc: 'Organic tomatoes from local farms', price: 50, category: 'Vegetables' },
        { name: 'Organic Spinach', desc: 'Fresh green spinach leaves', price: 30, category: 'Vegetables' },
        { name: 'Local Potatoes', desc: 'Fresh potatoes from nearby farms', price: 40, category: 'Vegetables' },
        { name: 'Fresh Mangoes', desc: 'Sweet Alphonso mangoes', price: 80, category: 'Fruits' },
        { name: 'Bananas', desc: 'Fresh yellow bananas', price: 20, category: 'Fruits' },
        { name: 'Carrots', desc: 'Orange carrots rich in beta-carotene', price: 35, category: 'Vegetables' },
        { name: 'Cabbage', desc: 'Fresh green cabbage', price: 25, category: 'Vegetables' },
        { name: 'Apples', desc: 'Red apples from Kashmir', price: 100, category: 'Fruits' }
      ];

      for (const product of products) {
        await dbRun(
          `INSERT INTO products (seller_id, name, description, price, pincode, category, image_url, rating)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
          [sellerRes.lastID, product.name, product.desc, product.price, '600001', product.category, 
           'https://via.placeholder.com/300', 4.5]
        );
      }

      console.log('✅ Sample data seeded successfully');
    }
  } catch (error) {
    console.error('Error seeding database:', error);
  }
}

// JWT middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ error: 'Invalid token' });
    req.user = user;
    next();
  });
};

// ============ AUTH ROUTES ============

app.post('/api/auth/register', async (req, res) => {
  try {
    const { username, password, email, phone } = req.body;
    
    if (!username || !password || !email) {
      return res.status(400).json({ error: 'Username, password, and email required' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    
    const result = await dbRun(
      'INSERT INTO users (username, password, email, phone, role) VALUES (?, ?, ?, ?, ?)',
      [username, hashedPassword, email, phone || '', 'BUYER']
    );

    const token = jwt.sign({ id: result.lastID, username, role: 'BUYER' }, JWT_SECRET, { expiresIn: '7d' });
    
    res.json({ 
      success: true,
      token, 
      user: { id: result.lastID, username, email, role: 'BUYER' } 
    });
  } catch (error) {
    console.error('Register error:', error);
    res.status(400).json({ error: error.message || 'Registration failed' });
  }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    
    if (!username || !password) {
      return res.status(400).json({ error: 'Username and password required' });
    }

    const user = await dbGet('SELECT * FROM users WHERE username = ?', [username]);
    
    if (!user) {
      return res.status(401).json({ error: 'User not found' });
    }

    const validPassword = await bcrypt.compare(password, user.password);
    
    if (!validPassword) {
      return res.status(401).json({ error: 'Invalid password' });
    }

    const token = jwt.sign({ id: user.id, username: user.username, role: user.role }, JWT_SECRET, { expiresIn: '7d' });
    
    res.json({ 
      success: true,
      token, 
      user: { id: user.id, username: user.username, email: user.email, role: user.role } 
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Login failed' });
  }
});

app.get('/api/auth/me', authenticateToken, async (req, res) => {
  try {
    const user = await dbGet('SELECT id, username, email, role, phone FROM users WHERE id = ?', [req.user.id]);
    res.json(user);
  } catch (error) {
    res.status(500).json({ error: 'Failed to get user info' });
  }
});

// ============ PRODUCT ROUTES ============

app.get('/api/products', async (req, res) => {
  try {
    const { pincode, category } = req.query;
    let query = 'SELECT p.*, s.shop_name FROM products p JOIN sellers s ON p.seller_id = s.id WHERE 1=1';
    const params = [];

    if (pincode) {
      query += ' AND p.pincode = ?';
      params.push(pincode);
    }

    if (category) {
      query += ' AND p.category = ?';
      params.push(category);
    }

    query += ' ORDER BY p.created_at DESC LIMIT 50';
    
    const products = await dbAll(query, params);
    res.json({ success: true, products });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch products' });
  }
});

app.get('/api/products/search', async (req, res) => {
  try {
    const { q, pincode } = req.query;
    let query = 'SELECT p.*, s.shop_name FROM products p JOIN sellers s ON p.seller_id = s.id WHERE 1=1';
    const params = [];

    if (q) {
      query += ' AND (p.name LIKE ? OR p.description LIKE ?)';
      params.push(`%${q}%`, `%${q}%`);
    }

    if (pincode) {
      query += ' AND p.pincode = ?';
      params.push(pincode);
    }

    query += ' ORDER BY p.created_at DESC LIMIT 50';
    
    const products = await dbAll(query, params);
    res.json({ success: true, products });
  } catch (error) {
    res.status(500).json({ error: 'Search failed' });
  }
});

app.get('/api/products/:id', async (req, res) => {
  try {
    const product = await dbGet(
      `SELECT p.*, s.shop_name, s.shop_description, s.avatar_url 
       FROM products p 
       JOIN sellers s ON p.seller_id = s.id 
       WHERE p.id = ?`,
      [req.params.id]
    );

    if (!product) {
      return res.status(404).json({ error: 'Product not found' });
    }

    res.json({ success: true, product });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch product' });
  }
});

app.get('/api/categories', async (req, res) => {
  try {
    const categories = await dbAll('SELECT DISTINCT category FROM products ORDER BY category');
    res.json({ success: true, categories: categories.map(c => c.category) });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch categories' });
  }
});

// ============ CART ROUTES ============

app.post('/api/cart/add', authenticateToken, async (req, res) => {
  try {
    const { productId, quantity = 1 } = req.body;
    
    const existing = await dbGet(
      'SELECT * FROM cart_items WHERE user_id = ? AND product_id = ?',
      [req.user.id, productId]
    );

    if (existing) {
      await dbRun(
        'UPDATE cart_items SET quantity = quantity + ? WHERE user_id = ? AND product_id = ?',
        [quantity, req.user.id, productId]
      );
    } else {
      await dbRun(
        'INSERT INTO cart_items (user_id, product_id, quantity) VALUES (?, ?, ?)',
        [req.user.id, productId, quantity]
      );
    }

    res.json({ success: true, message: 'Item added to cart' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to add to cart' });
  }
});

app.post('/api/cart/remove', authenticateToken, async (req, res) => {
  try {
    const { productId } = req.body;
    
    await dbRun(
      'DELETE FROM cart_items WHERE user_id = ? AND product_id = ?',
      [req.user.id, productId]
    );

    res.json({ success: true, message: 'Item removed from cart' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to remove from cart' });
  }
});

app.get('/api/cart', authenticateToken, async (req, res) => {
  try {
    const items = await dbAll(
      `SELECT c.id, c.quantity, p.* 
       FROM cart_items c 
       JOIN products p ON c.product_id = p.id 
       WHERE c.user_id = ? 
       ORDER BY c.added_at DESC`,
      [req.user.id]
    );

    const total = items.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    
    res.json({ success: true, items, total, count: items.length });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch cart' });
  }
});

app.post('/api/cart/clear', authenticateToken, async (req, res) => {
  try {
    await dbRun('DELETE FROM cart_items WHERE user_id = ?', [req.user.id]);
    res.json({ success: true, message: 'Cart cleared' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to clear cart' });
  }
});

// ============ ORDER ROUTES ============

app.post('/api/orders', authenticateToken, async (req, res) => {
  try {
    const { deliveryAddress, phone, paymentMethod } = req.body;

    if (!deliveryAddress || !phone) {
      return res.status(400).json({ error: 'Delivery address and phone required' });
    }

    // Get cart items
    const cartItems = await dbAll(
      `SELECT c.quantity, p.*, p.seller_id 
       FROM cart_items c 
       JOIN products p ON c.product_id = p.id 
       WHERE c.user_id = ?`,
      [req.user.id]
    );

    if (cartItems.length === 0) {
      return res.status(400).json({ error: 'Cart is empty' });
    }

    // Group by seller and create orders
    const ordersBySeller = {};
    for (const item of cartItems) {
      if (!ordersBySeller[item.seller_id]) {
        ordersBySeller[item.seller_id] = [];
      }
      ordersBySeller[item.seller_id].push(item);
    }

    const orders = [];
    for (const [sellerId, items] of Object.entries(ordersBySeller)) {
      const total = items.reduce((sum, item) => sum + (item.price * item.quantity), 0);
      
      const result = await dbRun(
        `INSERT INTO orders (buyer_id, seller_id, total, delivery_address, phone, payment_method, status)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [req.user.id, sellerId, total, deliveryAddress, phone, paymentMethod || 'COD', 'CONFIRMED']
      );

      // Add order items
      for (const item of items) {
        await dbRun(
          'INSERT INTO order_items (order_id, product_id, quantity, price) VALUES (?, ?, ?, ?)',
          [result.lastID, item.id, item.quantity, item.price]
        );
      }

      orders.push({
        id: result.lastID,
        seller_id: sellerId,
        total,
        status: 'CONFIRMED'
      });
    }

    // Clear cart
    await dbRun('DELETE FROM cart_items WHERE user_id = ?', [req.user.id]);

    res.json({ 
      success: true, 
      message: 'Orders placed successfully',
      orders 
    });
  } catch (error) {
    console.error('Order error:', error);
    res.status(500).json({ error: 'Failed to place order' });
  }
});

app.get('/api/orders', authenticateToken, async (req, res) => {
  try {
    const orders = await dbAll(
      `SELECT o.*, s.shop_name 
       FROM orders o 
       JOIN sellers s ON o.seller_id = s.id 
       WHERE o.buyer_id = ? 
       ORDER BY o.created_at DESC`,
      [req.user.id]
    );

    res.json({ success: true, orders });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch orders' });
  }
});

app.get('/api/orders/:id', authenticateToken, async (req, res) => {
  try {
    const order = await dbGet(
      `SELECT o.*, s.shop_name 
       FROM orders o 
       JOIN sellers s ON o.seller_id = s.id 
       WHERE o.id = ? AND o.buyer_id = ?`,
      [req.params.id, req.user.id]
    );

    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }

    const items = await dbAll(
      `SELECT oi.*, p.name, p.description 
       FROM order_items oi 
       JOIN products p ON oi.product_id = p.id 
       WHERE oi.order_id = ?`,
      [req.params.id]
    );

    res.json({ success: true, order, items });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch order' });
  }
});

// ============ SELLER ROUTES ============

app.post('/api/seller/onboard', authenticateToken, async (req, res) => {
  try {
    const { shopName, shopDescription, pincode, address } = req.body;

    if (!shopName || !pincode || !address) {
      return res.status(400).json({ error: 'Shop name, pincode, and address required' });
    }

    const result = await dbRun(
      `INSERT INTO sellers (user_id, shop_name, shop_description, pincode, address, avatar_url)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [req.user.id, shopName, shopDescription || '', pincode, address, 'https://via.placeholder.com/200']
    );

    await dbRun('UPDATE users SET role = ? WHERE id = ?', ['SELLER', req.user.id]);

    res.json({ 
      success: true, 
      seller: {
        id: result.lastID,
        shop_name: shopName,
        pincode,
        address
      }
    });
  } catch (error) {
    res.status(400).json({ error: error.message || 'Failed to onboard as seller' });
  }
});

app.get('/api/sellers/:id', async (req, res) => {
  try {
    const seller = await dbGet(
      'SELECT * FROM sellers WHERE id = ?',
      [req.params.id]
    );

    if (!seller) {
      return res.status(404).json({ error: 'Seller not found' });
    }

    const products = await dbAll(
      'SELECT * FROM products WHERE seller_id = ?',
      [req.params.id]
    );

    res.json({ success: true, seller, products });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch seller' });
  }
});

// ============ ERROR HANDLING ============

app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(err.status || 500).json({ error: err.message || 'Internal server error' });
});

app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// ============ START SERVER ============

app.listen(PORT, () => {
  console.log(`\n✅ TinyTrail Backend running on http://localhost:${PORT}`);
  console.log(`📚 API Documentation: http://localhost:${PORT}/api`);
  console.log(`\n🔑 Sample credentials:`);
  console.log(`   Username: admin / Password: password123`);
  console.log(`   Username: john_buyer / Password: password123`);
  console.log(`   Username: jane_seller / Password: password123\n`);
});

process.on('SIGINT', () => {
  console.log('\n🛑 Server shutting down...');
  db.close();
  process.exit(0);
});

module.exports = app;
