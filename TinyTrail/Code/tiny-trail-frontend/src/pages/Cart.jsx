import React from 'react';
import { Link } from 'react-router-dom';
import { useLanguage } from '../contexts/LanguageContext';
import { ShoppingCart, Trash2, Plus, Minus } from 'lucide-react';

const Cart = () => {
  const { t } = useLanguage();

  // Mock cart data
  const cartItems = [
    {
      id: 1,
      productId: 1,
      name: 'Handmade Organic Soap Set',
      price: 450,
      quantity: 2,
      entrepreneur: 'Priya Crafts',
      imageUrl: null,
    },
    {
      id: 2,
      productId: 2,
      name: 'Organic Honey',
      price: 300,
      quantity: 1,
      entrepreneur: 'Nature\'s Best',
      imageUrl: null,
    },
  ];

  const formatPrice = (price) => {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR',
    }).format(price);
  };

  const calculateSubtotal = () => {
    return cartItems.reduce((total, item) => total + (item.price * item.quantity), 0);
  };

  const calculateTotal = () => {
    const subtotal = calculateSubtotal();
    const shipping = 50; // Fixed shipping cost
    return subtotal + shipping;
  };

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold text-gray-900">
          Shopping Cart
        </h1>
        <span className="text-gray-600">
          {cartItems.length} {cartItems.length === 1 ? 'item' : 'items'}
        </span>
      </div>

      {cartItems.length > 0 ? (
        <div className="grid lg:grid-cols-3 gap-8">
          {/* Cart Items */}
          <div className="lg:col-span-2 space-y-4">
            {cartItems.map((item) => (
              <div key={item.id} className="card">
                <div className="card-body">
                  <div className="flex items-center space-x-4">
                    {/* Product Image */}
                    <div className="w-20 h-20 bg-gray-200 rounded-lg flex items-center justify-center flex-shrink-0">
                      {item.imageUrl ? (
                        <img
                          src={item.imageUrl}
                          alt={item.name}
                          className="w-full h-full object-cover rounded-lg"
                        />
                      ) : (
                        <ShoppingCart className="w-8 h-8 text-gray-400" />
                      )}
                    </div>

                    {/* Product Details */}
                    <div className="flex-1">
                      <h3 className="font-semibold text-gray-900 mb-1">
                        {item.name}
                      </h3>
                      <p className="text-sm text-gray-600 mb-2">
                        By {item.entrepreneur}
                      </p>
                      <p className="text-lg font-bold text-primary-600">
                        {formatPrice(item.price)}
                      </p>
                    </div>

                    {/* Quantity Controls */}
                    <div className="flex items-center space-x-3">
                      <button className="w-8 h-8 rounded-full border border-gray-300 flex items-center justify-center hover:bg-gray-50">
                        <Minus className="w-4 h-4" />
                      </button>
                      <span className="w-8 text-center font-medium">
                        {item.quantity}
                      </span>
                      <button className="w-8 h-8 rounded-full border border-gray-300 flex items-center justify-center hover:bg-gray-50">
                        <Plus className="w-4 h-4" />
                      </button>
                    </div>

                    {/* Remove Button */}
                    <button className="text-red-600 hover:text-red-700 p-2">
                      <Trash2 className="w-5 h-5" />
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* Order Summary */}
          <div className="lg:col-span-1">
            <div className="card sticky top-4">
              <div className="card-header">
                <h2 className="text-lg font-semibold text-gray-900">
                  Order Summary
                </h2>
              </div>
              <div className="card-body space-y-4">
                <div className="flex justify-between">
                  <span className="text-gray-600">Subtotal</span>
                  <span className="font-medium">{formatPrice(calculateSubtotal())}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Shipping</span>
                  <span className="font-medium">{formatPrice(50)}</span>
                </div>
                <div className="border-t pt-4">
                  <div className="flex justify-between">
                    <span className="text-lg font-semibold text-gray-900">Total</span>
                    <span className="text-lg font-bold text-primary-600">
                      {formatPrice(calculateTotal())}
                    </span>
                  </div>
                </div>
                
                <Link
                  to="/checkout"
                  className="w-full btn btn-primary flex items-center justify-center space-x-2"
                >
                  <span>Proceed to Checkout</span>
                </Link>
                
                <Link
                  to="/products"
                  className="w-full btn btn-outline text-center"
                >
                  Continue Shopping
                </Link>
              </div>
            </div>
          </div>
        </div>
      ) : (
        <div className="text-center py-12">
          <div className="w-16 h-16 mx-auto mb-4 bg-gray-200 rounded-lg flex items-center justify-center">
            <ShoppingCart className="w-8 h-8 text-gray-400" />
          </div>
          <h3 className="text-lg font-medium text-gray-900 mb-2">
            Your cart is empty
          </h3>
          <p className="text-gray-600 mb-4">
            Add some products to get started.
          </p>
          <Link to="/products" className="btn btn-primary">
            Start Shopping
          </Link>
        </div>
      )}
    </div>
  );
};

export default Cart;
