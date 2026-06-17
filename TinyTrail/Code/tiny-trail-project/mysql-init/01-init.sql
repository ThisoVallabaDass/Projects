-- Create database if not exists
CREATE DATABASE IF NOT EXISTS tiny_trail_db;

-- Use the database
USE tiny_trail_db;

-- Create demo users
INSERT IGNORE INTO users (id, name, email, password, role, pincode, phone_number, created_at, updated_at, is_active) VALUES
(1, 'Demo Customer', 'customer@demo.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'CUSTOMER', '600001', '9876543210', NOW(), NOW(), true),
(2, 'Demo Entrepreneur', 'entrepreneur@demo.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'ENTREPRENEUR', '600001', '9876543211', NOW(), NOW(), true);

-- Create demo products
INSERT IGNORE INTO products (id, name, description, price, category, language, entrepreneur_id, pincode, image_url, stock_quantity, is_available, created_at, updated_at) VALUES
(1, 'Handmade Organic Soap Set', 'A beautiful set of handmade organic soaps made with natural ingredients. Perfect for sensitive skin and daily use.', 450.00, 'Beauty & Personal Care', 'ENGLISH', 2, '600001', NULL, 25, true, NOW(), NOW()),
(2, 'Organic Honey', 'Pure organic honey sourced from local beekeepers. Rich in antioxidants and natural enzymes.', 300.00, 'Food & Beverages', 'ENGLISH', 2, '600001', NULL, 15, true, NOW(), NOW()),
(3, 'Cotton Eco Bags', 'Reusable cotton bags perfect for shopping. Eco-friendly alternative to plastic bags.', 200.00, 'Home & Garden', 'ENGLISH', 2, '600001', NULL, 50, true, NOW(), NOW());

-- Note: Password for demo accounts is 'password123' (BCrypt encoded)
