# TinyTrail - Complete Full-Stack Marketplace Application

A complete, production-ready marketplace application with:
- ✅ **Node.js Express Backend** with SQLite database
- ✅ **React Web Frontend** with Tailwind CSS
- 📱 **React Native Mobile App** (coming soon)
- 🐳 Docker support for easy deployment

## 📋 Features

### Backend API
- User authentication (JWT tokens)
- Product catalog with search and filtering
- Shopping cart management
- Order placement and tracking
- Seller onboarding
- User registration and login
- SQLite database with Flyway migrations

### Web Frontend (React + Tailwind)
- Beautiful, responsive UI
- User authentication
- Product search and filtering by pincode and category
- Shopping cart with add/remove items
- Checkout with delivery address and payment method
- Order history and tracking
- Seller dashboard (coming soon)

### Mobile App (React Native)
- All web features in a mobile-optimized interface
- Voice input support (coming soon)
- Collaborative shopping cart
- Multilingual support (English + Tamil)

## 🚀 Quick Start

### Prerequisites
- Node.js 18+ (https://nodejs.org/)
- npm or yarn

### 1. Start the Backend Server

```bash
cd packages/backend
npm install
npm start
```

Backend will run on: **http://localhost:8080**

Sample credentials:
- Username: `admin` / Password: `password123`
- Username: `john_buyer` / Password: `password123`
- Username: `jane_seller` / Password: `password123`

### 2. Start the Web Frontend

```bash
cd packages/web
npm install
npm start
```

Web app will run on: **http://localhost:3000**

### 3. Start the Mobile App (Coming Soon)

```bash
cd packages/mobile
npm install
npm start
```

## 📁 Project Structure

```
packages/
├── backend/              # Node.js Express API
│   ├── server.js        # Main server file
│   ├── package.json
│   ├── .env             # Environment variables
│   └── tinytrail.db     # SQLite database
│
├── web/                 # React web app
│   ├── src/
│   │   ├── App.jsx
│   │   ├── pages/       # Login, Products, Cart, Orders
│   │   ├── components/  # Navigation, etc.
│   │   └── App.css      # Tailwind CSS
│   ├── package.json
│   └── public/          # Static files
│
└── mobile/              # React Native app
    ├── app.json
    ├── package.json
    └── src/
```

## 🔌 API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/me` - Get current user info

### Products
- `GET /api/products` - List all products
- `GET /api/products/search` - Search products
- `GET /api/products/:id` - Get product details
- `GET /api/categories` - List categories

### Cart
- `POST /api/cart/add` - Add item to cart
- `POST /api/cart/remove` - Remove item from cart
- `GET /api/cart` - Get cart items
- `POST /api/cart/clear` - Clear cart

### Orders
- `POST /api/orders` - Place order
- `GET /api/orders` - Get user's orders
- `GET /api/orders/:id` - Get order details

### Sellers
- `POST /api/seller/onboard` - Become a seller
- `GET /api/sellers/:id` - Get seller profile

## 🔐 Sample Data

The backend automatically seeds sample data:

**Users:**
- admin@tinytrail.com (role: ADMIN)
- john@example.com (role: BUYER)
- jane@example.com (role: SELLER)

**Products:**
- Fresh Tomatoes (₹50)
- Organic Spinach (₹30)
- Local Potatoes (₹40)
- Fresh Mangoes (₹80)
- And more...

All sample users have password: `password123`

## 🛠️ Development

### Running Everything Together

```bash
npm install-all
npm dev
```

### Testing Backend API

```bash
# Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password123"}'

# Get token from response, then use it:
curl -H "Authorization: Bearer <TOKEN>" \
  http://localhost:8080/api/products

# Search products by pincode
curl "http://localhost:8080/api/products?pincode=600001"
```

## 📱 Mobile App (In Progress)

The mobile app is being built with React Native and Expo. Features include:
- Responsive mobile UI
- Voice-to-text product search
- Multilingual support (English + Tamil)
- Collaborative shopping cart via WebSocket
- Push notifications
- Offline support

## 🐳 Docker Deployment

```bash
# Build images
docker-compose build

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

## 📝 Environment Variables

### Backend (.env)
```
PORT=8080
JWT_SECRET=your-secret-key-change-in-production
DB_PATH=./tinytrail.db
NODE_ENV=development
```

### Web Frontend (.env)
```
REACT_APP_API_URL=http://localhost:8080
REACT_APP_WS_URL=ws://localhost:8080
```

## 🚨 Known Issues & TODOs

- [ ] Mobile app React Native UI
- [ ] Voice input for product search
- [ ] Real-time notifications with WebSocket
- [ ] Seller dashboard with analytics
- [ ] Payment gateway integration
- [ ] Image upload and storage
- [ ] Advanced search with filters
- [ ] User reviews and ratings
- [ ] Wishlist functionality
- [ ] Multi-language support (Tamil)

## 📚 Tech Stack

### Backend
- Node.js 18+
- Express.js 4.18
- SQLite3
- JWT authentication
- bcrypt for password hashing

### Frontend (Web)
- React 18
- React Router v6
- Axios for API calls
- Tailwind CSS for styling
- React Icons

### Frontend (Mobile)
- React Native
- Expo
- React Navigation
- NativeBase UI
- react-i18next for i18n

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Test thoroughly
4. Submit a pull request

## 📄 License

This project is open source and available under the MIT License.

## 🎯 Next Steps

1. ✅ Complete backend API
2. ✅ Build React web frontend
3. 📱 Build React Native mobile app
4. 🧪 Add comprehensive tests
5. 🐳 Docker containerization
6. 🚀 Deploy to production

## 📞 Support

For issues and questions:
- Create an issue on GitHub
- Check existing documentation
- Review sample code in the repository

---

**Happy coding! 🚀**

Built with ❤️ for local merchants and buyers
