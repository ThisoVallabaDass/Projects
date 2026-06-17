import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { FiShoppingCart, FiLogOut, FiLogIn, FiHome, FiPackage } from 'react-icons/fi';

function Navigation({ user, onLogout }) {
  const location = useLocation();

  const isActive = (path) => location.pathname === path ? 'text-green-600 border-b-2 border-green-600' : 'text-gray-600 hover:text-gray-800';

  return (
    <nav className="bg-white shadow-sm">
      <div className="max-w-7xl mx-auto px-4 py-4 flex justify-between items-center">
        <Link to="/" className="flex items-center gap-2 text-2xl font-bold text-green-600">
          <FiHome /> TinyTrail
        </Link>

        <div className="flex items-center gap-6">
          {user ? (
            <>
              <Link to="/products" className={`${isActive('/products')} pb-1`}>Products</Link>
              <Link to="/cart" className={`${isActive('/cart')} flex items-center gap-1 pb-1`}>
                <FiShoppingCart /> Cart
              </Link>
              <Link to="/orders" className={`${isActive('/orders')} pb-1`}>Orders</Link>
              {user.role === 'SELLER' && (
                <Link to="/seller/onboard" className={`${isActive('/seller/onboard')} pb-1`}>Seller</Link>
              )}
              <span className="text-sm text-gray-600">Hi, {user.username}</span>
              <button
                onClick={onLogout}
                className="flex items-center gap-1 bg-red-500 text-white px-3 py-2 rounded hover:bg-red-600"
              >
                <FiLogOut /> Logout
              </button>
            </>
          ) : (
            <>
              <Link to="/login" className={`${isActive('/login')} flex items-center gap-1 pb-1`}>
                <FiLogIn /> Login
              </Link>
              <Link
                to="/register"
                className={`${isActive('/register')} bg-green-600 text-white px-4 py-2 rounded hover:bg-green-700`}
              >
                Register
              </Link>
            </>
          )}
        </div>
      </div>
    </nav>
  );
}

export default Navigation;
