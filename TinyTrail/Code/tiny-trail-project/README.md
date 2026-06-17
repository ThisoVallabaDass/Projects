# Tiny Trail: A Digital Marketplace - From Home to Your Hands

A localized, web-based marketplace that connects home entrepreneurs with nearby customers. Built with Spring Boot backend and React frontend, featuring Tamil and English support, secure UPI payments, JWT authentication, and pincode-based product discovery.

## 🚀 Features

### Core Features
- **User Authentication**: JWT-based secure login/signup with role management (Customer/Entrepreneur)
- **Product Management**: Entrepreneurs can add, edit, delete products with multilingual support
- **Marketplace**: Customers can browse/search products by pincode or category
- **Order Management**: Complete order lifecycle with status tracking
- **Secure Payments**: UPI-based payments via Razorpay integration
- **Multilingual Support**: English and Tamil language toggle
- **Responsive Design**: Modern UI with Tailwind CSS

### Technical Features
- **Backend**: Spring Boot 3.1.5 with REST APIs
- **Frontend**: React 18 with Vite and Tailwind CSS
- **Database**: MySQL with JPA/Hibernate
- **Authentication**: JWT tokens with Spring Security
- **Payments**: Razorpay integration for UPI payments
- **Containerization**: Docker and Docker Compose ready

## 🏗️ Project Structure

```
tiny-trail-project/
├── tiny-trail-backend/          # Spring Boot backend
│   ├── src/main/java/com/tinytrail/
│   │   ├── controller/          # REST controllers
│   │   ├── entity/             # JPA entities
│   │   ├── repository/         # Data repositories
│   │   ├── service/            # Business logic
│   │   ├── security/           # JWT security config
│   │   └── dto/                # Data transfer objects
│   ├── src/main/resources/
│   │   └── application.yml     # Configuration
│   ├── pom.xml                 # Maven dependencies
│   └── Dockerfile              # Backend container
├── tiny-trail-frontend/         # React frontend
│   ├── src/
│   │   ├── components/         # React components
│   │   ├── pages/              # Page components
│   │   ├── contexts/           # React contexts
│   │   ├── services/           # API services
│   │   └── App.jsx             # Main app component
│   ├── package.json            # NPM dependencies
│   └── Dockerfile              # Frontend container
├── docker-compose.yml          # Multi-container setup
└── README.md                   # This file
```

## 🛠️ Tech Stack

### Backend
- **Framework**: Spring Boot 3.1.5
- **Language**: Java 17
- **Database**: MySQL 8.0
- **Security**: Spring Security with JWT
- **Build Tool**: Maven
- **Payment**: Razorpay Java SDK

### Frontend
- **Framework**: React 18
- **Build Tool**: Vite
- **Styling**: Tailwind CSS
- **Routing**: React Router DOM
- **HTTP Client**: Axios
- **Forms**: React Hook Form
- **Notifications**: React Hot Toast

### Database Schema
- **Users**: id, name, email, password, role, pincode, phone_number
- **Products**: id, name, description, price, category, language, entrepreneur_id, pincode
- **Orders**: id, user_id, product_id, quantity, status, payment_status, delivery_address
- **Payments**: id, order_id, transaction_id, razorpay_payment_id, status, method

## 🚀 Getting Started

### Prerequisites
- Java 17+
- Node.js 18+
- MySQL 8.0+
- Docker & Docker Compose (optional)

### Option 1: Docker Compose (Recommended)

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd tiny-trail-project
   ```

2. **Update Razorpay credentials** (optional for testing)
   ```bash
   # Edit docker-compose.yml and update:
   - RAZORPAY_KEY_ID=your_actual_razorpay_key_id
   - RAZORPAY_KEY_SECRET=your_actual_razorpay_key_secret
   ```

3. **Start all services**
   ```bash
   docker-compose up -d
   ```

4. **Access the application**
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:8080/api
   - MySQL: localhost:3306

### Option 2: Manual Setup

#### Backend Setup
1. **Navigate to backend directory**
   ```bash
   cd tiny-trail-backend
   ```

2. **Update database configuration**
   ```yaml
   # src/main/resources/application.yml
   spring:
     datasource:
       url: jdbc:mysql://localhost:3306/tiny_trail_db
       username: your_db_username
       password: your_db_password
   ```

3. **Run the backend**
   ```bash
   ./mvnw spring-boot:run
   ```

#### Frontend Setup
1. **Navigate to frontend directory**
   ```bash
   cd tiny-trail-frontend
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Start development server**
   ```bash
   npm run dev
   ```

## 🔧 Configuration

### Environment Variables

#### Backend (.env or application.yml)
```yaml
DB_USERNAME=your_db_username
DB_PASSWORD=your_db_password
JWT_SECRET=your_jwt_secret_key
RAZORPAY_KEY_ID=your_razorpay_key_id
RAZORPAY_KEY_SECRET=your_razorpay_key_secret
```

#### Frontend (.env)
```env
VITE_API_BASE_URL=http://localhost:8080/api
```

## 📱 Usage

### For Customers
1. **Register** as a Customer with your pincode
2. **Browse Products** by entering your pincode
3. **Search & Filter** products by category or keywords
4. **Place Orders** and make secure payments
5. **Track Orders** through your dashboard

### For Entrepreneurs
1. **Register** as an Entrepreneur
2. **Add Products** with descriptions in English or Tamil
3. **Manage Inventory** and update product availability
4. **Process Orders** and update order status
5. **View Analytics** in your dashboard

## 🔐 API Endpoints

### Authentication
- `POST /api/auth/signin` - User login
- `POST /api/auth/signup` - User registration
- `GET /api/auth/me` - Get current user

### Products
- `GET /api/products/public/search` - Search products (public)
- `GET /api/products/public/{id}` - Get product details (public)
- `POST /api/products` - Create product (entrepreneur only)
- `PUT /api/products/{id}` - Update product (entrepreneur only)
- `DELETE /api/products/{id}` - Delete product (entrepreneur only)

### Orders
- `POST /api/orders` - Create order
- `GET /api/orders/my-orders` - Get user orders
- `GET /api/orders/entrepreneur-orders` - Get entrepreneur orders
- `PUT /api/orders/{id}/status` - Update order status

### Payments
- `POST /api/payments/create-order` - Create Razorpay order
- `POST /api/payments/verify` - Verify payment
- `GET /api/payments/order/{orderId}` - Get payment details

## 🌐 Multilingual Support

The application supports both English and Tamil languages:
- **Language Toggle**: Available in the navigation bar
- **Product Listings**: Support for Tamil and English product descriptions
- **UI Translation**: Key interface elements translated
- **Database Support**: Language field in products table

## 💳 Payment Integration

### Razorpay Setup
1. Create a Razorpay account at https://razorpay.com
2. Get your Key ID and Key Secret from the dashboard
3. Update the configuration with your credentials
4. Test with Razorpay test mode initially

### Supported Payment Methods
- UPI (Google Pay, PhonePe, Paytm, etc.)
- Credit/Debit Cards
- Net Banking
- Digital Wallets

## 🚀 Deployment

### Docker Deployment
```bash
# Build and start all services
docker-compose up -d --build

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### Production Considerations
1. **Database**: Use managed MySQL service (AWS RDS, etc.)
2. **Environment Variables**: Use secure secret management
3. **SSL/TLS**: Configure HTTPS with proper certificates
4. **Load Balancing**: Use nginx or cloud load balancers
5. **Monitoring**: Add application monitoring and logging

## 🧪 Testing

### Backend Testing
```bash
cd tiny-trail-backend
./mvnw test
```

### Frontend Testing
```bash
cd tiny-trail-frontend
npm test
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation

## 🔮 Future Enhancements

- **AI-powered Product Categorization**
- **Voice Input for Product Listings**
- **Advanced Analytics Dashboard**
- **Mobile App (React Native)**
- **Logistics Integration**
- **Multi-vendor Support**
- **Review and Rating System**
- **Real-time Chat Support**

---

**Tiny Trail** - Connecting communities through local commerce! 🛒✨
