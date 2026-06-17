const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const sqlite3 = require('sqlite3').verbose();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { spawn } = require('child_process');
const axios = require('axios');
const FormData = require('form-data');
require('dotenv').config();

let firestore = null;
let firebaseAuth = null;
try {
    // Firebase is optional during local dev; SQLite fallback remains available.
    // When configured, new endpoints will use Firestore + Firebase Auth.
    ({ firestore, firebaseAuth } = require('./firebaseAdmin'));
} catch (e) {
    console.warn('⚠️ Firebase Admin not initialized. Set FIREBASE_SERVICE_ACCOUNT_PATH to enable Firestore.', e.message);
}

const app = express();
const PORT = 8080;
const JWT_SECRET = 'dev-secret-change-me-in-production';
const UPLOADS_DIR = path.join(__dirname, 'uploads');
const WEB_APP_DIR = path.join(__dirname, 'public');
const HYGIENE_SCRIPT_PATH =
    process.env.HYGIENE_SCRIPT_PATH || path.resolve(__dirname, '..', '..', 'Hygine', 'api_predict.py');
const overnightModelPath = path.resolve(__dirname, '..', '..', 'Hygine', 'models', 'hygiene_model_overnight.pth');
const HYGIENE_MODEL_PATH =
    process.env.HYGIENE_MODEL_PATH ||
    (fs.existsSync(overnightModelPath)
        ? overnightModelPath
        : path.resolve(__dirname, '..', '..', 'Hygine', 'models', 'hygiene_model.pth'));

// ============================================================================
// MIDDLEWARE
// ============================================================================

// Enable CORS for all routes
app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));

app.use(express.json());
app.use('/uploads', express.static(UPLOADS_DIR));
app.use(express.static(WEB_APP_DIR));

// Create uploads directory
if (!fs.existsSync(UPLOADS_DIR)) {
    fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}

const ensureUploadSubdirectory = (folderName) => {
    const fullPath = path.join(UPLOADS_DIR, folderName);
    if (!fs.existsSync(fullPath)) {
        fs.mkdirSync(fullPath, { recursive: true });
    }
    return fullPath;
};

const uploadStorage = multer.diskStorage({
    destination: (_req, file, cb) => {
        const targetFolder = file.fieldname === 'workspaceImage' ? 'hygiene' : 'products';
        cb(null, ensureUploadSubdirectory(targetFolder));
    },
    filename: (_req, file, cb) => {
        const extension = path.extname(file.originalname || '') || '.jpg';
        cb(null, `${Date.now()}-${Math.round(Math.random() * 1e9)}${extension}`);
    },
});

const upload = multer({ storage: uploadStorage });

const toPublicUploadPath = (absolutePath) => {
    const relativePath = path.relative(UPLOADS_DIR, absolutePath).replace(/\\/g, '/');
    return `/uploads/${relativePath}`;
};

const findVendorByUserId = (userId) =>
    new Promise((resolve, reject) => {
        db.get('SELECT * FROM vendors WHERE user_id = ? ORDER BY id DESC LIMIT 1', [userId], (err, vendor) => {
            if (err) {
                reject(err);
                return;
            }
            resolve(vendor || null);
        });
    });

const runPythonPrediction = (command, args) =>
    new Promise((resolve, reject) => {
        const child = spawn(command, args, { cwd: path.dirname(HYGIENE_SCRIPT_PATH) });
        let stdout = '';
        let stderr = '';

        child.stdout.on('data', (chunk) => {
            stdout += chunk.toString();
        });

        child.stderr.on('data', (chunk) => {
            stderr += chunk.toString();
        });

        child.on('error', reject);
        child.on('close', (code) => {
            if (code !== 0) {
                reject(new Error(stderr || `Prediction process exited with code ${code}`));
                return;
            }

            try {
                resolve(JSON.parse(stdout.trim()));
            } catch (error) {
                reject(new Error(`Prediction output was not valid JSON: ${stdout || stderr}`));
            }
        });
    });

const runHygienePrediction = async (imagePath) => {
    const args = [HYGIENE_SCRIPT_PATH, imagePath, '--model-path', HYGIENE_MODEL_PATH];

    try {
        return await runPythonPrediction(process.env.PYTHON_BIN || 'python', args);
    } catch (error) {
        return runPythonPrediction('py', ['-3', ...args]);
    }
};

// ============================================================================
// FIREBASE AUTH MIDDLEWARE (preferred)
// ============================================================================

const authenticateFirebase = async (req, res, next) => {
    if (!firebaseAuth) {
        return res.status(500).json({ error: 'Firebase Auth is not configured on this backend' });
    }

    const authHeader = req.headers['authorization'] || '';
    const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;

    if (!token) {
        return res.status(401).json({ error: 'No token provided' });
    }

    try {
        const decoded = await firebaseAuth.verifyIdToken(token);
        req.firebaseUser = { uid: decoded.uid, email: decoded.email || null };
        next();
    } catch (err) {
        return res.status(401).json({ error: 'Invalid token' });
    }
};

// ============================================================================
// DATABASE SETUP
// ============================================================================

const db = new sqlite3.Database('tinytrail.db', (err) => {
    if (err) {
        console.error('Database error:', err);
    } else {
        console.log('✅ Connected to SQLite database');
    }
});

// Initialize database schema
db.serialize(() => {
    // Users table
    db.run(`CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        email TEXT UNIQUE,
        phone TEXT,
        role TEXT DEFAULT 'BUYER',
        preferred_locale TEXT DEFAULT 'en',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);
    db.run(`CREATE UNIQUE INDEX IF NOT EXISTS idx_users_phone_unique
            ON users(phone)
            WHERE phone IS NOT NULL AND phone != ''`);

    // Vendors table
    db.run(`CREATE TABLE IF NOT EXISTS vendors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        shop_name TEXT NOT NULL,
        story_text TEXT,
        story_video_url TEXT,
        pincode TEXT NOT NULL,
        address TEXT,
        avatar_url TEXT,
        is_verified_home_kitchen INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id)
    )`);

    // Products table
    db.run(`CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vendor_id INTEGER,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        pincode TEXT,
        image_url TEXT,
        category TEXT,
        custom_options TEXT,
        is_subscription_item INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (vendor_id) REFERENCES vendors(id)
    )`);

    // Subscription plans
    db.run(`CREATE TABLE IF NOT EXISTS subscription_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vendor_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        frequency TEXT DEFAULT 'WEEKLY',
        details_json TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (vendor_id) REFERENCES vendors(id)
    )`);

    // Subscriptions
    db.run(`CREATE TABLE IF NOT EXISTS subscriptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        plan_id INTEGER NOT NULL,
        status TEXT DEFAULT 'ACTIVE',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        expires_at DATETIME,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (plan_id) REFERENCES subscription_plans(id)
    )`);

    // Orders table
    db.run(`CREATE TABLE IF NOT EXISTS orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        buyer_id INTEGER NOT NULL,
        vendor_id INTEGER,
        total REAL NOT NULL,
        status TEXT DEFAULT 'PENDING',
        delivery_address TEXT NOT NULL,
        payment_method TEXT,
        upi_id TEXT,
        transaction_id TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (buyer_id) REFERENCES users(id),
        FOREIGN KEY (vendor_id) REFERENCES vendors(id)
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

    // Collaborative carts
    db.run(`CREATE TABLE IF NOT EXISTS collaborative_carts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cart_code TEXT UNIQUE NOT NULL,
        items_json TEXT,
        expires_at DATETIME,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);

    // Jobs for async operations
    db.run(`CREATE TABLE IF NOT EXISTS jobs (
        id TEXT PRIMARY KEY,
        user_id INTEGER,
        job_type TEXT,
        status TEXT DEFAULT 'PENDING',
        result_json TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);

    db.run(`CREATE TABLE IF NOT EXISTS vendor_hygiene_checks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vendor_id INTEGER NOT NULL,
        image_url TEXT NOT NULL,
        predicted_class TEXT NOT NULL,
        confidence REAL NOT NULL,
        hygiene_score INTEGER NOT NULL,
        badge_text TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (vendor_id) REFERENCES vendors(id)
    )`);

    // Seed sample data
    const hashedPassword = bcrypt.hashSync('password123', 10);
    
    db.run(`INSERT OR IGNORE INTO users (username, password, email, role, phone) VALUES 
        ('admin', ?, 'admin@tinytrail.com', 'ADMIN', '9876543210'),
        ('john_buyer', ?, 'john@example.com', 'BUYER', '9876543211'),
        ('jane_seller', ?, 'jane@example.com', 'SELLER', '9876543212')`, 
        [hashedPassword, hashedPassword, hashedPassword],
        (err) => {
            if (!err) console.log('✅ Sample users created');
        }
    );

    db.run(`INSERT OR IGNORE INTO vendors (user_id, shop_name, pincode, address, story_text) VALUES 
        (3, 'Jane Fresh Vegetables', '600001', '123 Main Street, Chennai', 'Fresh organic vegetables from local farms')`,
        (err) => {
            if (!err) console.log('✅ Sample vendor created');
        }
    );

    db.run(`INSERT OR IGNORE INTO products (vendor_id, name, description, price, pincode, category) VALUES 
        (1, 'Fresh Tomatoes', 'Organic tomatoes from local farms', 50.00, '600001', 'Vegetables'),
        (1, 'Organic Spinach', 'Fresh green spinach leaves', 30.00, '600001', 'Vegetables'),
        (1, 'Local Potatoes', 'Fresh potatoes from nearby farms', 40.00, '600001', 'Vegetables'),
        (1, 'Fresh Mangoes', 'Sweet Alphonso mangoes', 80.00, '600001', 'Fruits'),
        (1, 'Bananas', 'Fresh yellow bananas', 20.00, '600001', 'Fruits')`,
        (err) => {
            if (!err) console.log('✅ Sample products created');
        }
    );
});

// ============================================================================
// MIDDLEWARE: AUTHENTICATION
// ============================================================================

const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({ error: 'No token provided' });
    }

    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) {
            return res.status(403).json({ error: 'Invalid token' });
        }
        req.user = user;
        next();
    });
};

// ============================================================================
// ROUTES: HEALTH & INFO
// ============================================================================

app.get('/api/health', (req, res) => {
    res.json({ 
        status: 'OK',
        timestamp: new Date().toISOString(),
        message: 'TinyTrail Backend is running'
    });
});

// ============================================================================
// ROUTES: FIRESTORE PROFILE (NEW)
// ============================================================================

app.post('/api/auth/profile', authenticateFirebase, async (req, res) => {
    if (!firestore) {
        return res.status(500).json({ error: 'Firestore not configured' });
    }

    const { name, phone, pincode, role } = req.body || {};

    const normalizedRole = role === 'vendor' ? 'vendor' : 'customer';
    const uid = req.firebaseUser.uid;
    const email = req.firebaseUser.email || '';

    const userDoc = {
        uid,
        name: String(name || '').trim(),
        email,
        role: normalizedRole,
        phone: String(phone || '').trim(),
        pincode: String(pincode || '').trim(),
        createdAt: new Date(),
    };

    try {
        const ref = firestore.collection('users').doc(uid);
        const existing = await ref.get();
        if (existing.exists) {
            await ref.set(
                {
                    ...userDoc,
                    createdAt: existing.data().createdAt || userDoc.createdAt,
                },
                { merge: true }
            );
        } else {
            await ref.set(userDoc);
        }

        res.json({ ok: true });
    } catch (err) {
        console.error('Upsert profile error:', err);
        res.status(500).json({ error: 'Failed to save profile' });
    }
});

app.get('/api/user/me', authenticateFirebase, async (req, res) => {
    if (!firestore) {
        return res.status(500).json({ error: 'Firestore not configured' });
    }

    try {
        const uid = req.firebaseUser.uid;
        const doc = await firestore.collection('users').doc(uid).get();
        if (!doc.exists) {
            return res.status(404).json({ error: 'User profile not found. Please complete profile setup.' });
        }

        const data = doc.data();
        // Provide legacy role mapping so existing mobile navigation keeps working.
        const legacyRole = data.role === 'vendor' ? 'SELLER' : 'BUYER';

        res.json({
            uid: data.uid,
            name: data.name || '',
            email: data.email || '',
            phone: data.phone || '',
            pincode: data.pincode || '',
            role: legacyRole,
            roleRaw: data.role,
        });
    } catch (err) {
        console.error('Get profile error:', err);
        res.status(500).json({ error: 'Failed to fetch profile' });
    }
});

// ============================================================================
// ROUTES: VENDOR CRUD (FIRESTORE, SPEC-COMPAT)
// ============================================================================

app.post('/api/vendor/create', authenticateFirebase, upload.array('workspaceImages', 10), async (req, res) => {
    if (!firestore) {
        return res.status(500).json({ error: 'Firestore not configured' });
    }

    const { shopName, description, category, lat, lng, pincode } = req.body || {};
    const files = req.files || [];

    if (!shopName || !category || !pincode) {
        return res.status(400).json({ error: 'shopName, category, pincode are required' });
    }

    try {
        const uid = req.firebaseUser.uid;
        const now = new Date();

        const isFood = String(category).toLowerCase() === 'food';
        const HYGIENE_THRESHOLD_REGISTER = Number(process.env.HYGIENE_THRESHOLD_REGISTER || 0.75);
        const HYGIENE_BASELINE_MIN_IMAGES = Number(process.env.HYGIENE_BASELINE_MIN_IMAGES || 5);
        const hygieneServiceUrl = process.env.HYGIENE_SERVICE_URL || 'http://localhost:8000';

        let hygieneApproved = !isFood;
        let hygieneScore = 0;
        let referenceEmbedding = null;
        let referenceImages = [];
        let verification = {};

        if (isFood) {
            if (files.length < HYGIENE_BASELINE_MIN_IMAGES) {
                return res.status(400).json({
                    error: `Food vendors must upload ${HYGIENE_BASELINE_MIN_IMAGES}-10 baseline workspace images`,
                });
            }

            const selectedFiles = files.slice(0, 10);
            const form = new FormData();
            for (const file of selectedFiles) {
                form.append('images', fs.createReadStream(file.path), {
                    filename: file.originalname || path.basename(file.path),
                    contentType: file.mimetype || 'image/jpeg',
                });
            }
            form.append('min_score', String(HYGIENE_THRESHOLD_REGISTER));

            const resp = await axios.post(`${hygieneServiceUrl}/verify-registration`, form, {
                headers: form.getHeaders(),
                timeout: 120000,
            });

            verification = resp.data || {};
            const predictions = Array.isArray(verification.results) ? verification.results : [];
            hygieneScore = Number(
                verification.referenceAverageScore || verification.averageScore || 0
            );
            hygieneApproved = Boolean(verification.approved);
            referenceEmbedding = Array.isArray(verification.referenceEmbedding)
                ? verification.referenceEmbedding
                : null;
            referenceImages = selectedFiles.map((file) => toPublicUploadPath(file.path));

            if (!hygieneApproved) {
                return res.status(403).json({
                    error: 'Workspace not clean enough',
                    message:
                        (Array.isArray(verification.reasons) && verification.reasons[0]) ||
                        'Workspace not clean enough',
                    details: verification,
                });
            }

            const batch = firestore.batch();
            for (let index = 0; index < selectedFiles.length; index += 1) {
                const file = selectedFiles[index];
                const prediction = predictions[index] || {};
                const reportRef = firestore.collection('hygieneReports').doc();
                batch.set(reportRef, {
                    reportId: reportRef.id,
                    vendorId: null,
                    imageUrl: toPublicUploadPath(file.path),
                    score: Number(prediction.score || 0),
                    result: prediction.label || 'unknown',
                    embedding: Array.isArray(prediction.embedding) ? prediction.embedding : null,
                    attentionZone: prediction.attentionZone || 'overall_workspace',
                    issues: prediction.issues || [],
                    createdAt: now,
                });
            }
            await batch.commit();
        }

        const vendorRef = firestore.collection('vendors').doc(uid);
        const vendorDoc = {
            vendorId: vendorRef.id,
            ownerId: uid,
            shopName: String(shopName),
            description: String(description || ''),
            category: String(category),
            businessType: String(category),
            pincode: String(pincode),
            location: {
                lat: lat ? Number(lat) : 0,
                lng: lng ? Number(lng) : 0,
                pincode: String(pincode),
            },
            isLive: Boolean(hygieneApproved),
            hygieneScore: hygieneScore,
            trustTier: hygieneApproved ? 'blue' : 'blue',
            createdAt: now,
            hygieneApproved: Boolean(hygieneApproved),
            requiresDailyHygieneCheck: Boolean(isFood),
            referenceImages: referenceImages,
            referenceEmbedding: referenceEmbedding,
            baselineImageCount: referenceImages.length,
            baselineAttentionZone: verification?.dominantAttentionZone || 'overall_workspace',
            baselineReasons: Array.isArray(verification?.reasons) ? verification.reasons : [],
            baselineReferenceAverageScore: Number(
                verification?.referenceAverageScore || verification?.averageScore || 0
            ),
            lastCheckScore: hygieneApproved ? hygieneScore : null,
            lastCheckedAt: hygieneApproved ? now : null,
        };

        await vendorRef.set(vendorDoc);

        // Update hygiene reports vendorId if any were created
        if (isFood && referenceImages.length) {
            const snap = await firestore
                .collection('hygieneReports')
                .where('vendorId', '==', null)
                .where('imageUrl', 'in', referenceImages.slice(0, 10))
                .get();

            const batch2 = firestore.batch();
            snap.forEach((doc) => batch2.update(doc.ref, { vendorId: vendorRef.id }));
            await batch2.commit();
        }

        res.status(201).json(vendorDoc);
    } catch (err) {
        console.error('Vendor create error:', err);
        res.status(500).json({ error: 'Failed to create vendor' });
    }
});

app.post('/api/vendor/hygiene-check', authenticateFirebase, upload.single('workspaceImage'), async (req, res) => {
    if (!firestore) {
        return res.status(500).json({ error: 'Firestore not configured' });
    }

    if (!req.file) {
        return res.status(400).json({ error: 'workspaceImage is required' });
    }

    const hygieneServiceUrl = process.env.HYGIENE_SERVICE_URL || 'http://localhost:8000';
    const HYGIENE_THRESHOLD_LOGIN = Number(process.env.HYGIENE_THRESHOLD_LOGIN || 0.7);
    const SIMILARITY_THRESHOLD = Number(process.env.HYGIENE_SIMILARITY_THRESHOLD || 0.6);

    try {
        const uid = req.firebaseUser.uid;

        let vendorDocRef = firestore.collection('vendors').doc(uid);
        let vendorSnap = await vendorDocRef.get();
        let vendor = vendorSnap.exists ? vendorSnap.data() : null;

        if (!vendor) {
            const ownerMatch = await firestore.collection('vendors').where('ownerId', '==', uid).limit(1).get();
            if (ownerMatch.empty) {
                return res.status(404).json({ error: 'Vendor not found' });
            }
            vendorDocRef = ownerMatch.docs[0].ref;
            vendor = ownerMatch.docs[0].data();
        }

        if (!vendor.referenceEmbedding || !Array.isArray(vendor.referenceEmbedding)) {
            return res.status(400).json({ error: 'Vendor has no reference embedding. Re-register hygiene.' });
        }

        const form = new FormData();
        form.append('image', fs.createReadStream(req.file.path), {
            filename: req.file.originalname || path.basename(req.file.path),
            contentType: req.file.mimetype || 'image/jpeg',
        });
        form.append('reference_embedding', JSON.stringify(vendor.referenceEmbedding));
        form.append('score_threshold', String(HYGIENE_THRESHOLD_LOGIN));
        form.append('similarity_threshold', String(SIMILARITY_THRESHOLD));

        const resp = await axios.post(`${hygieneServiceUrl}/verify-shift`, form, {
            headers: form.getHeaders(),
            timeout: 60000,
        });

        const verification = resp.data || {};
        const score = Number(verification.score || 0);
        const similarity = Number(verification.similarity || 0);
        const allowed = Boolean(verification.allowed);

        await vendorDocRef.set(
            {
                lastCheckScore: score,
                lastCheckedAt: new Date(),
            },
            { merge: true }
        );

        if (!allowed) {
            return res.status(403).json({
                allowed: false,
                score,
                similarity,
                reason: verification.reason || 'Workspace differs from the approved setup',
                attentionZone: verification.attentionZone || 'overall_workspace',
                issues: verification.issues || [],
            });
        }

        res.json({
            allowed: true,
            score,
            similarity,
            message: verification.reason || 'Hygiene verified',
            attentionZone: verification.attentionZone || 'overall_workspace',
            issues: verification.issues || [],
        });
    } catch (err) {
        console.error('Vendor hygiene-check error:', err);
        res.status(500).json({ error: 'Failed hygiene check' });
    }
});

// ============================================================================
// ROUTES: PRODUCT CRUD (FIRESTORE)
// ============================================================================

app.post('/api/product/add', authenticateFirebase, upload.single('image'), async (req, res) => {
    if (!firestore) {
        return res.status(500).json({ error: 'Firestore not configured' });
    }

    const { vendorId, name, description, price, category } = req.body || {};
    if (!vendorId || !name || price === undefined) {
        return res.status(400).json({ error: 'vendorId, name, price are required' });
    }

    try {
        const vendorRef = firestore.collection('vendors').doc(String(vendorId));
        const vendorDoc = await vendorRef.get();
        if (!vendorDoc.exists) {
            return res.status(404).json({ error: 'Vendor not found' });
        }

        const vendor = vendorDoc.data();
        if (vendor.ownerId !== req.firebaseUser.uid) {
            return res.status(403).json({ error: 'Not authorized' });
        }

        const imageUrl = req.file ? toPublicUploadPath(req.file.path) : '';
        const productRef = firestore.collection('products').doc();
        const now = new Date();

        const product = {
            productId: productRef.id,
            vendorId: String(vendorId),
            name: String(name),
            description: String(description || ''),
            price: Number(price),
            category: String(category || 'general'),
            imageUrl,
            isAvailable: true,
            createdAt: now,
        };

        await productRef.set(product);
        res.status(201).json(product);
    } catch (err) {
        console.error('Add product error:', err);
        res.status(500).json({ error: 'Failed to add product' });
    }
});

app.get('/api/products/byVendor/:vendorId', async (req, res) => {
    if (!firestore) {
        return res.status(500).json({ error: 'Firestore not configured' });
    }

    try {
        const vendorId = String(req.params.vendorId);
        const snap = await firestore
            .collection('products')
            .where('vendorId', '==', vendorId)
            .where('isAvailable', '==', true)
            .limit(50)
            .get();

        res.json(snap.docs.map((d) => d.data()));
    } catch (err) {
        console.error('List products error:', err);
        res.status(500).json({ error: 'Failed to list products' });
    }
});

// ============================================================================
// ROUTES: ORDER CRUD (FIRESTORE)
// ============================================================================

app.post('/api/order/create', authenticateFirebase, async (req, res) => {
    if (!firestore) {
        return res.status(500).json({ error: 'Firestore not configured' });
    }

    const { vendorId, items } = req.body || {};
    if (!vendorId || !Array.isArray(items) || items.length === 0) {
        return res.status(400).json({ error: 'vendorId and items are required' });
    }

    try {
        const orderRef = firestore.collection('orders').doc();
        const now = new Date();

        const totalPrice = items.reduce((sum, item) => {
            const qty = Number(item.quantity || 0);
            const price = Number(item.price || 0);
            return sum + qty * price;
        }, 0);

        const order = {
            orderId: orderRef.id,
            userId: req.firebaseUser.uid,
            vendorId: String(vendorId),
            items: items.map((i) => ({
                productId: String(i.productId),
                quantity: Number(i.quantity || 1),
            })),
            totalPrice,
            status: 'pending',
            createdAt: now,
        };

        await orderRef.set(order);
        res.status(201).json(order);
    } catch (err) {
        console.error('Create order error:', err);
        res.status(500).json({ error: 'Failed to create order' });
    }
});

app.get('/api/orders/user/:userId', authenticateFirebase, async (req, res) => {
    if (!firestore) {
        return res.status(500).json({ error: 'Firestore not configured' });
    }

    const userId = String(req.params.userId);
    if (userId !== req.firebaseUser.uid) {
        return res.status(403).json({ error: 'Not authorized' });
    }

    try {
        const snap = await firestore
            .collection('orders')
            .where('userId', '==', userId)
            .orderBy('createdAt', 'desc')
            .limit(50)
            .get();

        res.json(snap.docs.map((d) => d.data()));
    } catch (err) {
        console.error('List orders error:', err);
        res.status(500).json({ error: 'Failed to list orders' });
    }
});

// ============================================================================
// ROUTES: USER LOOKUP (FIRESTORE)
// ============================================================================

app.get('/api/user/:uid', authenticateFirebase, async (req, res) => {
    if (!firestore) {
        return res.status(500).json({ error: 'Firestore not configured' });
    }

    const uid = String(req.params.uid);
    if (uid !== req.firebaseUser.uid) {
        return res.status(403).json({ error: 'Not authorized' });
    }

    try {
        const doc = await firestore.collection('users').doc(uid).get();
        if (!doc.exists) {
            return res.status(404).json({ error: 'User not found' });
        }
        res.json(doc.data());
    } catch (err) {
        console.error('Get user error:', err);
        res.status(500).json({ error: 'Failed to fetch user' });
    }
});

// ============================================================================
// ROUTES: AUTHENTICATION
// ============================================================================

app.post('/api/auth/login', (req, res) => {
    const { identifier, username, password } = req.body;
    const loginIdentifier = identifier || username;
    
    if (!loginIdentifier || !password) {
        return res.status(400).json({ error: 'Identifier and password required' });
    }
    
    db.get(
        'SELECT * FROM users WHERE username = ? OR email = ? OR phone = ?',
        [loginIdentifier, loginIdentifier, loginIdentifier],
        (err, user) => {
        if (err) return res.status(500).json({ error: 'Database error' });
        if (!user) return res.status(401).json({ error: 'User not found' });
        
        if (!bcrypt.compareSync(password, user.password)) {
            return res.status(401).json({ error: 'Invalid password' });
        }
        
        const token = jwt.sign({ id: user.id, username: user.username, role: user.role }, JWT_SECRET, { expiresIn: '7d' });
        res.json({ 
            token, 
            user: { 
                id: user.id, 
                username: user.username, 
                email: user.email, 
                role: user.role,
                phone: user.phone,
                preferred_locale: user.preferred_locale
            } 
        });
    });
});

app.post('/api/auth/register', (req, res) => {
    const { username, password, email, phone, role } = req.body;
    const normalizedRole = role === 'SELLER' ? 'SELLER' : 'BUYER';
    
    if (!username || !password || !email || !phone) {
        return res.status(400).json({ error: 'Username, email, phone, and password are required' });
    }

    if (String(password).length < 6) {
        return res.status(400).json({ error: 'Password must be at least 6 characters' });
    }
    
    const hashedPassword = bcrypt.hashSync(password, 10);
    
    db.run('INSERT INTO users (username, password, email, phone, role) VALUES (?, ?, ?, ?, ?)', 
        [username.trim(), hashedPassword, email.trim().toLowerCase(), String(phone).trim(), normalizedRole], 
        function(err) {
            if (err) {
                if (String(err.message).includes('users.username')) {
                    return res.status(400).json({ error: 'That username already exists' });
                }
                if (String(err.message).includes('users.email')) {
                    return res.status(400).json({ error: 'That email is already registered' });
                }
                if (String(err.message).includes('idx_users_phone_unique')) {
                    return res.status(400).json({ error: 'That mobile number is already registered' });
                }
                return res.status(400).json({ error: 'Unable to create account with those details' });
            }
            
            const token = jwt.sign({ id: this.lastID, username, role: normalizedRole }, JWT_SECRET, { expiresIn: '7d' });
            res.json({ 
                token, 
                user: { 
                    id: this.lastID, 
                    username: username.trim(), 
                    email: email.trim().toLowerCase(), 
                    phone: String(phone).trim(),
                    role: normalizedRole,
                    preferred_locale: 'en'
                } 
            });
        }
    );
});

app.get('/api/auth/me', authenticateToken, (req, res) => {
    db.get('SELECT id, username, email, role, phone, preferred_locale FROM users WHERE id = ?', 
        [req.user.id], 
        (err, user) => {
            if (err) return res.status(500).json({ error: 'Database error' });
            if (!user) return res.status(404).json({ error: 'User not found' });
            res.json(user);
        }
    );
});

app.put('/api/users/:id/locale', authenticateToken, (req, res) => {
    const { locale } = req.body;
    
    if (!['en', 'ta', 'ml', 'kn', 'te'].includes(locale)) {
        return res.status(400).json({ error: 'Invalid locale' });
    }
    
    db.run('UPDATE users SET preferred_locale = ? WHERE id = ?', 
        [locale, req.user.id], 
        (err) => {
            if (err) return res.status(500).json({ error: 'Database error' });
            res.json({ message: 'Locale updated', locale });
        }
    );
});

// ============================================================================
// ROUTES: PRODUCTS
// ============================================================================

app.get('/api/products', (req, res) => {
    db.all(`SELECT p.*, v.shop_name as vendor_name FROM products p 
            LEFT JOIN vendors v ON p.vendor_id = v.id 
            LIMIT 50`, 
        (err, products) => {
            if (err) return res.status(500).json({ error: 'Database error' });
            res.json(products || []);
        }
    );
});

app.get('/api/products/search', (req, res) => {
    const { pincode, category } = req.query;
    
    let query = `SELECT p.*, v.shop_name as vendor_name FROM products p 
                 LEFT JOIN vendors v ON p.vendor_id = v.id WHERE 1=1`;
    let params = [];
    
    if (pincode) {
        query += ` AND p.pincode = ?`;
        params.push(pincode);
    }
    
    if (category) {
        query += ` AND p.category = ?`;
        params.push(category);
    }
    
    query += ` LIMIT 50`;
    
    db.all(query, params, (err, products) => {
        if (err) return res.status(500).json({ error: 'Database error' });
        res.json(products || []);
    });
});

app.get('/api/products/:id', (req, res) => {
    const { id } = req.params;
    
    db.get(`SELECT p.*, v.shop_name as vendor_name, v.id as vendor_id 
            FROM products p 
            LEFT JOIN vendors v ON p.vendor_id = v.id 
            WHERE p.id = ?`, 
        [id], 
        (err, product) => {
            if (err) return res.status(500).json({ error: 'Database error' });
            if (!product) return res.status(404).json({ error: 'Product not found' });
            res.json(product);
        }
    );
});

app.get('/api/products/mine', authenticateToken, async (req, res) => {
    try {
        const vendor = await findVendorByUserId(req.user.id);
        if (!vendor) {
            return res.status(404).json({ error: 'Vendor not found' });
        }

        db.all(
            `SELECT p.*, v.shop_name as vendor_name
             FROM products p
             LEFT JOIN vendors v ON p.vendor_id = v.id
             WHERE p.vendor_id = ?
             ORDER BY p.created_at DESC, p.id DESC`,
            [vendor.id],
            (err, products) => {
                if (err) return res.status(500).json({ error: 'Database error' });
                res.json(products || []);
            }
        );
    } catch (error) {
        console.error('Fetch my products error:', error);
        res.status(500).json({ error: 'Failed to fetch seller products' });
    }
});

app.post('/api/products', authenticateToken, upload.single('image'), async (req, res) => {
    const { name, description, price, pincode, category } = req.body;

    if (!name || !price || !pincode) {
        return res.status(400).json({ error: 'Name, price, and pincode are required' });
    }

    try {
        const vendor = await findVendorByUserId(req.user.id);
        if (!vendor) {
            return res.status(400).json({ error: 'Seller onboarding is required before adding products' });
        }

        const imageUrl = req.file ? toPublicUploadPath(req.file.path) : null;

        db.run(
            `INSERT INTO products (vendor_id, name, description, price, pincode, image_url, category)
             VALUES (?, ?, ?, ?, ?, ?, ?)`,
            [vendor.id, name, description || '', Number(price), pincode, imageUrl, category || 'General'],
            function (err) {
                if (err) return res.status(500).json({ error: 'Database error' });

                db.get(
                    `SELECT p.*, v.shop_name as vendor_name, v.id as vendor_id
                     FROM products p
                     LEFT JOIN vendors v ON p.vendor_id = v.id
                     WHERE p.id = ?`,
                    [this.lastID],
                    (fetchErr, product) => {
                        if (fetchErr) return res.status(500).json({ error: 'Database error' });
                        res.status(201).json(product);
                    }
                );
            }
        );
    } catch (error) {
        console.error('Create product error:', error);
        res.status(500).json({ error: 'Failed to create product' });
    }
});

app.get('/api/products/categories/list', (req, res) => {
    db.all('SELECT DISTINCT category FROM products WHERE category IS NOT NULL', 
        (err, rows) => {
            if (err) return res.status(500).json({ error: 'Database error' });
            const categories = rows.map(r => r.category);
            res.json(categories);
        }
    );
});

// ============================================================================
// ROUTES: VENDORS
// ============================================================================

app.get('/api/vendors/me', authenticateToken, async (req, res) => {
    try {
        if (firestore && firebaseAuth) {
            return res.status(400).json({ error: 'Use /api/user/me with Firebase auth' });
        }
        const vendor = await findVendorByUserId(req.user.id);
        if (!vendor) {
            return res.status(404).json({ error: 'Vendor not found' });
        }

        db.get(
            `SELECT * FROM vendor_hygiene_checks
             WHERE vendor_id = ?
             ORDER BY created_at DESC, id DESC
             LIMIT 1`,
            [vendor.id],
            (err, hygieneCheck) => {
                if (err) return res.status(500).json({ error: 'Database error' });
                res.json({ ...vendor, latest_hygiene: hygieneCheck || null });
            }
        );
    } catch (error) {
        console.error('Fetch vendor profile error:', error);
        res.status(500).json({ error: 'Failed to fetch vendor profile' });
    }
});

app.post('/api/vendors/onboard', authenticateToken, async (req, res) => {
    const { shop_name, address, pincode, story_text } = req.body;

    if (!shop_name || !address || !pincode) {
        return res.status(400).json({ error: 'Shop name, address, and pincode are required' });
    }

    try {
        if (firestore && firebaseAuth) {
            return res.status(400).json({ error: 'Use /api/vendor/create with Firebase auth' });
        }
        const existingVendor = await findVendorByUserId(req.user.id);

        const finishResponse = (vendorId) => {
            db.run('UPDATE users SET role = ? WHERE id = ?', ['SELLER', req.user.id], (roleErr) => {
                if (roleErr) return res.status(500).json({ error: 'Database error' });

                db.get('SELECT * FROM vendors WHERE id = ?', [vendorId], (fetchErr, vendor) => {
                    if (fetchErr) return res.status(500).json({ error: 'Database error' });
                    res.json(vendor);
                });
            });
        };

        if (existingVendor) {
            db.run(
                `UPDATE vendors
                 SET shop_name = ?, address = ?, pincode = ?, story_text = ?
                 WHERE id = ?`,
                [shop_name, address, pincode, story_text || '', existingVendor.id],
                (err) => {
                    if (err) return res.status(500).json({ error: 'Database error' });
                    finishResponse(existingVendor.id);
                }
            );
            return;
        }

        db.run(
            `INSERT INTO vendors (user_id, shop_name, pincode, address, story_text)
             VALUES (?, ?, ?, ?, ?)`,
            [req.user.id, shop_name, pincode, address, story_text || ''],
            function (err) {
                if (err) return res.status(500).json({ error: 'Database error' });
                finishResponse(this.lastID);
            }
        );
    } catch (error) {
        console.error('Vendor onboarding error:', error);
        res.status(500).json({ error: 'Failed to onboard seller' });
    }
});

app.get('/api/vendors', (req, res) => {
    db.all(`SELECT v.*, u.username FROM vendors v 
            LEFT JOIN users u ON v.user_id = u.id 
            LIMIT 50`, 
        (err, vendors) => {
            if (err) return res.status(500).json({ error: 'Database error' });
            res.json(vendors || []);
        }
    );
});

app.get('/api/vendors/nearby', (req, res) => {
    const { pincode } = req.query;
    
    if (!pincode) {
        return res.status(400).json({ error: 'Pincode required' });
    }
    
    db.all(`SELECT v.*, u.username, COUNT(p.id) as product_count 
            FROM vendors v 
            LEFT JOIN users u ON v.user_id = u.id 
            LEFT JOIN products p ON v.id = p.vendor_id
            WHERE v.pincode = ? 
            GROUP BY v.id`, 
        [pincode], 
        (err, vendors) => {
            if (err) return res.status(500).json({ error: 'Database error' });
            res.json(vendors || []);
        }
    );
});

app.get('/api/vendors/:id', (req, res) => {
    const { id } = req.params;
    
    db.get(`SELECT v.*, u.username, u.email, u.phone FROM vendors v 
            LEFT JOIN users u ON v.user_id = u.id 
            WHERE v.id = ?`, 
        [id], 
        (err, vendor) => {
            if (err) return res.status(500).json({ error: 'Database error' });
            if (!vendor) return res.status(404).json({ error: 'Vendor not found' });
            
            // Get vendor products
            db.all('SELECT * FROM products WHERE vendor_id = ?', [id], (err, products) => {
                vendor.products = products || [];
                res.json(vendor);
            });
        }
    );
});

app.post('/api/hygiene/check', authenticateToken, upload.single('workspaceImage'), async (req, res) => {
    if (!req.file) {
        return res.status(400).json({ error: 'Workspace image is required' });
    }

    try {
        if (firestore && firebaseAuth) {
            return res.status(400).json({ error: 'Use /api/vendor/hygiene-check with Firebase auth' });
        }
        const vendor = await findVendorByUserId(req.user.id);
        if (!vendor) {
            return res.status(400).json({ error: 'Seller onboarding is required before hygiene check' });
        }

        const prediction = await runHygienePrediction(req.file.path);
        const imageUrl = toPublicUploadPath(req.file.path);

        db.run(
            `INSERT INTO vendor_hygiene_checks
             (vendor_id, image_url, predicted_class, confidence, hygiene_score, badge_text)
             VALUES (?, ?, ?, ?, ?, ?)`,
            [
                vendor.id,
                imageUrl,
                prediction.predicted_class,
                prediction.confidence,
                prediction.hygiene_score,
                prediction.badge_text,
            ],
            function (err) {
                if (err) return res.status(500).json({ error: 'Database error' });

                res.json({
                    id: this.lastID,
                    vendor_id: vendor.id,
                    image_url: imageUrl,
                    ...prediction,
                });
            }
        );
    } catch (error) {
        console.error('Hygiene prediction error:', error);
        res.status(500).json({
            error: 'Failed to run hygiene check',
            details: error.message,
        });
    }
});

app.post('/api/vendors/:id/subscribe', authenticateToken, (req, res) => {
    const { id } = req.params;
    const { plan_id } = req.body;
    
    db.get('SELECT id FROM subscription_plans WHERE id = ? AND vendor_id = ?', 
        [plan_id, id], 
        (err, plan) => {
            if (err || !plan) return res.status(404).json({ error: 'Plan not found' });
            
            db.run('INSERT INTO subscriptions (user_id, plan_id, status) VALUES (?, ?, ?)',
                [req.user.id, plan_id, 'ACTIVE'],
                function(err) {
                    if (err) return res.status(500).json({ error: 'Database error' });
                    res.json({ id: this.lastID, message: 'Subscribed successfully' });
                }
            );
        }
    );
});

// ============================================================================
// ROUTES: ORDERS
// ============================================================================

app.post('/api/orders', authenticateToken, (req, res) => {
    const { delivery_address, payment_method, upi_id, items } = req.body;
    
    if (!items || items.length === 0) {
        return res.status(400).json({ error: 'No items in order' });
    }
    
    const total = items.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    
    db.run('INSERT INTO orders (buyer_id, total, status, delivery_address, payment_method, upi_id) VALUES (?, ?, ?, ?, ?, ?)',
        [req.user.id, total, 'PENDING', delivery_address, payment_method, upi_id],
        function(err) {
            if (err) return res.status(500).json({ error: 'Database error' });
            
            const orderId = this.lastID;
            
            // Insert order items
            items.forEach(item => {
                db.run('INSERT INTO order_items (order_id, product_id, quantity, price) VALUES (?, ?, ?, ?)',
                    [orderId, item.product_id, item.quantity, item.price]
                );
            });
            
            res.json({ 
                id: orderId, 
                buyer_id: req.user.id, 
                total, 
                status: 'PENDING',
                message: 'Order placed successfully'
            });
        }
    );
});

app.get('/api/orders', authenticateToken, (req, res) => {
    db.all('SELECT * FROM orders WHERE buyer_id = ? ORDER BY created_at DESC', 
        [req.user.id], 
        (err, orders) => {
            if (err) return res.status(500).json({ error: 'Database error' });
            res.json(orders || []);
        }
    );
});

app.get('/api/orders/:id', authenticateToken, (req, res) => {
    const { id } = req.params;
    
    db.get('SELECT * FROM orders WHERE id = ? AND buyer_id = ?', 
        [id, req.user.id], 
        (err, order) => {
            if (err) return res.status(500).json({ error: 'Database error' });
            if (!order) return res.status(404).json({ error: 'Order not found' });
            
            db.all('SELECT * FROM order_items WHERE order_id = ?', [id], (err, items) => {
                order.items = items || [];
                res.json(order);
            });
        }
    );
});

// ============================================================================
// ROUTES: AI ENDPOINT (MOCK)
// ============================================================================

app.post('/api/ai/query', (req, res) => {
    const { query, language } = req.body;
    
    if (!query) {
        return res.status(400).json({ error: 'Query required' });
    }
    
    // Mock AI responses
    const mockResponses = {
        'vegetables': 'We have fresh organic vegetables! Check out our tomatoes, spinach, and potatoes.',
        'fruits': 'Fresh fruits available! Try our sweet mangoes and bananas.',
        'hello': 'Welcome to TinyTrail! How can I help you find local products?',
        'recommend': 'Based on your preferences, I recommend our organic spinach and fresh tomatoes!',
        'default': `I understand you're looking for: "${query}". Let me help you find the best local products!`
    };
    
    const response = Object.keys(mockResponses).find(key => query.toLowerCase().includes(key));
    const answer = mockResponses[response] || mockResponses['default'];
    
    res.json({
        query,
        response: answer,
        language: language || 'en',
        suggestions: [
            { type: 'product', id: 1, name: 'Fresh Tomatoes', price: 50 },
            { type: 'product', id: 2, name: 'Organic Spinach', price: 30 }
        ],
        confidence: 0.95
    });
});

// ============================================================================
// ROUTES: WEBHOOKS
// ============================================================================

app.post('/api/webhooks/payment', (req, res) => {
    const { order_id, status, txn_id } = req.body;
    
    let orderStatus = 'PENDING';
    if (status === 'SUCCESS') orderStatus = 'CONFIRMED';
    else if (status === 'FAILED') orderStatus = 'CANCELLED';
    
    db.run('UPDATE orders SET status = ?, transaction_id = ? WHERE id = ?', 
        [orderStatus, txn_id, order_id], 
        (err) => {
            if (err) return res.status(500).json({ error: 'Database error' });
            res.json({ message: 'Webhook processed', status: orderStatus });
        }
    );
});

// ============================================================================
// ROUTES: SELLER TOOLS
// ============================================================================

app.post('/api/seller/clean-menu', authenticateToken, (req, res) => {
    // Mock OCR response
    res.json({
        success: true,
        items: [
            { name: 'Organic Tomatoes', price: 50 },
            { name: 'Fresh Spinach', price: 30 },
            { name: 'Local Potatoes', price: 40 }
        ],
        message: 'Menu items extracted from image'
    });
});

app.post('/api/seller/generate-photo', authenticateToken, (req, res) => {
    // Mock image generation
    res.json({
        success: true,
        job_id: 'job_' + Date.now(),
        image_url: 'https://via.placeholder.com/400x300?text=Generated+Product+Photo',
        message: 'Image generated successfully'
    });
});

app.get('/', (_req, res) => {
    res.sendFile(path.join(WEB_APP_DIR, 'index.html'));
});

// ============================================================================
// ERROR HANDLING
// ============================================================================

app.use((req, res) => {
    res.status(404).json({ error: 'Route not found', path: req.path });
});

app.use((err, req, res, next) => {
    console.error('Error:', err);
    res.status(500).json({ error: 'Internal server error' });
});

// ============================================================================
// START SERVER
// ============================================================================

app.listen(PORT, () => {
    console.log('\n' + '='.repeat(70));
    console.log('🚀 TINYTRAIL BACKEND');
    console.log('='.repeat(70));
    console.log(`✅ Server running on http://localhost:${PORT}`);
    console.log(`✅ Database: SQLite (tinytrail.db)`);
    console.log('\n📝 Sample Users:');
    console.log(`   admin / password123`);
    console.log(`   john_buyer / password123`);
    console.log(`   jane_seller / password123`);
    console.log('\n🔗 Main Endpoints:');
    console.log(`   GET    /api/health`);
    console.log(`   POST   /api/auth/login`);
    console.log(`   POST   /api/auth/register`);
    console.log(`   GET    /api/products`);
    console.log(`   GET    /api/products/search?pincode=600001`);
    console.log(`   GET    /api/vendors`);
    console.log(`   POST   /api/orders`);
    console.log(`   POST   /api/ai/query`);
    console.log('='.repeat(70) + '\n');
});

process.on('SIGINT', () => {
    console.log('\n🛑 Shutting down server...');
    db.close();
    process.exit(0);
});
