import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import axios from 'axios';
import { FiShoppingCart, FiStar } from 'react-icons/fi';

const API_URL = 'http://localhost:8080/api';

function Products({ token }) {
  const [products, setProducts] = useState([]);
  const [categories, setCategories] = useState([]);
  const [selectedCategory, setSelectedCategory] = useState('');
  const [pincode, setPincode] = useState('600001');
  const [searchQuery, setSearchQuery] = useState('');
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    fetchCategories();
    fetchProducts();
  }, []);

  const fetchCategories = async () => {
    try {
      const response = await axios.get(`${API_URL}/categories`);
      setCategories(response.data.categories || []);
    } catch (error) {
      console.error('Error fetching categories:', error);
    }
  };

  const fetchProducts = async () => {
    setLoading(true);
    try {
      let url = `${API_URL}/products?pincode=${pincode}`;
      if (selectedCategory) {
        url += `&category=${selectedCategory}`;
      }
      
      const response = await axios.get(url);
      setProducts(response.data.products || []);
    } catch (error) {
      console.error('Error fetching products:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSearch = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      const response = await axios.get(`${API_URL}/products/search`, {
        params: { q: searchQuery, pincode }
      });
      setProducts(response.data.products || []);
    } catch (error) {
      console.error('Error searching:', error);
    } finally {
      setLoading(false);
    }
  };

  const addToCart = async (productId) => {
    try {
      await axios.post(
        `${API_URL}/cart/add`,
        { productId, quantity: 1 },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      alert('Item added to cart!');
    } catch (error) {
      alert('Failed to add to cart');
    }
  };

  return (
    <div className="max-w-7xl mx-auto px-4 py-8">
      <h1 className="text-4xl font-bold mb-8 text-gray-800">Products</h1>

      {/* Search and Filter */}
      <div className="bg-white p-6 rounded-lg shadow-md mb-8">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-4">
          <input
            type="text"
            placeholder="Pincode"
            value={pincode}
            onChange={(e) => setPincode(e.target.value)}
            className="border rounded px-3 py-2"
          />
          
          <select
            value={selectedCategory}
            onChange={(e) => setSelectedCategory(e.target.value)}
            className="border rounded px-3 py-2"
          >
            <option value="">All Categories</option>
            {categories.map((cat) => (
              <option key={cat} value={cat}>
                {cat}
              </option>
            ))}
          </select>

          <button
            onClick={fetchProducts}
            className="bg-green-600 text-white px-4 py-2 rounded hover:bg-green-700"
          >
            Filter
          </button>
        </div>

        <form onSubmit={handleSearch} className="flex gap-2">
          <input
            type="text"
            placeholder="Search products..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="flex-1 border rounded px-3 py-2"
          />
          <button
            type="submit"
            className="bg-blue-600 text-white px-6 py-2 rounded hover:bg-blue-700"
          >
            Search
          </button>
        </form>
      </div>

      {/* Products Grid */}
      {loading ? (
        <div className="text-center py-12">
          <p className="text-gray-600">Loading...</p>
        </div>
      ) : products.length === 0 ? (
        <div className="text-center py-12">
          <p className="text-gray-600">No products found</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-4 gap-6">
          {products.map((product) => (
            <div key={product.id} className="bg-white rounded-lg shadow-md overflow-hidden hover:shadow-lg transition">
              <div className="h-40 bg-gray-200 relative">
                <img
                  src={product.image_url || 'https://via.placeholder.com/300x200?text=' + product.name}
                  alt={product.name}
                  className="w-full h-full object-cover"
                />
              </div>
              
              <div className="p-4">
                <h3 className="font-bold text-gray-800 line-clamp-2">{product.name}</h3>
                <p className="text-sm text-gray-600 mb-2">{product.shop_name}</p>
                <p className="text-sm text-gray-600 mb-3 line-clamp-2">{product.description}</p>
                
                <div className="flex items-center gap-2 mb-3">
                  <FiStar className="text-yellow-500" />
                  <span className="text-sm font-semibold">{product.rating}</span>
                </div>

                <div className="flex justify-between items-center">
                  <span className="text-2xl font-bold text-green-600">₹{product.price}</span>
                  <button
                    onClick={() => addToCart(product.id)}
                    className="flex items-center gap-1 bg-green-600 text-white px-3 py-2 rounded hover:bg-green-700"
                  >
                    <FiShoppingCart /> Add
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

export default Products;
