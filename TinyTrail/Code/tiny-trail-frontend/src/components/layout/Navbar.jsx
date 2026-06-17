import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { useLanguage } from '../../contexts/LanguageContext';
import { 
  Menu, 
  X, 
  ShoppingCart, 
  User, 
  LogOut, 
  Package, 
  BarChart3,
  Globe
} from 'lucide-react';

const Navbar = () => {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [isUserMenuOpen, setIsUserMenuOpen] = useState(false);
  const { user, logout, isAuthenticated, isEntrepreneur } = useAuth();
  const { t, language, changeLanguage } = useLanguage();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate('/');
    setIsUserMenuOpen(false);
  };

  const toggleLanguage = () => {
    changeLanguage(language === 'en' ? 'ta' : 'en');
  };

  return (
    <nav className="bg-white shadow-lg border-b border-gray-200">
      <div className="container mx-auto px-4">
        <div className="flex justify-between items-center h-16">
          {/* Logo */}
          <Link to="/" className="flex items-center space-x-2">
            <div className="w-8 h-8 bg-primary-600 rounded-lg flex items-center justify-center">
              <span className="text-white font-bold text-sm">TT</span>
            </div>
            <span className="text-xl font-bold text-gray-900">Tiny Trail</span>
          </Link>

          {/* Desktop Navigation */}
          <div className="hidden md:flex items-center space-x-8">
            <Link 
              to="/" 
              className="text-gray-700 hover:text-primary-600 transition-colors"
            >
              {t('home')}
            </Link>
            <Link 
              to="/products" 
              className="text-gray-700 hover:text-primary-600 transition-colors"
            >
              {t('products')}
            </Link>
            
            {isAuthenticated && (
              <>
                <Link 
                  to="/orders" 
                  className="text-gray-700 hover:text-primary-600 transition-colors"
                >
                  {t('orders')}
                </Link>
                <Link 
                  to="/dashboard" 
                  className="text-gray-700 hover:text-primary-600 transition-colors"
                >
                  {t('dashboard')}
                </Link>
              </>
            )}
          </div>

          {/* Right side items */}
          <div className="flex items-center space-x-4">
            {/* Language Toggle */}
            <button
              onClick={toggleLanguage}
              className="flex items-center space-x-1 text-gray-700 hover:text-primary-600 transition-colors"
              title="Change Language"
            >
              <Globe className="w-5 h-5" />
              <span className="text-sm font-medium">
                {language === 'en' ? 'தமிழ்' : 'EN'}
              </span>
            </button>

            {isAuthenticated ? (
              <>
                {/* Cart Icon (for customers) */}
                {!isEntrepreneur && (
                  <Link 
                    to="/cart" 
                    className="text-gray-700 hover:text-primary-600 transition-colors"
                  >
                    <ShoppingCart className="w-6 h-6" />
                  </Link>
                )}

                {/* User Menu */}
                <div className="relative">
                  <button
                    onClick={() => setIsUserMenuOpen(!isUserMenuOpen)}
                    className="flex items-center space-x-2 text-gray-700 hover:text-primary-600 transition-colors"
                  >
                    <User className="w-6 h-6" />
                    <span className="hidden md:block text-sm font-medium">
                      {user?.name}
                    </span>
                  </button>

                  {/* User Dropdown */}
                  {isUserMenuOpen && (
                    <div className="absolute right-0 mt-2 w-48 bg-white rounded-lg shadow-lg border border-gray-200 py-2 z-50">
                      <div className="px-4 py-2 border-b border-gray-200">
                        <p className="text-sm font-medium text-gray-900">{user?.name}</p>
                        <p className="text-xs text-gray-500">{user?.email}</p>
                        <p className="text-xs text-primary-600">
                          {t(user?.role?.toLowerCase())}
                        </p>
                      </div>
                      
                      <Link
                        to="/dashboard"
                        className="flex items-center space-x-2 px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                        onClick={() => setIsUserMenuOpen(false)}
                      >
                        <BarChart3 className="w-4 h-4" />
                        <span>{t('dashboard')}</span>
                      </Link>
                      
                      <Link
                        to="/orders"
                        className="flex items-center space-x-2 px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                        onClick={() => setIsUserMenuOpen(false)}
                      >
                        <Package className="w-4 h-4" />
                        <span>{t('orders')}</span>
                      </Link>
                      
                      <button
                        onClick={handleLogout}
                        className="flex items-center space-x-2 w-full px-4 py-2 text-sm text-red-600 hover:bg-red-50"
                      >
                        <LogOut className="w-4 h-4" />
                        <span>{t('logout')}</span>
                      </button>
                    </div>
                  )}
                </div>
              </>
            ) : (
              <div className="flex items-center space-x-4">
                <Link
                  to="/login"
                  className="text-gray-700 hover:text-primary-600 transition-colors"
                >
                  {t('login')}
                </Link>
                <Link
                  to="/register"
                  className="btn btn-primary"
                >
                  {t('register')}
                </Link>
              </div>
            )}

            {/* Mobile menu button */}
            <button
              onClick={() => setIsMenuOpen(!isMenuOpen)}
              className="md:hidden text-gray-700 hover:text-primary-600"
            >
              {isMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
            </button>
          </div>
        </div>

        {/* Mobile Navigation */}
        {isMenuOpen && (
          <div className="md:hidden border-t border-gray-200 py-4">
            <div className="flex flex-col space-y-4">
              <Link 
                to="/" 
                className="text-gray-700 hover:text-primary-600 transition-colors"
                onClick={() => setIsMenuOpen(false)}
              >
                {t('home')}
              </Link>
              <Link 
                to="/products" 
                className="text-gray-700 hover:text-primary-600 transition-colors"
                onClick={() => setIsMenuOpen(false)}
              >
                {t('products')}
              </Link>
              
              {isAuthenticated ? (
                <>
                  <Link 
                    to="/orders" 
                    className="text-gray-700 hover:text-primary-600 transition-colors"
                    onClick={() => setIsMenuOpen(false)}
                  >
                    {t('orders')}
                  </Link>
                  <Link 
                    to="/dashboard" 
                    className="text-gray-700 hover:text-primary-600 transition-colors"
                    onClick={() => setIsMenuOpen(false)}
                  >
                    {t('dashboard')}
                  </Link>
                  {!isEntrepreneur && (
                    <Link 
                      to="/cart" 
                      className="text-gray-700 hover:text-primary-600 transition-colors"
                      onClick={() => setIsMenuOpen(false)}
                    >
                      Cart
                    </Link>
                  )}
                </>
              ) : (
                <>
                  <Link
                    to="/login"
                    className="text-gray-700 hover:text-primary-600 transition-colors"
                    onClick={() => setIsMenuOpen(false)}
                  >
                    {t('login')}
                  </Link>
                  <Link
                    to="/register"
                    className="btn btn-primary w-fit"
                    onClick={() => setIsMenuOpen(false)}
                  >
                    {t('register')}
                  </Link>
                </>
              )}
            </div>
          </div>
        )}
      </div>
    </nav>
  );
};

export default Navbar;
