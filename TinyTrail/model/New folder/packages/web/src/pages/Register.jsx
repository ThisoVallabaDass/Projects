import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { FiMail, FiLock, FiUser, FiPhone } from 'react-icons/fi';

function Register({ onRegister, loading }) {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    username: '',
    email: '',
    password: '',
    confirmPassword: '',
    phone: ''
  });
  const [error, setError] = useState('');

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');

    if (formData.password !== formData.confirmPassword) {
      setError('Passwords do not match');
      return;
    }

    const success = await onRegister(
      formData.username,
      formData.password,
      formData.email,
      formData.phone
    );

    if (success) {
      navigate('/products');
    } else {
      setError('Registration failed. Please try again.');
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-green-50 to-blue-50 flex items-center justify-center">
      <div className="bg-white p-8 rounded-lg shadow-lg max-w-md w-full">
        <h1 className="text-3xl font-bold text-center text-green-600 mb-2">Register</h1>
        <p className="text-center text-gray-600 mb-8">Join TinyTrail Marketplace</p>

        {error && (
          <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit}>
          <div className="mb-4">
            <label className="block text-gray-700 font-semibold mb-2">Username</label>
            <div className="flex items-center bg-gray-100 rounded px-3 py-2">
              <FiUser className="text-gray-500" />
              <input
                type="text"
                name="username"
                value={formData.username}
                onChange={handleChange}
                placeholder="Choose username"
                className="bg-transparent ml-2 outline-none w-full"
                required
              />
            </div>
          </div>

          <div className="mb-4">
            <label className="block text-gray-700 font-semibold mb-2">Email</label>
            <div className="flex items-center bg-gray-100 rounded px-3 py-2">
              <FiMail className="text-gray-500" />
              <input
                type="email"
                name="email"
                value={formData.email}
                onChange={handleChange}
                placeholder="Enter email"
                className="bg-transparent ml-2 outline-none w-full"
                required
              />
            </div>
          </div>

          <div className="mb-4">
            <label className="block text-gray-700 font-semibold mb-2">Phone</label>
            <div className="flex items-center bg-gray-100 rounded px-3 py-2">
              <FiPhone className="text-gray-500" />
              <input
                type="tel"
                name="phone"
                value={formData.phone}
                onChange={handleChange}
                placeholder="Enter phone"
                className="bg-transparent ml-2 outline-none w-full"
              />
            </div>
          </div>

          <div className="mb-4">
            <label className="block text-gray-700 font-semibold mb-2">Password</label>
            <div className="flex items-center bg-gray-100 rounded px-3 py-2">
              <FiLock className="text-gray-500" />
              <input
                type="password"
                name="password"
                value={formData.password}
                onChange={handleChange}
                placeholder="Enter password"
                className="bg-transparent ml-2 outline-none w-full"
                required
              />
            </div>
          </div>

          <div className="mb-6">
            <label className="block text-gray-700 font-semibold mb-2">Confirm Password</label>
            <div className="flex items-center bg-gray-100 rounded px-3 py-2">
              <FiLock className="text-gray-500" />
              <input
                type="password"
                name="confirmPassword"
                value={formData.confirmPassword}
                onChange={handleChange}
                placeholder="Confirm password"
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
            {loading ? 'Registering...' : 'Register'}
          </button>
        </form>

        <p className="text-center mt-6 text-gray-600">
          Already have an account?{' '}
          <Link to="/login" className="text-green-600 font-semibold hover:underline">
            Login
          </Link>
        </p>
      </div>
    </div>
  );
}

export default Register;
