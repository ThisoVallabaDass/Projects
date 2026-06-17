import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { FiMail, FiLock } from 'react-icons/fi';

function Login({ onLogin, loading }) {
  const navigate = useNavigate();
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');

    const success = await onLogin(username, password);
    if (success) {
      navigate('/products');
    } else {
      setError('Invalid username or password');
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-green-50 to-blue-50 flex items-center justify-center">
      <div className="bg-white p-8 rounded-lg shadow-lg max-w-md w-full">
        <h1 className="text-3xl font-bold text-center text-green-600 mb-2">TinyTrail</h1>
        <p className="text-center text-gray-600 mb-8">Local Marketplace</p>

        {error && (
          <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit}>
          <div className="mb-4">
            <label className="block text-gray-700 font-semibold mb-2">Username</label>
            <div className="flex items-center bg-gray-100 rounded px-3 py-2">
              <FiMail className="text-gray-500" />
              <input
                type="text"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                placeholder="Enter username"
                className="bg-transparent ml-2 outline-none w-full"
                required
              />
            </div>
          </div>

          <div className="mb-6">
            <label className="block text-gray-700 font-semibold mb-2">Password</label>
            <div className="flex items-center bg-gray-100 rounded px-3 py-2">
              <FiLock className="text-gray-500" />
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Enter password"
                className="bg-transparent ml-2 outline-none w-full"
                required
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-green-600 text-white font-bold py-2 rounded hover:bg-green-700 disabled:bg-gray-400"
          >
            {loading ? 'Logging in...' : 'Login'}
          </button>
        </form>

        <p className="text-center mt-6 text-gray-600">
          Don't have an account?{' '}
          <Link to="/register" className="text-green-600 font-semibold hover:underline">
            Register
          </Link>
        </p>

        <div className="mt-8 p-4 bg-gray-100 rounded">
          <p className="font-semibold text-gray-700 mb-2">Demo Credentials:</p>
          <p className="text-sm text-gray-600">admin / password123</p>
          <p className="text-sm text-gray-600">john_buyer / password123</p>
          <p className="text-sm text-gray-600">jane_seller / password123</p>
        </div>
      </div>
    </div>
  );
}

export default Login;
