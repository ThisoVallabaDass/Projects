import React from 'react';
import { useParams } from 'react-router-dom';
import { useLanguage } from '../contexts/LanguageContext';
import { MapPin, User, ShoppingCart, Star } from 'lucide-react';

const ProductDetail = () => {
  const { id } = useParams();
  const { t } = useLanguage();

  // Mock product data
  const product = {
    id: 1,
    name: 'Handmade Organic Soap Set',
    description: 'A beautiful set of handmade organic soaps made with natural ingredients. Perfect for sensitive skin and daily use. Each soap is carefully crafted with love and attention to detail.',
    price: 450,
    category: 'Beauty & Personal Care',
    language: 'ENGLISH',
    pincode: '600001',
    imageUrl: null,
    stockQuantity: 25,
    isAvailable: true,
    entrepreneur: {
      name: 'Priya Crafts',
      email: 'priya@example.com',
    },
    createdAt: '2023-10-15T10:30:00',
  };

  const formatPrice = (price) => {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR',
    }).format(price);
  };

  return (
    <div className="max-w-6xl mx-auto">
      <div className="grid md:grid-cols-2 gap-8">
        {/* Product Image */}
        <div className="space-y-4">
          <div className="aspect-square bg-gray-200 rounded-lg flex items-center justify-center">
            {product.imageUrl ? (
              <img
                src={product.imageUrl}
                alt={product.name}
                className="w-full h-full object-cover rounded-lg"
              />
            ) : (
              <div className="text-gray-400 text-center">
                <div className="w-16 h-16 mx-auto mb-4 bg-gray-300 rounded-lg flex items-center justify-center">
                  <ShoppingCart className="w-8 h-8" />
                </div>
                <span>No Image Available</span>
              </div>
            )}
          </div>
        </div>

        {/* Product Details */}
        <div className="space-y-6">
          <div>
            <div className="flex items-center space-x-2 mb-2">
              <span className={`badge ${
                product.language === 'TAMIL' ? 'badge-info' : 'badge-success'
              }`}>
                {product.language === 'TAMIL' ? 'தமிழ்' : 'EN'}
              </span>
              <span className="badge badge-info">{product.category}</span>
            </div>
            
            <h1 className="text-3xl font-bold text-gray-900 mb-2">
              {product.name}
            </h1>
            
            <div className="flex items-center space-x-4 text-gray-600 mb-4">
              <div className="flex items-center space-x-1">
                <User className="w-4 h-4" />
                <span>By {product.entrepreneur.name}</span>
              </div>
              <div className="flex items-center space-x-1">
                <MapPin className="w-4 h-4" />
                <span>{product.pincode}</span>
              </div>
            </div>

            <div className="text-3xl font-bold text-primary-600 mb-6">
              {formatPrice(product.price)}
            </div>
          </div>

          <div>
            <h3 className="text-lg font-semibold text-gray-900 mb-2">
              Description
            </h3>
            <p className="text-gray-700 leading-relaxed">
              {product.description}
            </p>
          </div>

          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-gray-700">Stock Available:</span>
              <span className="font-medium text-gray-900">
                {product.stockQuantity} units
              </span>
            </div>
            
            <div className="flex items-center justify-between">
              <span className="text-gray-700">Status:</span>
              <span className={`badge ${
                product.isAvailable ? 'badge-success' : 'badge-error'
              }`}>
                {product.isAvailable ? 'Available' : 'Out of Stock'}
              </span>
            </div>
          </div>

          {/* Quantity and Add to Cart */}
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Quantity
              </label>
              <select className="input w-32">
                {[...Array(Math.min(10, product.stockQuantity))].map((_, i) => (
                  <option key={i + 1} value={i + 1}>
                    {i + 1}
                  </option>
                ))}
              </select>
            </div>

            <div className="flex space-x-4">
              <button 
                className="flex-1 btn btn-primary flex items-center justify-center space-x-2"
                disabled={!product.isAvailable}
              >
                <ShoppingCart className="w-5 h-5" />
                <span>Add to Cart</span>
              </button>
              <button 
                className="flex-1 btn btn-outline"
                disabled={!product.isAvailable}
              >
                Buy Now
              </button>
            </div>
          </div>

          {/* Entrepreneur Info */}
          <div className="card">
            <div className="card-body">
              <h3 className="text-lg font-semibold text-gray-900 mb-3">
                About the Entrepreneur
              </h3>
              <div className="flex items-center space-x-3">
                <div className="w-12 h-12 bg-primary-100 rounded-full flex items-center justify-center">
                  <User className="w-6 h-6 text-primary-600" />
                </div>
                <div>
                  <h4 className="font-medium text-gray-900">
                    {product.entrepreneur.name}
                  </h4>
                  <p className="text-sm text-gray-600">
                    Local entrepreneur in {product.pincode}
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ProductDetail;
