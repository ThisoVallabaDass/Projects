import React from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { useLanguage } from '../contexts/LanguageContext';
import { 
  ShoppingBag, 
  Users, 
  MapPin, 
  Star, 
  ArrowRight,
  Package,
  Shield,
  Zap
} from 'lucide-react';

const Home = () => {
  const { isAuthenticated, user } = useAuth();
  const { t } = useLanguage();

  const features = [
    {
      icon: MapPin,
      title: 'Local Discovery',
      description: 'Find products from entrepreneurs in your area using pincode-based search.',
    },
    {
      icon: Shield,
      title: 'Secure Payments',
      description: 'Safe and secure UPI payments powered by Razorpay integration.',
    },
    {
      icon: Users,
      title: 'Community Driven',
      description: 'Connect local entrepreneurs with nearby customers in your community.',
    },
    {
      icon: Zap,
      title: 'Multilingual',
      description: 'Support for both English and Tamil languages for better accessibility.',
    },
  ];

  const stats = [
    { label: 'Local Entrepreneurs', value: '500+' },
    { label: 'Products Listed', value: '2,000+' },
    { label: 'Happy Customers', value: '1,500+' },
    { label: 'Cities Covered', value: '50+' },
  ];

  return (
    <div className="space-y-16">
      {/* Hero Section */}
      <section className="text-center py-16">
        <div className="max-w-4xl mx-auto">
          <h1 className="text-5xl font-bold text-gray-900 mb-6">
            {t('welcome')}
          </h1>
          <p className="text-xl text-gray-600 mb-4">
            {t('tagline')}
          </p>
          <p className="text-lg text-gray-500 mb-8 max-w-2xl mx-auto">
            A localized marketplace connecting home entrepreneurs with nearby customers. 
            Discover unique products from your community and support local businesses.
          </p>
          
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            {isAuthenticated ? (
              <>
                <Link
                  to="/products"
                  className="btn btn-primary flex items-center justify-center space-x-2"
                >
                  <ShoppingBag className="w-5 h-5" />
                  <span>Browse {t('products')}</span>
                </Link>
                <Link
                  to="/dashboard"
                  className="btn btn-outline flex items-center justify-center space-x-2"
                >
                  <Package className="w-5 h-5" />
                  <span>Go to {t('dashboard')}</span>
                </Link>
              </>
            ) : (
              <>
                <Link
                  to="/register"
                  className="btn btn-primary flex items-center justify-center space-x-2"
                >
                  <Users className="w-5 h-5" />
                  <span>Join Now</span>
                </Link>
                <Link
                  to="/products"
                  className="btn btn-outline flex items-center justify-center space-x-2"
                >
                  <ShoppingBag className="w-5 h-5" />
                  <span>Browse Products</span>
                </Link>
              </>
            )}
          </div>
        </div>
      </section>

      {/* Stats Section */}
      <section className="py-16 bg-primary-50">
        <div className="max-w-6xl mx-auto">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-8">
            {stats.map((stat, index) => (
              <div key={index} className="text-center">
                <div className="text-3xl font-bold text-primary-600 mb-2">
                  {stat.value}
                </div>
                <div className="text-gray-600">
                  {stat.label}
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-16">
        <div className="max-w-6xl mx-auto">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-bold text-gray-900 mb-4">
              Why Choose Tiny Trail?
            </h2>
            <p className="text-lg text-gray-600 max-w-2xl mx-auto">
              We're building a platform that brings communities together through local commerce.
            </p>
          </div>
          
          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
            {features.map((feature, index) => (
              <div key={index} className="card text-center">
                <div className="card-body">
                  <div className="w-12 h-12 bg-primary-100 rounded-lg flex items-center justify-center mx-auto mb-4">
                    <feature.icon className="w-6 h-6 text-primary-600" />
                  </div>
                  <h3 className="text-lg font-semibold text-gray-900 mb-2">
                    {feature.title}
                  </h3>
                  <p className="text-gray-600 text-sm">
                    {feature.description}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* How It Works Section */}
      <section className="py-16 bg-gray-100">
        <div className="max-w-6xl mx-auto">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-bold text-gray-900 mb-4">
              How It Works
            </h2>
          </div>
          
          <div className="grid md:grid-cols-2 gap-12">
            {/* For Customers */}
            <div className="space-y-6">
              <h3 className="text-xl font-semibold text-gray-900 flex items-center">
                <ShoppingBag className="w-6 h-6 text-primary-600 mr-2" />
                For Customers
              </h3>
              <div className="space-y-4">
                <div className="flex items-start space-x-3">
                  <div className="w-8 h-8 bg-primary-600 text-white rounded-full flex items-center justify-center text-sm font-semibold">
                    1
                  </div>
                  <div>
                    <h4 className="font-medium text-gray-900">Search by Pincode</h4>
                    <p className="text-gray-600 text-sm">Enter your pincode to find products from local entrepreneurs.</p>
                  </div>
                </div>
                <div className="flex items-start space-x-3">
                  <div className="w-8 h-8 bg-primary-600 text-white rounded-full flex items-center justify-center text-sm font-semibold">
                    2
                  </div>
                  <div>
                    <h4 className="font-medium text-gray-900">Browse & Order</h4>
                    <p className="text-gray-600 text-sm">Explore products, read descriptions, and place your order.</p>
                  </div>
                </div>
                <div className="flex items-start space-x-3">
                  <div className="w-8 h-8 bg-primary-600 text-white rounded-full flex items-center justify-center text-sm font-semibold">
                    3
                  </div>
                  <div>
                    <h4 className="font-medium text-gray-900">Secure Payment</h4>
                    <p className="text-gray-600 text-sm">Pay securely using UPI and track your order status.</p>
                  </div>
                </div>
              </div>
            </div>

            {/* For Entrepreneurs */}
            <div className="space-y-6">
              <h3 className="text-xl font-semibold text-gray-900 flex items-center">
                <Package className="w-6 h-6 text-primary-600 mr-2" />
                For Entrepreneurs
              </h3>
              <div className="space-y-4">
                <div className="flex items-start space-x-3">
                  <div className="w-8 h-8 bg-secondary-600 text-white rounded-full flex items-center justify-center text-sm font-semibold">
                    1
                  </div>
                  <div>
                    <h4 className="font-medium text-gray-900">Create Account</h4>
                    <p className="text-gray-600 text-sm">Sign up as an entrepreneur and set up your profile.</p>
                  </div>
                </div>
                <div className="flex items-start space-x-3">
                  <div className="w-8 h-8 bg-secondary-600 text-white rounded-full flex items-center justify-center text-sm font-semibold">
                    2
                  </div>
                  <div>
                    <h4 className="font-medium text-gray-900">List Products</h4>
                    <p className="text-gray-600 text-sm">Add your products with photos, descriptions, and pricing.</p>
                  </div>
                </div>
                <div className="flex items-start space-x-3">
                  <div className="w-8 h-8 bg-secondary-600 text-white rounded-full flex items-center justify-center text-sm font-semibold">
                    3
                  </div>
                  <div>
                    <h4 className="font-medium text-gray-900">Manage Orders</h4>
                    <p className="text-gray-600 text-sm">Receive orders, update status, and grow your business.</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-16 bg-primary-600 text-white">
        <div className="max-w-4xl mx-auto text-center">
          <h2 className="text-3xl font-bold mb-4">
            Ready to Get Started?
          </h2>
          <p className="text-xl mb-8 opacity-90">
            Join thousands of entrepreneurs and customers building stronger communities.
          </p>
          
          {!isAuthenticated && (
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Link
                to="/register"
                className="bg-white text-primary-600 px-8 py-3 rounded-lg font-semibold hover:bg-gray-100 transition-colors flex items-center justify-center space-x-2"
              >
                <span>Start Selling</span>
                <ArrowRight className="w-5 h-5" />
              </Link>
              <Link
                to="/products"
                className="border-2 border-white text-white px-8 py-3 rounded-lg font-semibold hover:bg-white hover:text-primary-600 transition-colors flex items-center justify-center space-x-2"
              >
                <span>Start Shopping</span>
                <ArrowRight className="w-5 h-5" />
              </Link>
            </div>
          )}
        </div>
      </section>
    </div>
  );
};

export default Home;
