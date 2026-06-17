import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { useLanguage } from '../contexts/LanguageContext';
import { productsAPI } from '../services/api';
import { Search, Filter, MapPin, Star, ShoppingCart, Eye } from 'lucide-react';
import toast from 'react-hot-toast';

const Products = () => {
  const [products, setProducts] = useState([]);
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('');
  const [pincode, setPincode] = useState('');
  const [currentPage, setCurrentPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [sortBy, setSortBy] = useState('createdAt');
  const [sortDir, setSortDir] = useState('desc');
  const { t } = useLanguage();

  useEffect(() => {
    fetchProducts();
    fetchCategories();
  }, [searchQuery, selectedCategory, pincode, currentPage, sortBy, sortDir]);

  const fetchProducts = async () => {
    try {
      setLoading(true);
      const params = {
        page: currentPage,
        size: 12,
        sortBy,
        sortDir,
      };

      if (pincode) params.pincode = pincode;
      if (searchQuery) params.query = searchQuery;
      if (selectedCategory) params.category = selectedCategory;

      const response = await productsAPI.search(params);
      
      if (response.data.success) {
        const pageData = response.data.data;
        setProducts(pageData.content || []);
        setTotalPages(pageData.totalPages || 0);
      }
    } catch (error) {
      console.error('Error fetching products:', error);
      toast.error('Failed to load products');
    } finally {
      setLoading(false);
    }
  };

  const fetchCategories = async () => {
    try {
      const response = await productsAPI.getCategories(pincode);
      if (response.data.success) {
        setCategories(response.data.data || []);
      }
    } catch (error) {
      console.error('Error fetching categories:', error);
    }
  };

  const handleSearch = (e) => {
    e.preventDefault();
    setCurrentPage(0);
    fetchProducts();
  };

  const handlePincodeChange = (e) => {
    setPincode(e.target.value);
    setCurrentPage(0);
  };

  const handleCategoryChange = (category) => {
    setSelectedCategory(category === selectedCategory ? '' : category);
    setCurrentPage(0);
  };

  const handleSortChange = (newSortBy) => {
    if (sortBy === newSortBy) {
      setSortDir(sortDir === 'asc' ? 'desc' : 'asc');
    } else {
      setSortBy(newSortBy);
      setSortDir('desc');
    }
    setCurrentPage(0);
  };

  const formatPrice = (price) => {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR',
    }).format(price);
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="text-center">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">
          {t('marketplace')}
        </h1>
        <p className="text-gray-600">
          Discover amazing products from local entrepreneurs
        </p>
      </div>

      {/* Search and Filters */}
      <div className="card">
        <div className="card-body">
          <form onSubmit={handleSearch} className="space-y-4">
            <div className="grid md:grid-cols-3 gap-4">
              {/* Search */}
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <Search className="h-5 w-5 text-gray-400" />
                </div>
                <input
                  type="text"
                  placeholder="Search products..."
                  className="input pl-10"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                />
              </div>

              {/* Pincode */}
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <MapPin className="h-5 w-5 text-gray-400" />
                </div>
                <input
                  type="text"
                  placeholder="Enter pincode"
                  className="input pl-10"
                  value={pincode}
                  onChange={handlePincodeChange}
                  maxLength={6}
                />
              </div>

              {/* Sort */}
              <select
                className="input"
                value={`${sortBy}-${sortDir}`}
                onChange={(e) => {
                  const [newSortBy, newSortDir] = e.target.value.split('-');
                  setSortBy(newSortBy);
                  setSortDir(newSortDir);
                  setCurrentPage(0);
                }}
              >
                <option value="createdAt-desc">Newest First</option>
                <option value="createdAt-asc">Oldest First</option>
                <option value="price-asc">Price: Low to High</option>
                <option value="price-desc">Price: High to Low</option>
                <option value="name-asc">Name: A to Z</option>
                <option value="name-desc">Name: Z to A</option>
              </select>
            </div>

            <button type="submit" className="btn btn-primary">
              {t('search')}
            </button>
          </form>
        </div>
      </div>

      {/* Categories */}
      {categories.length > 0 && (
        <div className="card">
          <div className="card-body">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Categories</h3>
            <div className="flex flex-wrap gap-2">
              <button
                onClick={() => handleCategoryChange('')}
                className={`px-4 py-2 rounded-full text-sm font-medium transition-colors ${
                  selectedCategory === ''
                    ? 'bg-primary-600 text-white'
                    : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                }`}
              >
                All Categories
              </button>
              {categories.map((category) => (
                <button
                  key={category}
                  onClick={() => handleCategoryChange(category)}
                  className={`px-4 py-2 rounded-full text-sm font-medium transition-colors ${
                    selectedCategory === category
                      ? 'bg-primary-600 text-white'
                      : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                  }`}
                >
                  {category}
                </button>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Products Grid */}
      {loading ? (
        <div className="flex items-center justify-center py-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
        </div>
      ) : products.length > 0 ? (
        <>
          <div className="grid sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {products.map((product) => (
              <div key={product.id} className="card hover:shadow-lg transition-shadow">
                <div className="relative">
                  {product.imageUrl ? (
                    <img
                      src={product.imageUrl}
                      alt={product.name}
                      className="w-full h-48 object-cover rounded-t-lg"
                    />
                  ) : (
                    <div className="w-full h-48 bg-gray-200 rounded-t-lg flex items-center justify-center">
                      <div className="text-gray-400 text-center">
                        <div className="w-12 h-12 mx-auto mb-2 bg-gray-300 rounded-lg flex items-center justify-center">
                          <ShoppingCart className="w-6 h-6" />
                        </div>
                        <span className="text-sm">No Image</span>
                      </div>
                    </div>
                  )}
                  
                  {/* Language Badge */}
                  <div className="absolute top-2 right-2">
                    <span className={`badge ${
                      product.language === 'TAMIL' ? 'badge-info' : 'badge-success'
                    }`}>
                      {product.language === 'TAMIL' ? 'தமிழ்' : 'EN'}
                    </span>
                  </div>
                </div>

                <div className="card-body">
                  <h3 className="font-semibold text-gray-900 mb-2 line-clamp-2">
                    {product.name}
                  </h3>
                  
                  <p className="text-gray-600 text-sm mb-3 line-clamp-2">
                    {product.description}
                  </p>

                  <div className="flex items-center justify-between mb-3">
                    <span className="text-lg font-bold text-primary-600">
                      {formatPrice(product.price)}
                    </span>
                    <span className="badge badge-info">
                      {product.category}
                    </span>
                  </div>

                  <div className="flex items-center justify-between text-sm text-gray-500 mb-4">
                    <div className="flex items-center space-x-1">
                      <MapPin className="w-4 h-4" />
                      <span>{product.pincode}</span>
                    </div>
                    <div className="flex items-center space-x-1">
                      <span>By {product.entrepreneur?.name}</span>
                    </div>
                  </div>

                  <div className="flex space-x-2">
                    <Link
                      to={`/products/${product.id}`}
                      className="flex-1 btn btn-outline flex items-center justify-center space-x-1"
                    >
                      <Eye className="w-4 h-4" />
                      <span>View</span>
                    </Link>
                    <Link
                      to={`/products/${product.id}`}
                      className="flex-1 btn btn-primary flex items-center justify-center space-x-1"
                    >
                      <ShoppingCart className="w-4 h-4" />
                      <span>Buy</span>
                    </Link>
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="flex justify-center space-x-2">
              <button
                onClick={() => setCurrentPage(Math.max(0, currentPage - 1))}
                disabled={currentPage === 0}
                className="btn btn-outline disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Previous
              </button>
              
              <span className="flex items-center px-4 py-2 text-gray-700">
                Page {currentPage + 1} of {totalPages}
              </span>
              
              <button
                onClick={() => setCurrentPage(Math.min(totalPages - 1, currentPage + 1))}
                disabled={currentPage >= totalPages - 1}
                className="btn btn-outline disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Next
              </button>
            </div>
          )}
        </>
      ) : (
        <div className="text-center py-12">
          <div className="w-16 h-16 mx-auto mb-4 bg-gray-200 rounded-lg flex items-center justify-center">
            <ShoppingCart className="w-8 h-8 text-gray-400" />
          </div>
          <h3 className="text-lg font-medium text-gray-900 mb-2">
            {t('noProducts')}
          </h3>
          <p className="text-gray-600">
            Try adjusting your search criteria or check back later.
          </p>
        </div>
      )}
    </div>
  );
};

export default Products;
