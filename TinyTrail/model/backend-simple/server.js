const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const sqlite3 = require('sqlite3').verbose();
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = 8080;
const JWT_SECRET = 'dev-secret-change-me-in-production';

// Middleware
app.use(cors());
app.use(express.json());
app.use('/uploads', express.static('uploads'));

// Create uploads directory
if (!fs.existsSync('uploads')) {
    fs.mkdirSync('uploads');
}

// Database setup
const db = new sqlite3.Database('tinytrail.db');

// Initialize database
db.serialize(() => {
    // Users table
    db.run(`CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT DEFAULT 'BUYER',
        phone TEXT,
        email TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);

    // Sellers table
    db.run(`CREATE TABLE IF NOT EXISTS sellers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        shop_name TEXT NOT NULL,
        pincode TEXT NOT NULL,
        address TEXT NOT NULL,
        description TEXT,
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
        image_url TEXT,
        category TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (seller_id) REFERENCES sellers(id)
    )`);

    // Orders table
    db.run(`CREATE TABLE IF NOT EXISTS orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        buyer_id INTEGER NOT NULL,
        seller_id INTEGER NOT NULL,
        total REAL NOT NULL,
        status TEXT DEFAULT 'PENDING',
        delivery_address TEXT NOT NULL,
        payment_method TEXT,
        upi_id TEXT,
        transaction_id TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
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

    // Insert sample data
    const hashedPassword = bcrypt.hashSync('password123', 10);
    
    db.run(`INSERT OR IGNORE INTO users (username, password, role, phone, email) VALUES 
        ('admin', ?, 'ADMIN', '9876543210', 'admin@tinytrail.com'),
        ('john_buyer', ?, 'BUYER', '9876543211', 'john@example.com'),
        ('jane_seller', ?, 'SELLER', '9876543212', 'jane@example.com')`, [hashedPassword, hashedPassword, hashedPassword]);

    db.run(`INSERT OR IGNORE INTO sellers (user_id, shop_name, pincode, address, description) VALUES 
        (3, 'Jane''s Fresh Vegetables', '600001', '123 Main Street, Chennai', 'Fresh organic vegetables from local farms')`);

    db.run(`INSERT OR IGNORE INTO products (seller_id, name, description, price, pincode, category) VALUES 
        (1, 'Fresh Tomatoes', 'Organic tomatoes from local farms', 50.00, '600001', 'Vegetables'),
        (1, 'Organic Spinach', 'Fresh green spinach leaves', 30.00, '600001', 'Vegetables'),
        (1, 'Local Potatoes', 'Fresh potatoes from nearby farms', 40.00, '600001', 'Vegetables'),
        (1, 'Fresh Mangoes', 'Sweet Alphonso mangoes', 80.00, '600001', 'Fruits'),
        (1, 'Bananas', 'Fresh yellow bananas', 20.00, '600001', 'Fruits')`);
});

// JWT middleware
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.sendStatus(401);
    }

    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) return res.sendStatus(403);
        req.user = user;
        next();
    });
};

// Routes

// Auth routes
app.post('/auth/login', (req, res) => {
    const { username, password } = req.body;
    
    db.get('SELECT * FROM users WHERE username = ?', [username], (err, user) => {
        if (err) return res.status(500).json({ error: 'Database error' });
        if (!user) return res.status(401).json({ error: 'User not found' });
        
        if (!bcrypt.compareSync(password, user.password)) {
            return res.status(401).json({ error: 'Invalid password' });
        }
        
        const token = jwt.sign({ username: user.username }, JWT_SECRET);
        res.json({ token, user: { id: user.id, username: user.username, email: user.email, role: user.role } });
    });
});

app.post('/auth/register', (req, res) => {
    const { username, password, email, phone } = req.body;
    const hashedPassword = bcrypt.hashSync(password, 10);
    
    db.run('INSERT INTO users (username, password, email, phone) VALUES (?, ?, ?, ?)', 
        [username, hashedPassword, email, phone], function(err) {
            if (err) {
                return res.status(400).json({ error: 'Username already exists' });
            }
            
            const token = jwt.sign({ username }, JWT_SECRET);
            res.json({ token, user: { id: this.lastID, username, email, role: 'BUYER' } });
        });
});

app.get('/auth/me', authenticateToken, (req, res) => {
    db.get('SELECT * FROM users WHERE username = ?', [req.user.username], (err, user) => {
        if (err) return res.status(500).json({ error: 'Database error' });
        res.json({ id: user.id, username: user.username, email: user.email, role: user.role });
    });
});

// Product routes
app.get('/products/search', (req, res) => {
    const { pincode } = req.query;
    
    db.all(`SELECT p.*, s.shop_name as sellerName 
            FROM products p 
            JOIN sellers s ON p.seller_id = s.id 
            WHERE p.pincode = ?`, [pincode], (err, products) => {
        if (err) return res.status(500).json({ error: 'Database error' });
        res.json(products);
    });
});

app.get('/products/:id', (req, res) => {
    const { id } = req.params;
    
    db.get(`SELECT p.*, s.shop_name as sellerName 
            FROM products p 
            JOIN sellers s ON p.seller_id = s.id 
            WHERE p.id = ?`, [id], (err, product) => {
        if (err) return res.status(500).json({ error: 'Database error' });
        if (!product) return res.status(404).json({ error: 'Product not found' });
        res.json(product);
    });
});

app.get('/products/categories', (req, res) => {
    db.all('SELECT DISTINCT category FROM products WHERE category IS NOT NULL', (err, categories) => {
        if (err) return res.status(500).json({ error: 'Database error' });
        res.json(categories.map(c => c.category));
    });
});

// Seller routes
app.post('/seller/onboard', authenticateToken, (req, res) => {
    const { shopName, pincode, address, description } = req.body;
    
    db.get('SELECT id FROM users WHERE username = ?', [req.user.username], (err, user) => {
        if (err) return res.status(500).json({ error: 'Database error' });
        
        db.run('INSERT INTO sellers (user_id, shop_name, pincode, address, description) VALUES (?, ?, ?, ?, ?)',
            [user.id, shopName, pincode, address, description], function(err) {
                if (err) return res.status(400).json({ error: 'Seller already exists' });
                
                // Update user role to SELLER
                db.run('UPDATE users SET role = ? WHERE id = ?', ['SELLER', user.id]);
                
                res.json({ id: this.lastID, user_id: user.id, shop_name: shopName, pincode, address, description });
            });
    });
});

// Order routes
app.post('/orders', authenticateToken, (req, res) => {
    const { deliveryAddress, paymentMethod, upiId, items } = req.body;
    
    db.get('SELECT id FROM users WHERE username = ?', [req.user.username], (err, buyer) => {
        if (err) return res.status(500).json({ error: 'Database error' });
        
        // Get seller from first product
        db.get('SELECT seller_id FROM products WHERE id = ?', [items[0].productId], (err, product) => {
            if (err) return res.status(500).json({ error: 'Database error' });
            
            const total = items.reduce((sum, item) => sum + (item.price * item.quantity), 0);
            
            db.run('INSERT INTO orders (buyer_id, seller_id, total, delivery_address, payment_method, upi_id) VALUES (?, ?, ?, ?, ?, ?)',
                [buyer.id, product.seller_id, total, deliveryAddress, paymentMethod, upiId], function(err) {
                    if (err) return res.status(500).json({ error: 'Database error' });
                    
                    const orderId = this.lastID;
                    
                    // Insert order items
                    items.forEach(item => {
                        db.run('INSERT INTO order_items (order_id, product_id, quantity, price) VALUES (?, ?, ?, ?)',
                            [orderId, item.productId, item.quantity, item.price]);
                    });
                    
                    res.json({ id: orderId, buyer_id: buyer.id, seller_id: product.seller_id, total, status: 'PENDING' });
                });
        });
    });
});

app.get('/orders/buyer', authenticateToken, (req, res) => {
    db.get('SELECT id FROM users WHERE username = ?', [req.user.username], (err, user) => {
        if (err) return res.status(500).json({ error: 'Database error' });
        
        db.all('SELECT * FROM orders WHERE buyer_id = ? ORDER BY created_at DESC', [user.id], (err, orders) => {
            if (err) return res.status(500).json({ error: 'Database error' });
            res.json(orders);
        });
    });
});

// Webhook routes
app.post('/webhooks/payment', (req, res) => {
    const { orderId, status, txnId } = req.body;
    
    let orderStatus = 'PENDING';
    if (status === 'SUCCESS') orderStatus = 'CONFIRMED';
    else if (status === 'FAILED') orderStatus = 'CANCELLED';
    
    db.run('UPDATE orders SET status = ?, transaction_id = ? WHERE id = ?', 
        [orderStatus, txnId, orderId], (err) => {
            if (err) return res.status(500).json({ error: 'Database error' });
            res.json({ message: 'Webhook processed successfully' });
        });
});

// Admin routes
app.post('/admin/seed', (req, res) => {
    res.json({ message: 'Sample data already seeded' });
});

// Start server
app.listen(PORT, () => {
    console.log(`🚀 TinyTrail Backend running on http://localhost:${PORT}`);
    console.log(`📱 Mobile app should connect to this URL`);
    console.log(`🔑 Sample users: admin/password123, john_buyer/password123, jane_seller/password123`);
});

// Graceful shutdown
process.on('SIGINT', () => {
    console.log('\n🛑 Shutting down server...');
    db.close();
    process.exit(0);
});

