# TinyTrails - Hyperlocal E-Commerce & Food Delivery Platform

<div align="center">

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Java](https://img.shields.io/badge/Java-17-orange.svg)](https://www.oracle.com/java/technologies/javase/jdk17-archive.html)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.1.5-brightgreen.svg)](https://spring.io/projects/spring-boot)
[![React](https://img.shields.io/badge/React-18.2.0-61dafb.svg)](https://react.dev/)
[![Python](https://img.shields.io/badge/Python-3.10%2B-blue.svg)](https://www.python.org/)
[![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-02569B.svg)](https://flutter.dev/)

**TinyTrails enables hyperlocal food entrepreneurs to connect directly with customers in their neighborhoods, powered by an AI-driven hygiene verification system.**

[Features](#features) • [Architecture](#architecture) • [Tech Stack](#tech-stack) • [Getting Started](#getting-started) • [API Documentation](#api-documentation) • [Project Structure](#project-structure)

</div>

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Key Features](#key-features)
3. [Technology Stack](#technology-stack)
4. [Architecture](#architecture)
5. [Project Structure](#project-structure)
6. [Component Documentation](#component-documentation)
7. [Installation & Setup](#installation--setup)
8. [API Documentation](#api-documentation)
9. [Development Guide](#development-guide)
10. [Database Schema](#database-schema)
11. [Environmental Variables](#environmental-variables)
12. [Deployment](#deployment)
13. [Contributing](#contributing)
14. [License](#license)

---

## 📱 Project Overview

**TinyTrails** is a modern, AI-powered hyperlocal e-commerce and food delivery platform designed for Indian food entrepreneurs and street vendors. The platform enables small food business owners to digitize their operations and connect directly with customers in their neighborhood without a middleman.

### 🎯 Core Unique Value Proposition

**AI Gatekeeper for Hygiene Verification**: An advanced computer vision system that ensures food vendors maintain hygiene standards through daily automated photo comparisons against baseline images.

- **Baseline Training**: Vendors upload 5 reference "clean" photos during onboarding
- **Daily Verification**: Each shift requires one live photo that's automatically compared against baselines
- **Anomaly Detection**: AI identifies areas that differ from the clean baseline using SSIM (Structural Similarity Index)
- **Bounding Box Visualization**: The system provides visual feedback on dirty/anomalous areas
- **Indian Kitchen Optimized**: Trained to handle typical Indian kitchen environments (stainless steel, compact spaces, lighting variations)

---

## 🌟 Key Features

### For Customers
- 🔍 **Hyperlocal Discovery**: Find food vendors within a specific radius (pincode-based)
- 🛒 **Easy Ordering**: Simple product browsing and shopping cart
- 💳 **Multiple Payment Options**: Razorpay integration for secure payments
- 📦 **Order Tracking**: Real-time order status updates
- 🌐 **Multi-language Support**: English and local language options
- ✅ **Hygiene Verified**: Buy from vendors verified by AI hygiene checks

### For Vendors (Entrepreneurs)
- 📊 **Dashboard**: Manage products, inventory, and orders
- 📸 **AI Hygiene Verification**: Daily automated compliance checks
- 📈 **Sales Analytics**: View order statistics and trends
- 👥 **Customer Management**: Direct communication without intermediaries
- 🎯 **Hyperlocal Reach**: Serve customers in their neighborhood efficiently

### For Administrators
- 🔐 **User Management**: Manage vendors, customers, and delivery personnel
- 📋 **Compliance Monitoring**: Monitor hygiene verification results
- 💰 **Payment Verification**: Track and verify all transactions
- 📊 **Platform Analytics**: Comprehensive business intelligence

---

## 🛠️ Technology Stack

### **Backend Services**

| Layer | Technology | Version | Purpose |
|-------|-----------|---------|---------|
| **Framework** | Spring Boot | 3.1.5 | REST API & Business Logic |
| **Language** | Java | 17 | Type-safe backend development |
| **Database** | MySQL | 8.0 | Relational data persistence |
| **ORM** | JPA/Hibernate | Latest | Object-relational mapping |
| **Security** | Spring Security + JWT | 0.11.5 | Authentication & authorization |
| **Validation** | Spring Validation | Latest | Request validation |
| **Payment** | Razorpay | 1.4.3 | Payment processing |

### **AI/ML & Hygiene Service**

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| **Framework** | FastAPI | 0.116.0 | High-performance async API |
| **Language** | Python | 3.10+ | ML & Computer Vision |
| **Deep Learning** | PyTorch | 2.0.0+ | Neural network models |
| **Vision Models** | TorchVision | 0.15.0+ | Pre-trained CNN models |
| **Computer Vision** | OpenCV | 4.8.0 | Image processing & bounding boxes |
| **SSIM Comparison** | scikit-image | 0.20.0 | Structural similarity analysis |
| **Image Processing** | PIL/Pillow | 10.0.0 | Image manipulation |
| **Data Augmentation** | Albumentations | 1.3.0 | Training data augmentation |
| **Server** | Uvicorn | 0.35.0 | ASGI Web server |

**ML Models:**
- **ResNet18/EfficientNet**: Hygiene classification (meets_standard, needs_work, shouldnt_work)
- **Siamese Network**: Baseline image comparison & similarity scoring
- **Custom SSIM Pipeline**: Anomaly detection with morphological analysis

### **Frontend (Web)**

| Layer | Technology | Version | Purpose |
|-------|-----------|---------|---------|
| **Framework** | React | 18.2.0 | UI component library |
| **Routing** | React Router | 6.16.0 | Client-side navigation |
| **HTTP Client** | Axios | 1.5.0 | API communication |
| **Forms** | React Hook Form | 7.46.1 | Form state management |
| **Styling** | Tailwind CSS | 3.3.3 | Utility-first CSS framework |
| **UI Components** | Lucide React | 0.284.0 | Icon library |
| **Notifications** | React Hot Toast | 2.4.1 | Toast notifications |
| **Build Tool** | Vite | 4.4.5 | Lightning-fast build tool |
| **Dev Server** | Vite Dev Server | Latest | Hot module replacement |

### **Frontend (Mobile)**

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Framework** | Flutter | Cross-platform mobile (iOS/Android) |
| **State Management** | Provider/GetX/BLoC | App state management |
| **Backend** | Firebase | Real-time database & authentication |
| **API Integration** | HTTP/Dio | Backend API calls |

### **DevOps & Infrastructure**

| Tool | Purpose |
|-----|---------|
| **Docker** | Containerization |
| **Docker Compose** | Multi-container orchestration |
| **GitHub Actions** | CI/CD pipeline |
| **MySQL Docker** | Database container |
| **CORS Middleware** | Cross-origin resource sharing |

---

## 🏗️ Architecture

### **High-Level System Architecture**

```
┌─────────────────────────────────────────────────────────────────┐
│                     Client Applications                          │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐  │
│  │  React Web App   │  │  Flutter Mobile  │  │ Admin Portal │  │
│  │  (Port 3000)     │  │  (Port 8081)     │  │ (Port 3001)  │  │
│  └────────┬─────────┘  └────────┬─────────┘  └──────┬───────┘  │
└───────────┼───────────────────────┼──────────────────┼──────────┘
            │                       │                  │
            └───────────────────────┼──────────────────┘
                                    │ HTTPS
                 ┌──────────────────┴──────────────────┐
                 │                                     │
            ┌────▼──────────────────────┐    ┌────────▼──────────┐
            │  Spring Boot Backend      │    │  Hygiene Service  │
            │  (Port 8080)              │    │  (Port 9000)      │
            │  REST API Server          │    │  FastAPI + PyTorch│
            └────┬──────────────────────┘    └────┬───────────────┘
                 │                               │
     ┌───────────┼───────────────────────────────┼──────────┐
     │           │                               │          │
     │      ┌────▼──────────┐            ┌──────▼──────┐   │
     │      │  MySQL DB     │            │  Vendor     │   │
     │      │  (Port 3306)  │            │  Baselines  │   │
     │      │               │            │  (File Sys) │   │
     │      └───────────────┘            └─────────────┘   │
     │
     └─────────────────────Docker Network──────────────────┘
```

### **Multi-Tier Architecture**

```
TIER 1: Presentation Layer
├── React Web Frontend (SPA)
├── Flutter Mobile App
└── Admin Dashboard

TIER 2: API Layer
├── Spring Boot REST Controllers
├── Request/Response DTOs
└── Error Handling Middleware

TIER 3: Business Logic Layer
├── Service Classes
├── Authentication & Authorization
├── Order Processing
└── Payment Management

TIER 4: AI/ML Service (Separate Microservice)
├── FastAPI Application
├── Computer Vision Models
├── Baseline Comparison Engine
└── Bounding Box Detection

TIER 5: Data Access Layer
├── JPA Repositories
├── MySQL Database
└── File Storage for Baselines

TIER 6: External Services
├── Razorpay Payment Gateway
└── Firebase (Mobile)
```

### **Data Flow for Hygiene Verification**

```
Vendor Setup Phase:
├── Vendor uploads 5 baseline images
├── Images stored in /vendor_baselines/{vendor_id}/
├── Models pre-process and store embeddings
└── System ready for daily checks

Daily Verification Phase:
├── Vendor submits today's workspace photo
├── Image resized to 512x512 standardization
├── SSIM comparison against baseline average
├── Bounding box detection for anomalies
├── Multi-layer scoring:
│   ├── SSIM Similarity Score
│   ├── Classification Score (ResNet18/EfficientNet)
│   └── Morphological Features
├── Final hygiene_score calculated
├── Passes/Fails inspection threshold
└── JSON response with feedback & boxes
```

---

## 📦 Project Structure

### **Root Directory Layout**

```
TinyTrail/
├── Code/                              # Main source code
│   ├── tiny-trail-backend/           # Java Spring Boot backend
│   ├── tiny-trail-frontend/          # React web frontend
│   └── tiny-trail-project/           # Docker & deployment configs
├── flutter_application_1/            # Flutter mobile app
├── hygiene_service/                  # AI/ML service (FastAPI)
├── Hygine/                           # Machine learning models & training
├── vendor_baselines/                 # Vendor baseline images storage
├── Documents/                        # Project documentation
├── .github/                          # GitHub Actions CI/CD
├── model/                            # Pre-trained ML models
├── test_images/                      # Test data for API testing
├── docker-compose.yml                # Docker orchestration
├── requirements_enhanced.txt          # Python dependencies
├── train_baseline_comparison.py       # ML training script
├── test_api.py                       # API test suite
└── README_EXTENSIVE.md               # This file
```

---

## 🔍 Component Documentation

### **1. Backend Service (Spring Boot)**

**Location:** `Code/tiny-trail-backend/`

#### Purpose
Core business logic, REST API, database management, and user authentication

#### Key Technologies
- Spring Boot 3.1.5
- MySQL 8.0
- JWT Authentication
- Spring Security
- Razorpay Integration

#### Directory Structure

```
src/main/java/com/tinytrail/
├── TinyTrailBackendApplication.java    # Main entry point
├── controller/                         # REST Controllers
│   ├── AuthController.java            # Login/Registration
│   ├── ProductController.java         # Product CRUD
│   ├── OrderController.java           # Order Management
│   └── PaymentController.java         # Payment Processing
├── service/                           # Business Logic
│   ├── UserService.java              # User operations
│   ├── ProductService.java           # Product operations
│   ├── OrderService.java             # Order operations
│   ├── PaymentService.java           # Payment operations
│   └── UserDetailsServiceImpl.java    # Spring Security integration
├── repository/                        # Data Access
│   ├── UserRepository.java           # User database access
│   ├── ProductRepository.java        # Product database access
│   ├── OrderRepository.java          # Order database access
│   └── PaymentRepository.java        # Payment database access
├── entity/                           # JPA Entities
│   ├── User.java                    # User model (CUSTOMER/ENTREPRENEUR)
│   ├── Product.java                 # Product listings
│   ├── Order.java                   # Orders
│   └── Payment.java                 # Payment records
├── dto/                             # Data Transfer Objects
│   ├── LoginRequest.java           # Login credentials
│   ├── SignupRequest.java          # Registration data
│   ├── JwtResponse.java            # JWT response
│   └── ApiResponse.java            # Standard API response
├── security/                        # Security Configuration
│   ├── SecurityConfig.java         # Spring Security setup
│   ├── JwtUtils.java              # JWT token generation/validation
│   ├── JwtAuthenticationFilter.java # JWT filter
│   └── JwtAuthenticationEntryPoint.java # Error handling
└── resources/
    └── application.yml             # Configuration file
```

#### Key Classes & Their Responsibilities

**User Entity**
```java
- Stores user information (name, email, password, role)
- Supports two roles: CUSTOMER, ENTREPRENEUR
- Implements Spring UserDetails for security
- Fields: id, name, email, password, role, pincode, phoneNumber,
         createdAt, updatedAt, isActive
```

**Product Entity**
```java
- Represents food items/products
- Links to ENTREPRENEUR vendors
- Tracks availability and category
- Supports pincode-based visibility
```

**Order Entity**
```java
- Purchase transactions
- Tracks order status (PENDING, CONFIRMED, DELIVERED, CANCELLED)
- Links customers and entrepreneurs
- Contains order items and amounts
```

**Payment Entity**
```java
- Razorpay payment records
- Tracks payment status and transaction IDs
- Linked to Orders
```

#### REST API Endpoints

**Authentication**
```
POST   /api/auth/signup           - Register new user
POST   /api/auth/signin           - Login & get JWT token
GET    /api/auth/me               - Get current user profile
```

**Products**
```
GET    /api/products/public/search           - Search products by pincode/category
GET    /api/products/public/{id}              - Get product details
GET    /api/products/public/categories        - Get categories by pincode
POST   /api/products                          - Create new product (ENTREPRENEUR only)
PUT    /api/products/{id}                     - Update product
DELETE /api/products/{id}                     - Delete product
GET    /api/products/my-products              - Get vendor's products
PUT    /api/products/{id}/toggle-availability - Toggle availability
```

**Orders**
```
POST   /api/orders                      - Create order
GET    /api/orders/my-orders            - Get customer orders
GET    /api/orders/entrepreneur-orders  - Get vendor orders
GET    /api/orders/{id}                 - Get order details
PUT    /api/orders/{id}/status          - Update order status
PUT    /api/orders/{id}/cancel          - Cancel order
GET    /api/orders/stats                - Get order statistics
```

**Payments**
```
POST   /api/payments/create-order       - Create Razorpay order
POST   /api/payments/verify             - Verify payment
POST   /api/payments/failure            - Handle payment failure
GET    /api/payments/order/{orderId}    - Get payment by order
```

#### Configuration

**Database (MySQL)**
```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/tiny_trail_db
    username: root
    password: password
    driver-class-name: com.mysql.cj.jdbc.Driver
  jpa:
    hibernate:
      ddl-auto: update  # Auto-generate tables
```

**Security**
```yaml
spring:
  security:
    jwt:
      secret: mySecretKey123456789012345678901234567890  # 432+ bits
      expiration: 86400000  # 24 hours in milliseconds
```

**CORS**
```yaml
cors:
  allowed-origins: http://localhost:3000,http://localhost:5173
  allowed-methods: GET,POST,PUT,DELETE,OPTIONS
  allow-credentials: true
```

---

### **2. AI Hygiene Service (FastAPI + PyTorch)**

**Location:** `hygiene_service/`

#### Purpose
Computer vision-based hygiene verification using baseline image comparison and anomaly detection

#### Key Technologies
- FastAPI 0.116.0 (async Python web framework)
- PyTorch 2.0+ (deep learning)
- OpenCV 4.8.0 (computer vision)
- scikit-image 0.20.0 (SSIM for image similarity)
- CUDA/CPU (GPU acceleration optional)

#### File Structure

```
hygiene_service/
├── app_enhanced.py                   # Main enhanced service (ACTIVE)
├── app.py                            # Basic service
├── app_new.py                        # Alternative implementation
├── app_yolo.py                       # YOLO-based variant
├── app_unified.py                    # Unified service
├── run_service.py                    # Service launcher
├── requirements.txt                  # Minimal dependencies
└── requirements_yolo.txt             # YOLO variant dependencies

Key Models:
├── SiameseNetwork                    # Baseline comparison model
├── ResNet18/EfficientNet             # Classification model
└── SSIM + Morphological Analysis     # Anomaly detection
```

#### Core Components

**SiameseNetwork Class**
```python
Purpose: Compare baseline images with daily photos
Architecture:
  ├── Backbone: ResNet18/EfficientNet (pre-trained)
  ├── Feature Extraction: 2048 features → embeddings
  ├── Projection: 256-dim → 128-dim embeddings (normalized)
  └── Classifier: Pair embeddings → similarity score (0-1)

Forward Pass:
  - Input: Two images (baseline, daily)
  - Output: Similarity score, embeddings
  - Higher score = images more similar
```

**HygieneAnalyzer Class**
```python
Purpose: Orchestrate all hygiene analysis
Methods:
  ├── setup_models()                      # Load classification & siamese models
  ├── setup_transforms()                  # Image preprocessing pipeline
  ├── load_vendor_baselines()             # Load stored baseline embeddings
  ├── preprocess_image()                  # Standardize image (512x512)
  ├── compute_ssim()                      # Structural similarity analysis
  ├── detect_anomalies()                  # Find dirty areas via SSIM diff
  ├── extract_bounding_boxes()            # Morphological operations → boxes
  ├── classify_hygiene()                  # ResNet18/EfficientNet prediction
  ├── generate_multi_layer_score()        # Combine SSIM + classification
  └── generate_feedback()                 # Human-readable explanations

Key Algorithms:
  1. SSIM (Structural Similarity Index)
     - Compares luminance, contrast, structure
     - Produces difference map highlighting changes
     - Threshold filtering for significant anomalies

  2. Morphological Analysis
     - Erosion/Dilation to clean noise
     - Contour detection to find connected anomalies
     - Bounding box extraction

  3. Multi-Layer Scoring
     - SSIM similarity: 0-1 score
     - Classification confidence: 0-1 score
     - Morphological feature density
     - Weighted average: final_score
```

#### API Endpoints

**Health Check**
```
GET /health
Response:
{
  "status": "healthy",
  "timestamp": "2025-04-01T10:00:00",
  "cuda_available": true
}
```

**Store Vendor Baselines**
```
POST /train-baseline
Content-Type: multipart/form-data

Request:
  vendor_id: "vendor_123"
  baseline_images: [file1.jpg, file2.jpg, file3.jpg, file4.jpg, file5.jpg]

Response:
{
  "vendor_id": "vendor_123",
  "baseline_count": 5,
  "status": "baseline_stored",
  "message": "Baselines stored successfully",
  "baseline_paths": ["/vendor_baselines/vendor_123/baseline_1.jpg", ...],
  "embedding_dim": 128,
  "timestamp": "2025-04-01T10:05:00"
}
```

**Verify Daily Image**
```
POST /verify-daily
Content-Type: multipart/form-data

Request:
  vendor_id: "vendor_123"
  daily_image: daily_photo.jpg

Response:
{
  "vendor_id": "vendor_123",
  "hygiene_score": 0.82,                    # Weighted score 0-1
  "passes_inspection": true,                # Boolean pass/fail
  "bounding_boxes": [                       # Anomaly locations
    [x1, y1, w1, h1],
    [x2, y2, w2, h2]
  ],
  "num_anomalies": 2,                      # Count of detected issues
  "classification_score": 0.85,            # ResNet18 score
  "ssim_score": 0.79,                      # SSIM match percentage
  "feedback": [                            # User-friendly messages
    "✅ Workspace appears clean",
    "⚠️ Small stain detected near cooking area",
    "✅ Equipment organized properly"
  ],
  "anomaly_description": "1-2 localized dirty spots",
  "timestamp": "2025-04-01T10:15:00"
}
```

**Get Vendor Baseline Info**
```
GET /vendor/{vendor_id}/baselines

Response:
{
  "vendor_id": "vendor_123",
  "baseline_count": 5,
  "last_updated": "2025-03-28T09:00:00",
  "baseline_images": [
    "/vendor_baselines/vendor_123/baseline_1.jpg",
    ...
  ]
}
```

#### Image Processing Pipeline

```
Input Image (any size)
    ↓
1. Load Image (PIL/OpenCV)
    ↓
2. Resize to 512x512 (standardization)
    ↓
3. Normalize (ImageNet normalization)
    ↓
4. Convert to Tensor (PyTorch)
    ↓
5. Model Inference (SiameseNetwork/ResNet18)
    ↓
6. SSIM Comparison (against baseline average)
    ↓
7. Compute Difference Map
    ↓
8. Threshold Filtering (identify significant changes)
    ↓
9. Morphological Operations (clean noise)
    ↓
10. Contour Detection (find regions)
    ↓
11. Extract Bounding Boxes
    ↓
12. Calculate Confidence Scores
    ↓
Output: hygiene_score + bounding_boxes + feedback
```

#### Model Architecture Details

**Siamese Network for Baseline Comparison**
```
Input: Two 512x512 RGB images

Branch 1 (Image 1):                    Branch 2 (Image 2):
    ↓                                      ↓
ResNet18/EfficientNet (frozen)      ResNet18/EfficientNet (frozen)
    ↓ (2048 features)                      ↓ (2048 features)
Projection Layer                     Projection Layer
├─ FC(2048 → 256)                   ├─ FC(2048 → 256)
├─ ReLU                             ├─ ReLU
├─ Dropout(0.3)                     ├─ Dropout(0.3)
└─ FC(256 → 128, normalized)        └─ FC(256 → 128, normalized)
    ↓ (128-dim embedding)                ↓ (128-dim embedding)
    └──────────────┬──────────────┘
                   ↓
        Concatenation (256-dim)
                   ↓
        Classifier Head:
        ├─ FC(256 → 64)
        ├─ ReLU
        ├─ Dropout(0.3)
        ├─ FC(64 → 32)
        ├─ ReLU
        ├─ FC(32 → 1)
        └─ Sigmoid (0-1 similarity score)
                   ↓
            Output: Similarity
```

**Classification Model (ResNet18)**
```
Pre-trained ResNet18:
    ↓
Last layer replaced with custom classifier
    ↓
3-class output: [meets_standard, needs_work, shouldnt_work]
    ↓
Softmax probabilities
```

#### Baseline Storage Strategy

```
/vendor_baselines/
├── vendor_001/
│   ├── baseline_1.jpg
│   ├── baseline_2.jpg
│   ├── baseline_3.jpg
│   ├── baseline_4.jpg
│   ├── baseline_5.jpg
│   └── metadata.json
│       {
│         "vendor_id": "vendor_001",
│         "upload_date": "2025-04-01",
│         "image_count": 5,
│         "avg_embedding": [...],  # Average of all embeddings
│         "embedding_dim": 128
│       }
├── vendor_002/
│   ├── baseline_1.jpg
│   ...
└── ...
```

---

### **3. React Web Frontend**

**Location:** `Code/tiny-trail-frontend/`

#### Purpose
Modern, responsive web interface for customers and vendors

#### Key Technologies
- React 18.2.0 (component-based UI)
- Vite 4.4.5 (fast build)
- Tailwind CSS 3.3.3 (styling)
- Axios 1.5.0 (HTTP requests)
- React Router 6.16.0 (navigation)
- React Hook Form 7.46.1 (form management)

#### Directory Structure

```
tiny-trail-frontend/
├── src/
│   ├── main.jsx                      # React entry point
│   ├── App.jsx                       # Root component
│   ├── pages/                        # Page components
│   │   ├── Home.jsx                 # Homepage
│   │   ├── Products.jsx             # Product listing
│   │   ├── ProductDetail.jsx        # Single product details
│   │   ├── Cart.jsx                 # Shopping cart
│   │   ├── Checkout.jsx             # Order checkout
│   │   ├── Orders.jsx               # Order history
│   │   ├── Dashboard.jsx            # Vendor dashboard
│   │   └── auth/
│   │       ├── Login.jsx            # Login page
│   │       └── Register.jsx         # Registration page
│   ├── components/                   # Reusable components
│   │   ├── layout/
│   │   │   └── Navbar.jsx           # Navigation bar
│   │   └── auth/
│   │       └── ProtectedRoute.jsx   # Route protection
│   ├── contexts/                     # React Context
│   │   ├── AuthContext.jsx          # Authentication state
│   │   └── LanguageContext.jsx      # Language/i18n state
│   ├── services/                     # Business logic
│   │   └── api.js                   # Axios instance & API calls
│   └── assets/                       # Images, fonts, etc.
├── package.json                      # Dependencies
├── vite.config.js                    # Vite configuration
├── tailwind.config.js                # Tailwind config
└── postcss.config.js                 # PostCSS config
```

#### Key Components

**App.jsx**
```jsx
Root component that sets up:
- Language provider (multi-language support)
- Auth provider (user authentication state)
- React Router (client-side routing)
- Toast notifications (feedback)

Routes:
├── Public
│   ├── / (Home)
│   ├── /login (Login)
│   ├── /register (Register)
│   ├── /products (Product listing)
│   └── /products/:id (Product detail)
└── Protected
    ├── /dashboard (Vendor only)
    ├── /orders (User orders)
    ├── /cart (Shopping cart)
    └── /checkout (Checkout)
```

**AuthContext.jsx**
```jsx
Manages authentication state globally:
- Current user info
- JWT token storage
- Login/logout functionality
- User role (CUSTOMER/ENTREPRENEUR)
- Protected route enforcement
```

**API Service (services/api.js)**
```javascript
Axios instance with:
- Base URL configuration from env
- Request/response interceptors
- Automatic JWT token injection
- 401 error handling (redirect to login)
- API methods organized by domain:
  ├── authAPI (login, register, getCurrentUser)
  ├── productsAPI (search, create, update, delete)
  ├── ordersAPI (create, getMyOrders, updateStatus)
  └── paymentsAPI (createOrder, verify)
```

#### Frontend Features

**Product Discovery**
```
GET /api/products/public/search?pincode=560034&category=food
├── Filter by pincode (hyperlocal)
├── Filter by category
├── Sort by rating/price
└── Display vendor info
```

**Shopping Cart**
```
State Management:
├── Add items to cart
├── Update quantities
├── Remove items
├── Calculate totals
└── Persist to localStorage
```

**Order Management**
```
Customer Side:
├── Create order from cart
├── Track order status
├── View order history
└── Cancel orders

Vendor Side:
├── View incoming orders
├── Update order status
├── Mark as delivered
└── View daily revenue
```

#### Styling Approach

```
Tailwind CSS Utility Classes:
├── Colors: Custom brand colors
├── Spacing: Consistent padding/margins
├── Responsive: Mobile-first design
├── Dark mode: Optional dark theme support
└── Components: Pre-built patterns
```

#### State Management

```
React Hooks:
├── useState: Local component state
├── useContext: Global auth/language state
├── useEffect: Side effects & data fetching
├── useNavigate: Programmatic routing
└── useParams: URL parameters
```

---

### **4. Flutter Mobile Application**

**Location:** `flutter_application_1/`

#### Purpose
Native mobile app for iOS and Android with Firebase integration

#### Key Technologies
- Flutter 3.0+ (cross-platform framework)
- Firebase (Backend-as-a-Service)
- Provider/GetX (state management)
- Dio/HTTP (API requests)

#### File Structure

```
flutter_application_1/
├── lib/
│   ├── main.dart                     # Entry point
│   ├── app.dart                      # App configuration
│   ├── bootstrap.dart                # App initialization
│   ├── splash.dart                   # Splash screen
│   ├── shell.dart                    # Navigation shell
│   ├── auth.dart                     # Authentication logic
│   ├── backend.dart                  # API/Firebase integration
│   ├── user_model.dart               # User data model
│   ├── shared.dart                   # Shared utilities
│   └── firebase_options.dart         # Firebase config
├── pubspec.yaml                      # Dependencies
├── android/                          # Android native code
├── ios/                              # iOS native code
└── web/                              # Web build
```

#### Key Pages

**Authentication Flow**
```
Splash Screen
    ↓
Login/Register
    ↓
Home Page (Product Listing)
```

**Customer Features**
- Browse products by location (pincode)
- View product details
- Add to cart
- Checkout and payment
- Track orders
- View hygiene verification status

**Vendor Features**
- Dashboard with sales stats
- Upload baseline images for hygiene system
- Daily hygiene verification submissions
- Manage product listings
- View orders and revenue

#### Firebase Integration

```
Authentication:
├── Email/Password auth
├── User profile storage
└── Role management (CUSTOMER/ENTREPRENEUR)

Realtime Database:
├── Product listings
├── Order updates
├── User profiles
└── Vendor baseline metadata
```

---

### **5. ML Training Module**

**Location:** `train_baseline_comparison.py` and `Hygine/`

#### Purpose
Train specialized models for baseline image comparison and hygiene classification

#### Script: `train_baseline_comparison.py`

**Dataset Organization Required:**
```
dataset/
├── baseline_clean/     # Clean reference images (5-10 per type)
├── clean/              # Additional clean images
├── dirty/              # Dirty/problematic images
└── moderate/           # Moderately dirty (optional)
```

**Training Process:**
```
1. Data Preparation
   ├── Load images
   ├── Apply augmentations (rotation, brightness, etc.)
   └── Create pairs for Siamese training

2. Model Training
   ├── Initialize Siamese Network
   ├── Forward pass with image pairs
   ├── Compute contrastive loss
   ├── Backpropagation
   └── Update weights

3. Validation
   ├── Test on validation set
   ├── Compute accuracy
   └── Save best model

4. Output
   └── Saved model checkpoint: .pth file
```

**Usage:**
```bash
python train_baseline_comparison.py \
  --data-dir ./dataset \
  --epochs 50 \
  --batch-size 16 \
  --learning-rate 0.001
```

---

## 🚀 Installation & Setup

### **Prerequisites**

- Java 17+
- Python 3.10+
- Node.js 18+
- Docker & Docker Compose
- MySQL 8.0 (or via Docker)
- Git

### **Step 1: Clone Repository**

```bash
git clone https://github.com/yourrepo/tinytrails.git
cd tinytrails
```

### **Step 2: Backend Setup (Spring Boot)**

```bash
cd Code/tiny-trail-backend

# Build the project
./mvnw clean package

# Or run directly
./mvnw spring-boot:run
```

**Configuration:**
Set environment variables in `.env` or `application-docker.yml`:
```bash
DB_USERNAME=root
DB_PASSWORD=password
JWT_SECRET=your-secret-key-123456789012345678901234567890
RAZORPAY_KEY_ID=your_razorpay_key_id
RAZORPAY_KEY_SECRET=your_razorpay_key_secret
```

Backend runs on: `http://localhost:8080`

### **Step 3: Frontend Setup (React)**

```bash
cd Code/tiny-trail-frontend

# Install dependencies
npm install

# Configure environment
echo "VITE_API_BASE_URL=http://localhost:8080/api" > .env.local

# Start dev server
npm run dev
```

Frontend runs on: `http://localhost:5173`

### **Step 4: AI Hygiene Service Setup (FastAPI)**

```bash
# Install Python dependencies
pip install -r requirements_enhanced.txt

# Start the service
cd hygiene_service
python app_enhanced.py
```

Service runs on: `http://localhost:9000`

### **Step 5: Database Setup (MySQL)**

```bash
# Option A: Using Docker
docker run -d \
  --name tiny-trail-mysql \
  -e MYSQL_ROOT_PASSWORD=password \
  -e MYSQL_DATABASE=tiny_trail_db \
  -p 3306:3306 \
  mysql:8.0

# Option B: Using Docker Compose
docker-compose -f Code/tiny-trail-project/docker-compose.yml up -d
```

### **Step 6: Flutter Mobile App Setup**

```bash
cd flutter_application_1

# Get dependencies
flutter pub get

# Configure Firebase (create google-services.json)
# Follow: https://firebase.google.com/docs/flutter/setup

# Run on emulator/device
flutter run
```

### **One-Command Setup (Docker Compose)**

```bash
cd Code/tiny-trail-project

# Start all services
docker-compose up -d

# Services available at:
# - Backend: http://localhost:8080/api
# - Frontend: http://localhost:3000
# - MySQL: localhost:3306
# - Hygiene Service: http://localhost:9000
```

---

## 📚 API Documentation

### **Authentication**

**Login**
```http
POST /api/auth/signin
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}

Response 200:
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "type": "Bearer",
  "id": 1,
  "email": "user@example.com",
  "name": "John Doe",
  "role": "CUSTOMER"
}
```

**Register**
```http
POST /api/auth/signup
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "role": "CUSTOMER",
  "pincode": "560034"
}

Response 201:
{
  "message": "User registered successfully",
  "user": { ... }
}
```

### **Products**

**Search Products**
```http
GET /api/products/public/search?pincode=560034&category=food&page=0&size=20

Response 200:
{
  "content": [
    {
      "id": 1,
      "name": "Dosa",
      "description": "Crispy south Indian dosa",
      "price": 80,
      "category": "food",
      "vendor": {
        "id": 1,
        "name": "Shanti Kitchen",
        "pincode": "560034"
      },
      "available": true
    }
  ],
  "totalElements": 50,
  "totalPages": 3,
  "currentPage": 0
}
```

### **Hygiene Service**

**Train Baseline**
```bash
curl -X POST "http://localhost:9000/train-baseline" \
  -F "vendor_id=vendor_001" \
  -F "baseline_images=@baseline1.jpg" \
  -F "baseline_images=@baseline2.jpg" \
  -F "baseline_images=@baseline3.jpg" \
  -F "baseline_images=@baseline4.jpg" \
  -F "baseline_images=@baseline5.jpg"
```

**Verify Daily Image**
```bash
curl -X POST "http://localhost:9000/verify-daily" \
  -F "vendor_id=vendor_001" \
  -F "daily_image=@today_photo.jpg"
```

---

## 👨‍💻 Development Guide

### **Coding Standards**

**Java (Backend)**
```
- Follow Java Naming Conventions
- Use appropriate annotations (
@Service, @Repository, @Controller, @Entity)
- Keep methods focused and small (<20 lines)
- Use logging instead of System.out.println
- Write unit tests for business logic
```

**Python (AI Service)**
```
- Follow PEP 8 style guide
- Type hints for function parameters
- Docstrings for all functions
- Comment complex algorithms
- Use logging module
```

**JavaScript/React (Frontend)**
```
- Use functional components with hooks
- Descriptive variable/function names
- Keep components small and focused
- Use React DevTools for debugging
- ESLint enforce consistency
```

### **Git Workflow**

```bash
# Create feature branch
git checkout -b feature/vendor-dashboard

# Commit frequently with clear messages
git commit -m "feat: add vendor dashboard with order stats"

# Push to remote
git push origin feature/vendor-dashboard

# Create Pull Request
# ...review, discuss, test...
# Merge to main after approval
```

### **Testing**

**Backend**
```bash
# Run tests with Maven
cd Code/tiny-trail-backend
./mvnw test
```

**Frontend**
```bash
# Run ESLint
npm run lint

# Run tests (if present)
npm test
```

**AI Service**
```bash
# Run test API against real endpoints
cd /t/College/Project/TinyTrail
python test_api.py
```

### **Debugging**

**Backend (Spring Boot)**
```
- Enable debug logs: logging.level.com.tinytrail=DEBUG
- Use IDE debugger (IntelliJ, VS Code)
- Check application.log files
```

**Frontend (React)**
```
- Use React DevTools Chrome extension
- Browser DevTools console
- Network tab for API calls
```

**AI Service (FastAPI)**
```
- Add print statements and logging
- Use FastAPI's interactive docs: http://localhost:9000/docs
- Check FastAPI logs
```

---

## 🗄️ Database Schema

### **Entity Relationship Diagram**

```
┌──────────────────┐         ┌──────────────────┐
│      USERS       │         │    PRODUCTS      │
├──────────────────┤         ├──────────────────┤
│ id (PK)          │ 1    *  │ id (PK)          │
│ name             ├────────>│ vendor_id (FK)   │
│ email (UNIQUE)   │         │ name             │
│ password         │         │ description      │
│ role             │         │ price            │
│ pincode          │         │ category         │
│ phone_number     │         │ available        │
│ is_active        │         │ created_at       │
│ created_at       │         │ updated_at       │
│ updated_at       │         └──────────────────┘
└──────────────────┘                  │
         │                            │ 1    *
         │ 1                          │
         │                    ┌──────────────┐
         │          ┌────────>│  ORDER_ITEMS │
         │          │         ├──────────────┤
         │          │         │ id (PK)      │
         │          │         │ order_id(FK) │
         │    ┌─────┴─────────│ product_id(FK)
         │    │               │ quantity     │
    ┌────▼────┴──────┐        │ price        │
    │     ORDERS     │        └──────────────┘
    ├────────────────┤
    │ id (PK)        │
    │ customer_id(FK)│
    │ vendor_id(FK)  │
    │ total_amount   │
    │ status         │
    │ created_at     │
    │ updated_at     │
    └────────────────┘
         │ 1    *
         │
    ┌────▼──────────┐
    │    PAYMENTS    │
    ├────────────────┤
    │ id (PK)        │
    │ order_id(FK)   │
    │ razorpay_id    │
    │ amount         │
    │ status         │
    │ created_at     │
    └────────────────┘
```

### **Key Tables**

**USERS**
|Field|Type|Constraints|
|-----|----|-----------|
|id|BIGINT|PRIMARY KEY AUTO_INCREMENT|
|name|VARCHAR(100)|NOT NULL|
|email|VARCHAR(100)|NOT NULL UNIQUE|
|password|VARCHAR(255)|NOT NULL|
|role|ENUM|CUSTOMER/ENTREPRENEUR|
|pincode|VARCHAR(6)|NOT NULL|
|phone_number|VARCHAR(10)|NULL|
|is_active|BOOLEAN|DEFAULT TRUE|
|created_at|DATETIME|AUTO|
|updated_at|DATETIME|AUTO|

**PRODUCTS**
|Field|Type|Constraints|
|-----|----|-----------|
|id|BIGINT|PRIMARY KEY|
|vendor_id|BIGINT|FOREIGN KEY(users.id)|
|name|VARCHAR(100)|NOT NULL|
|description|TEXT|NULL|
|price|DECIMAL(10,2)|NOT NULL|
|category|VARCHAR(50)|NOT NULL|
|available|BOOLEAN|DEFAULT TRUE|
|created_at|DATETIME|AUTO|
|updated_at|DATETIME|AUTO|

---

## 🔐 Environmental Variables

### **Backend (`application.yml` or `.env`)**

```yaml
# Database
DB_HOST: localhost
DB_PORT: 3306
DB_NAME: tiny_trail_db
DB_USERNAME: root
DB_PASSWORD: password

# JWT Security
JWT_SECRET: your-super-secret-key-must-be-at-least-32-chars-long
JWT_EXPIRATION: 86400000  # 24 hours in ms

# Razorpay
RAZORPAY_KEY_ID: rzp_test_xxxxxxxxxxxx
RAZORPAY_KEY_SECRET: xxxxxxxxxxxx

# CORS
CORS_ORIGINS: http://localhost:3000,http://localhost:5173,http://localhost:3001

# Server
SERVER_PORT: 8080
```

### **Frontend (`.env.local`)**

```bash
VITE_API_BASE_URL=http://localhost:8080/api
VITE_HYGIENE_SERVICE_URL=http://localhost:9000
```

### **AI Service (`.env` or hardcoded)**

```python
DEVICE: cuda  # or cpu
MODEL_DIR: ./Hygine/models
BASELINE_DIR: ./vendor_baselines
```

---

## 🐳 Deployment

### **Docker Deployment**

```bash
# Build all images
docker-compose build

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### **Production Checklist**

- ✅ Change JWT_SECRET to strong random value
- ✅ Set DB password to secure password
- ✅ Configure CORS origins for frontend domain
- ✅ Set up SSL/TLS certificates
- ✅ Configure Razorpay production keys
- ✅ Set up database backups
- ✅ Enable logging and monitoring
- ✅ Set up error tracking (Sentry/similar)
- ✅ Configure email service for notifications
- ✅ Set up CDN for static assets

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### **Contribution Guidelines**

- Write clear commit messages
- Add tests for new features
- Update documentation
- Follow coding standards
- Get peer reviews before merging

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 📞 Support & Contact

For support, questions, or feedback:
- 📧 Email: support@tinytrails.com
- 🐛 Issues: GitHub Issues
- 💬 Discussions: GitHub Discussions

---

## 🙏 Acknowledgments

- Spring Boot & Spring Security communities
- PyTorch & FastAPI frameworks
- React ecosystem
- Flutter framework
- Firebase platform
- Indian food entrepreneurs and vendors for inspiration

---

## 📊 Project Statistics

| Metric | Value |
|--------|-------|
| Backend Lines of Code | ~2,500 |
| AI Service Lines of Code | ~1,500 |
| Frontend Lines of Code | ~1,200 |
| Tests | ~50+ |
| Database Tables | 5 |
| API Endpoints | 25+ |
| Supported Languages | English + Local |

---

## 🗺️ Roadmap

### v1.1 (Q2 2025)
- [ ] Real-time order tracking with GPS
- [ ] Vendor rating and review system
- [ ] Advanced analytics dashboard
- [ ] SMS notifications

### v1.2 (Q3 2025)
- [ ] Multi-vendor order consolidation
- [ ] Loyalty program
- [ ] Subscription model support
- [ ] AI-powered demand forecasting

### v2.0 (Q4 2025)
- [ ] WhatsApp integration
- [ ] Hyperlocal delivery network
- [ ] Supply chain optimization
- [ ] Blockchain for payments

---

**Last Updated:** April 1, 2025
**Version:** 1.0.0
**Author:** TinyTrails Development Team

🚀 **TinyTrails** - Empowering hyperlocal food entrepreneurs through AI and technology.
