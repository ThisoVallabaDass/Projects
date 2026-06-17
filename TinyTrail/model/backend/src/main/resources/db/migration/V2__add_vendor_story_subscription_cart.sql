-- TODO: Review types and adjust for your schema
ALTER TABLE vendor ADD COLUMN story_text TEXT;
ALTER TABLE vendor ADD COLUMN story_video_url TEXT;
ALTER TABLE vendor ADD COLUMN handwritten_menu_url TEXT;
ALTER TABLE vendor ADD COLUMN is_verified_home_kitchen BOOLEAN DEFAULT FALSE;

CREATE TABLE subscription_plan (
  id BIGSERIAL PRIMARY KEY,
  vendor_id BIGINT REFERENCES vendor(id),
  name VARCHAR(255),
  price NUMERIC(10,2),
  frequency VARCHAR(50),
  details_json TEXT
);

CREATE TABLE collaborative_cart (
  id BIGSERIAL PRIMARY KEY,
  cart_code VARCHAR(32) UNIQUE NOT NULL,
  expires_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE cart_item (
  id BIGSERIAL PRIMARY KEY,
  cart_id BIGINT REFERENCES collaborative_cart(id),
  product_id BIGINT,
  quantity INT,
  added_by BIGINT
);

CREATE INDEX idx_vendor_story ON vendor(id);
CREATE INDEX idx_cart_code ON collaborative_cart(cart_code);
-- Migration adapted for PostgreSQL

-- If there's a legacy sellers table, rename to vendors (ignore error if not exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'sellers') THEN
        ALTER TABLE sellers RENAME TO vendors;
    END IF;
END$$;

ALTER TABLE IF EXISTS vendors ADD COLUMN IF NOT EXISTS story_text TEXT;
ALTER TABLE IF EXISTS vendors ADD COLUMN IF NOT EXISTS story_video_url VARCHAR(255);
ALTER TABLE IF EXISTS vendors ADD COLUMN IF NOT EXISTS handwritten_menu_url VARCHAR(255);
ALTER TABLE IF EXISTS vendors ADD COLUMN IF NOT EXISTS is_verified_home_kitchen BOOLEAN DEFAULT FALSE;
ALTER TABLE IF EXISTS vendors ADD COLUMN IF NOT EXISTS avatar_url VARCHAR(255);

-- Create subscription_plan table
CREATE TABLE IF NOT EXISTS subscription_plan (
  id BIGSERIAL PRIMARY KEY,
  vendor_id BIGINT NOT NULL REFERENCES vendors(id),
  name VARCHAR(255),
  price NUMERIC(10,2),
  frequency VARCHAR(50),
  details_json JSONB
);

-- Create subscriptions
CREATE TABLE IF NOT EXISTS subscriptions (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id),
  plan_id BIGINT NOT NULL REFERENCES subscription_plan(id),
  status VARCHAR(50),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  expires_at TIMESTAMP WITH TIME ZONE
);

-- Collaborative cart and items
CREATE TABLE IF NOT EXISTS collaborative_cart (
  id BIGSERIAL PRIMARY KEY,
  cart_code VARCHAR(16) UNIQUE,
  expires_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS cart_item (
  id BIGSERIAL PRIMARY KEY,
  cart_id BIGINT REFERENCES collaborative_cart(id),
  product_id BIGINT,
  quantity INT,
  added_by_user_id BIGINT
);

CREATE TABLE IF NOT EXISTS cart_participants (
  cart_id BIGINT REFERENCES collaborative_cart(id),
  user_id BIGINT REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_vendor_pincode ON vendors(pincode);
CREATE INDEX IF NOT EXISTS idx_cart_code ON collaborative_cart(cart_code);

-- Seed sample vendors (use INSERT ... ON CONFLICT DO NOTHING)
INSERT INTO vendors (user_id, shop_name, pincode, address, story_text, is_verified_home_kitchen, avatar_url)
VALUES
(1, 'Ammachi Murukku', '600001', '1 Baker Street', 'Generations of murukku making', TRUE, 'https://via.placeholder.com/150'),
(2, 'Kumar Sweets', '600002', '12 Market Road', 'Traditional sweets from grandma', FALSE, 'https://via.placeholder.com/150'),
(3, 'Meena Meals', '600003', '5 Station Road', 'Homemade lunch boxes', FALSE, 'https://via.placeholder.com/150'),
(4, 'Raju Bakery', '600001', '88 High Street', 'Freshly baked breads', FALSE, 'https://via.placeholder.com/150'),
(5, 'Latha Tiffins', '600004', '9 Park Avenue', 'Comfort food and tiffins', FALSE, 'https://via.placeholder.com/150')
ON CONFLICT DO NOTHING;

-- Seed sample collaborative cart
INSERT INTO collaborative_cart (cart_code, expires_at) VALUES ('TEST01', now() + INTERVAL '2 days') ON CONFLICT DO NOTHING;
