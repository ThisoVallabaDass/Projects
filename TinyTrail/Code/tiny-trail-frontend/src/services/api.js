import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080/api';

// Create axios instance
const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor to add auth token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor to handle auth errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

// Auth API
export const authAPI = {
  login: (credentials) => api.post('/auth/signin', credentials),
  register: (userData) => api.post('/auth/signup', userData),
  getCurrentUser: () => api.get('/auth/me'),
};

// Products API
export const productsAPI = {
  search: (params) => api.get('/products/public/search', { params }),
  getById: (id) => api.get(`/products/public/${id}`),
  getCategories: (pincode) => api.get('/products/public/categories', { params: { pincode } }),
  create: (productData) => api.post('/products', productData),
  update: (id, productData) => api.put(`/products/${id}`, productData),
  delete: (id) => api.delete(`/products/${id}`),
  getMyProducts: () => api.get('/products/my-products'),
  toggleAvailability: (id) => api.put(`/products/${id}/toggle-availability`),
};

// Orders API
export const ordersAPI = {
  create: (orderData) => api.post('/orders', orderData),
  getMyOrders: (params) => api.get('/orders/my-orders', { params }),
  getEntrepreneurOrders: (params) => api.get('/orders/entrepreneur-orders', { params }),
  getById: (id) => api.get(`/orders/${id}`),
  updateStatus: (id, status) => api.put(`/orders/${id}/status`, { status }),
  cancel: (id) => api.put(`/orders/${id}/cancel`),
  getStats: () => api.get('/orders/stats'),
};

// Payments API
export const paymentsAPI = {
  createOrder: (orderData) => api.post('/payments/create-order', orderData),
  verify: (paymentData) => api.post('/payments/verify', paymentData),
  handleFailure: (failureData) => api.post('/payments/failure', failureData),
  getByOrderId: (orderId) => api.get(`/payments/order/${orderId}`),
};

export default api;
