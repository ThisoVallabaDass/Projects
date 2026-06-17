-- Sample Users
INSERT INTO users (username, password, role, phone, email) VALUES
('admin', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVEFDi', 'ADMIN', '9876543210', 'admin@tinytrail.com'),
('john_buyer', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVEFDi', 'BUYER', '9876543211', 'john@example.com'),
('jane_seller', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVEFDi', 'SELLER', '9876543212', 'jane@example.com'),
('bob_seller', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVEFDi', 'SELLER', '9876543213', 'bob@example.com');

-- Sample Sellers
INSERT INTO sellers (user_id, shop_name, pincode, address, description) VALUES
(3, 'Jane''s Fresh Vegetables', '600001', '123 Main Street, Chennai', 'Fresh organic vegetables from local farms'),
(4, 'Bob''s Dairy Products', '600002', '456 Park Avenue, Chennai', 'Fresh dairy products and milk');

-- Sample Products
INSERT INTO products (seller_id, name, description, price, pincode, category) VALUES
(1, 'Fresh Tomatoes', 'Organic tomatoes from local farms', 50.00, '600001', 'Vegetables'),
(1, 'Organic Spinach', 'Fresh green spinach leaves', 30.00, '600001', 'Vegetables'),
(1, 'Local Potatoes', 'Fresh potatoes from nearby farms', 40.00, '600001', 'Vegetables'),
(1, 'Fresh Mangoes', 'Sweet Alphonso mangoes', 80.00, '600001', 'Fruits'),
(1, 'Bananas', 'Fresh yellow bananas', 20.00, '600001', 'Fruits'),
(2, 'Fresh Milk', 'Pure cow milk', 60.00, '600002', 'Dairy'),
(2, 'Paneer', 'Fresh homemade paneer', 120.00, '600002', 'Dairy'),
(2, 'Yogurt', 'Fresh curd', 40.00, '600002', 'Dairy'),
(2, 'Rice', 'Basmati rice', 100.00, '600002', 'Grains'),
(2, 'Wheat Flour', 'Whole wheat flour', 50.00, '600002', 'Grains');

-- Sample Orders
INSERT INTO orders (buyer_id, seller_id, total, status, delivery_address, payment_method, created_at) VALUES
(2, 1, 250.00, 'DELIVERED', '789 Oak Street, Chennai', 'UPI', '2024-01-15 10:00:00'),
(2, 1, 180.00, 'SHIPPED', '789 Oak Street, Chennai', 'UPI', '2024-01-20 14:30:00'),
(2, 2, 320.00, 'PENDING', '789 Oak Street, Chennai', 'COD', '2024-01-22 09:15:00');

-- Sample Order Items
INSERT INTO order_items (order_id, product_id, quantity, price) VALUES
(1, 1, 2, 50.00),
(1, 2, 1, 30.00),
(1, 3, 3, 40.00),
(2, 4, 2, 80.00),
(2, 5, 1, 20.00),
(3, 6, 1, 60.00),
(3, 7, 1, 120.00),
(3, 8, 1, 40.00),
(3, 9, 1, 100.00);
