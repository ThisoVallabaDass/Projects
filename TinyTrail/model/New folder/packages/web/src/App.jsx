import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, useNavigate } from 'react-router-dom';
import axios from 'axios';
import './App.css';
import Navigation from './components/Navigation';
import Login from './pages/Login';
import Register from './pages/Register';
import Products from './pages/Products';
import ProductDetail from './pages/ProductDetail';
import Cart from './pages/Cart';
import Orders from './pages/Orders';
import SellerOnboard from './pages/SellerOnboard';

const API_URL = 'http://localhost:8080/api';

function App() {
  const [user, setUser] = useState(null);
  const [token, setToken] = useState(null);
  const [loading, setLoading] = useState(false);

  // Load user from localStorage on mount
  useEffect(() => {
    const savedToken = localStorage.getItem('token');
    const savedUser = localStorage.getItem('user');
    
    if (savedToken) {
      setToken(savedToken);
      if (savedUser) {
        setUser(JSON.parse(savedUser));
      }
      // Verify token is still valid
      verifyToken(savedToken);
    }
  }, []);

  const verifyToken = async (authToken) => {
    try {
      const response = await axios.get(`${API_URL}/auth/me`, {
        headers: { Authorization: `Bearer ${authToken}` }
      });
      setUser(response.data);
    } catch (error) {
      // Token expired or invalid
      logout();
    }
  };

  const login = async (username, password) => {
    setLoading(true);
    try {
      const response = await axios.post(`${API_URL}/auth/login`, { username, password });
      const { token, user } = response.data;
      
      setToken(token);
      setUser(user);
      localStorage.setItem('token', token);
      localStorage.setItem('user', JSON.stringify(user));
      
      return true;
    } catch (error) {
      console.error('Login failed:', error.response?.data?.error);
      return false;
    } finally {
      setLoading(false);
    }
  };

  const register = async (username, password, email, phone) => {
    setLoading(true);
    try {
      const response = await axios.post(`${API_URL}/auth/register`, {
        username,
        password,
        email,
        phone
      });
      const { token, user } = response.data;
      
      setToken(token);
      setUser(user);
      localStorage.setItem('token', token);
      localStorage.setItem('user', JSON.stringify(user));
      
      return true;
    } catch (error) {
      console.error('Registration failed:', error.response?.data?.error);
      return false;
    } finally {
      setLoading(false);
    }
  };

  const logout = () => {
    setUser(null);
    setToken(null);
    localStorage.removeItem('token');
    localStorage.removeItem('user');
  };

  return (
    <Router>
      <div className="App bg-gray-50 min-h-screen">
        <Navigation user={user} onLogout={logout} />
        
        <Routes>
          <Route path="/" element={user ? <Products token={token} /> : <Login onLogin={login} loading={loading} />} />
          <Route path="/register" element={<Register onRegister={register} loading={loading} />} />
          <Route path="/login" element={<Login onLogin={login} loading={loading} />} />
          <Route path="/products" element={user ? <Products token={token} /> : <Login onLogin={login} loading={loading} />} />
          <Route path="/products/:id" element={user ? <ProductDetail token={token} /> : <Login onLogin={login} loading={loading} />} />
          <Route path="/cart" element={user ? <Cart token={token} /> : <Login onLogin={login} loading={loading} />} />
          <Route path="/orders" element={user ? <Orders token={token} /> : <Login onLogin={login} loading={loading} />} />
          <Route path="/seller/onboard" element={user ? <SellerOnboard token={token} /> : <Login onLogin={login} loading={loading} />} />
        </Routes>
      </div>
    </Router>
  );
}

export default App;
