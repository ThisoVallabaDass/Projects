-- Seed some sample vendors, products and a test collaborative cart
INSERT INTO vendor (id, name, tagline, story_text, is_verified_home_kitchen) VALUES
  (1, 'Murukku Mama', 'Crispy homemade murukku', 'We make murukku using traditional family recipe.', true),
  (2, 'Sundari Sweets', 'Handmade sweets and savories', 'Local sweets for festivals.', true),
  (3, 'Anbu Tiffins', 'Homestyle tiffins', 'Daily fresh tiffins.', false);

-- Note: adjust product table columns to your schema; this is a minimal seed for dev environment
INSERT INTO product (id, title, price) VALUES (101, 'Murukku (100g)', 50.00), (102, 'Samosa', 20.00);

INSERT INTO collaborative_cart (id, cart_code, expires_at, created_at) VALUES (1, 'TEST01', now() + interval '7 days', now());
