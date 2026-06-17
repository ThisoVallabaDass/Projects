# 🎬 TinyTrail - Visual Quick Reference

## 🌐 Where to Access Everything

```
┌─────────────────────────────────────────────────────────────┐
│                    YOUR APPLICATIONS                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  📱 WEB APPLICATION                                          │
│  ▶️  http://localhost:3000                                   │
│  • Login / Register                                          │
│  • Browse products                                           │
│  • Shopping cart                                             │
│  • Checkout                                                  │
│  • Order tracking                                            │
│                                                              │
│  🔌 BACKEND API                                              │
│  ▶️  http://localhost:8080                                   │
│  • All endpoints documented                                  │
│  • Sample data ready                                         │
│  • JWT authentication                                        │
│                                                              │
│  📊 DATABASE                                                 │
│  ▶️  packages/backend/tinytrail.db                            │
│  • SQLite3                                                   │
│  • 6 tables                                                  │
│  • Auto-populated                                            │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 User Journey Map

```
┌────────────────────────────────────────────────────────────────┐
│                    USER JOURNEY                                │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  START                                                         │
│    ↓                                                            │
│  ┌─────────────────┐                                           │
│  │  LANDING PAGE   │                                           │
│  │  Login/Register │                                           │
│  └────────┬────────┘                                           │
│           │                                                    │
│  ┌────────▼────────────┐                                       │
│  │  PRODUCTS PAGE      │ ◄─────── Filter by pincode/category   │
│  │  (Browse & Search)  │                                       │
│  └────────┬────────────┘                                       │
│           │                                                    │
│  ┌────────▼────────────┐                                       │
│  │   SHOPPING CART     │ ◄─────── Add/Remove items             │
│  │  (View & Manage)    │                                       │
│  └────────┬────────────┘                                       │
│           │                                                    │
│  ┌────────▼────────────┐                                       │
│  │    CHECKOUT PAGE    │ ◄─────── Enter address & payment      │
│  │  (Place Order)      │                                       │
│  └────────┬────────────┘                                       │
│           │                                                    │
│  ┌────────▼────────────┐                                       │
│  │   ORDER CONFIRMATION│                                       │
│  │                     │                                       │
│  └────────┬────────────┘                                       │
│           │                                                    │
│  ┌────────▼────────────┐                                       │
│  │   ORDERS PAGE       │ ◄─────── View all orders              │
│  │  (Tracking)         │                                       │
│  └─────────────────────┘                                       │
│           │                                                    │
│           ↓                                                    │
│         END                                                    │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

---

## 🏗️ System Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                    ARCHITECTURE                                │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│        USER'S BROWSER                                          │
│        ┌──────────────────┐                                    │
│        │  React Web App   │  (http://localhost:3000)           │
│        │  ├─ Pages        │                                    │
│        │  ├─ Components   │                                    │
│        │  └─ Router       │                                    │
│        └────────┬─────────┘                                    │
│                 │                                              │
│                 │ AXIOS HTTP REQUESTS                          │
│                 │                                              │
│        ┌────────▼──────────┐                                   │
│        │  EXPRESS SERVER   │  (http://localhost:8080)          │
│        │  ├─ Routes        │                                   │
│        │  ├─ Controllers   │                                   │
│        │  ├─ Middleware    │                                   │
│        │  └─ Error Handler │                                   │
│        └────────┬──────────┘                                   │
│                 │                                              │
│                 │ DATABASE QUERIES                             │
│                 │                                              │
│        ┌────────▼──────────┐                                   │
│        │  SQLITE DATABASE  │                                   │
│        │  ├─ Users Table   │                                   │
│        │  ├─ Products      │                                   │
│        │  ├─ Cart Items    │                                   │
│        │  ├─ Orders        │                                   │
│        │  ├─ Sellers       │                                   │
│        │  └─ ...           │                                   │
│        └───────────────────┘                                   │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

---

## 📱 Page Structure

```
┌─────────────────────────────────────────────────────────────┐
│                   ALL PAGES                                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1️⃣  LOGIN PAGE (/login)                                    │
│     Fields: Username, Password                             │
│     Actions: Login, Register link                          │
│     Demo: admin/password123                                │
│                                                             │
│  2️⃣  REGISTER PAGE (/register)                              │
│     Fields: Username, Email, Phone, Password               │
│     Actions: Register, Login link                          │
│                                                             │
│  3️⃣  PRODUCTS PAGE (/products)                              │
│     Search: By product name                                │
│     Filter: By pincode, category                           │
│     Display: Grid of product cards                         │
│     Actions: Add to cart, View details                     │
│                                                             │
│  4️⃣  CART PAGE (/cart)                                      │
│     Display: All cart items                                │
│     Actions: Remove item, Update quantity                  │
│     Form: Delivery address, Phone, Payment method          │
│     Button: Place order                                    │
│                                                             │
│  5️⃣  ORDERS PAGE (/orders)                                  │
│     Display: All user orders                               │
│     Info: Order ID, Status, Date, Total                    │
│     Actions: View details                                  │
│                                                             │
│  6️⃣  SELLER ONBOARD (/seller/onboard)                       │
│     Form: Shop name, Address, Pincode                      │
│     Actions: Become seller                                 │
│                                                             │
│  7️⃣  PRODUCT DETAIL (coming soon)                           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔌 API Endpoints Quick Reference

```
┌─────────────────────────────────────────────────────────────┐
│              API ENDPOINTS (18 Total)                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  AUTH                                                       │
│  ├─ POST   /api/auth/register         (Create account)     │
│  ├─ POST   /api/auth/login            (Login)              │
│  └─ GET    /api/auth/me               (Get user info)      │
│                                                             │
│  PRODUCTS                                                   │
│  ├─ GET    /api/products              (List all)           │
│  ├─ GET    /api/products/search       (Search)             │
│  ├─ GET    /api/products/:id          (Detail)             │
│  └─ GET    /api/categories            (List categories)    │
│                                                             │
│  CART                                                       │
│  ├─ POST   /api/cart/add              (Add item)           │
│  ├─ POST   /api/cart/remove           (Remove item)        │
│  ├─ GET    /api/cart                  (View cart)          │
│  └─ POST   /api/cart/clear            (Empty cart)         │
│                                                             │
│  ORDERS                                                     │
│  ├─ POST   /api/orders                (Create order)       │
│  ├─ GET    /api/orders                (List orders)        │
│  └─ GET    /api/orders/:id            (View order)         │
│                                                             │
│  SELLERS                                                    │
│  ├─ POST   /api/seller/onboard        (Become seller)      │
│  └─ GET    /api/sellers/:id           (View profile)       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 Database Tables

```
┌─────────────────────────────────────────────────────────────┐
│              DATABASE SCHEMA (6 Tables)                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  USERS                                                      │
│  ├─ id (INTEGER, PRIMARY KEY)                              │
│  ├─ username (TEXT, UNIQUE)                                │
│  ├─ password (TEXT, HASHED)                                │
│  ├─ email (TEXT, UNIQUE)                                   │
│  ├─ phone (TEXT)                                           │
│  ├─ role (TEXT: BUYER/SELLER/ADMIN)                        │
│  └─ created_at (DATETIME)                                  │
│                                                             │
│  SELLERS                                                    │
│  ├─ id (INTEGER, PRIMARY KEY)                              │
│  ├─ user_id (FK to USERS)                                  │
│  ├─ shop_name (TEXT)                                       │
│  ├─ pincode (TEXT)                                         │
│  ├─ address (TEXT)                                         │
│  └─ verified (INTEGER: 0/1)                                │
│                                                             │
│  PRODUCTS                                                   │
│  ├─ id (INTEGER, PRIMARY KEY)                              │
│  ├─ seller_id (FK to SELLERS)                              │
│  ├─ name (TEXT)                                            │
│  ├─ description (TEXT)                                     │
│  ├─ price (REAL)                                           │
│  ├─ pincode (TEXT)                                         │
│  ├─ category (TEXT)                                        │
│  └─ rating (REAL: 0-5)                                     │
│                                                             │
│  CART_ITEMS                                                 │
│  ├─ id (INTEGER, PRIMARY KEY)                              │
│  ├─ user_id (FK to USERS)                                  │
│  ├─ product_id (FK to PRODUCTS)                            │
│  └─ quantity (INTEGER)                                     │
│                                                             │
│  ORDERS                                                     │
│  ├─ id (INTEGER, PRIMARY KEY)                              │
│  ├─ buyer_id (FK to USERS)                                 │
│  ├─ seller_id (FK to SELLERS)                              │
│  ├─ total (REAL)                                           │
│  ├─ status (TEXT: PENDING/CONFIRMED)                       │
│  ├─ delivery_address (TEXT)                                │
│  └─ created_at (DATETIME)                                  │
│                                                             │
│  ORDER_ITEMS                                                │
│  ├─ id (INTEGER, PRIMARY KEY)                              │
│  ├─ order_id (FK to ORDERS)                                │
│  ├─ product_id (FK to PRODUCTS)                            │
│  ├─ quantity (INTEGER)                                     │
│  └─ price (REAL)                                           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🚀 Services Status Dashboard

```
┌─────────────────────────────────────────────────────────────┐
│              SERVICES STATUS                                │
├──────────────────────────┬──────────────┬────────────────────┤
│ Service                  │ Status       │ URL/Location       │
├──────────────────────────┼──────────────┼────────────────────┤
│ Backend API              │ ✅ Running   │ :8080              │
│ Web Frontend             │ ✅ Running   │ :3000              │
│ SQLite Database          │ ✅ Ready     │ ./tinytrail.db     │
│ Sample Data              │ ✅ Loaded    │ Auto-seeded        │
│ Authentication           │ ✅ Working   │ JWT Token          │
│ CORS                     │ ✅ Enabled   │ All origins        │
│ Mobile App               │ ⏳ Ready     │ (To build)         │
└──────────────────────────┴──────────────┴────────────────────┘
```

---

## 📱 Sample Data Available

```
┌─────────────────────────────────────────────────────────────┐
│           SAMPLE DATA FOR TESTING                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  USERS (3)                                                  │
│  ├─ admin (ADMIN role)                                      │
│  ├─ john_buyer (BUYER role)                                 │
│  └─ jane_seller (SELLER role)                               │
│  All passwords: password123                                │
│                                                             │
│  SELLERS (1)                                                │
│  └─ Jane's Fresh Market (verified, 4.8 rating)             │
│                                                             │
│  PRODUCTS (8)                                               │
│  ├─ Fresh Tomatoes (₹50, Vegetables)                       │
│  ├─ Organic Spinach (₹30, Vegetables)                      │
│  ├─ Local Potatoes (₹40, Vegetables)                       │
│  ├─ Fresh Mangoes (₹80, Fruits)                            │
│  ├─ Bananas (₹20, Fruits)                                  │
│  ├─ Carrots (₹35, Vegetables)                              │
│  ├─ Cabbage (₹25, Vegetables)                              │
│  └─ Apples (₹100, Fruits)                                  │
│                                                             │
│  PINCODE                                                    │
│  └─ 600001 (Chennai - Default)                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 Quick Test Checklist

```
┌─────────────────────────────────────────────────────────────┐
│           MANUAL TESTING CHECKLIST                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  □ Backend API running on :8080                            │
│  □ Web app running on :3000                                │
│  □ Can access http://localhost:3000                        │
│  □ Can login with admin/password123                        │
│  □ Can register new account                                │
│  □ Can search products by pincode                          │
│  □ Can filter by category                                  │
│  □ Can add product to cart                                 │
│  □ Can view cart                                           │
│  □ Can remove items from cart                              │
│  □ Can place order                                         │
│  □ Can view orders in Orders page                          │
│  □ Can logout                                              │
│  □ Can login again with new account                        │
│  □ API endpoints work (test with curl)                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 💡 Pro Tips

```
┌─────────────────────────────────────────────────────────────┐
│              PRO TIPS & TRICKS                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Use browser DevTools (F12) to see API calls             │
│     → Network tab shows all requests/responses             │
│                                                             │
│  2. Use Postman/Insomnia for API testing                   │
│     → More detailed than curl                              │
│                                                             │
│  3. Check browser Console for JavaScript errors            │
│     → Shows issues in React components                     │
│                                                             │
│  4. Database is auto-created on first run                  │
│     → No migration needed                                  │
│                                                             │
│  5. Tokens expire in 7 days                                │
│     → Re-login for new token                               │
│                                                             │
│  6. Sample data resets on database deletion                │
│     → Delete tinytrail.db to reset                         │
│                                                             │
│  7. Passwords are 10-round bcrypt hashed                   │
│     → Very secure, can't be reversed                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

**You're all set! Enjoy your TinyTrail marketplace! 🎉**
