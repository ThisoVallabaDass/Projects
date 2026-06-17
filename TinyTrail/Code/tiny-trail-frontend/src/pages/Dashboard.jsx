import React from 'react';
import { useAuth } from '../contexts/AuthContext';
import { useLanguage } from '../contexts/LanguageContext';
import { Package, ShoppingCart, BarChart3, Users } from 'lucide-react';

const Dashboard = () => {
  const { user, isEntrepreneur } = useAuth();
  const { t } = useLanguage();

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">
            {t('dashboard')}
          </h1>
          <p className="text-gray-600">
            Welcome back, {user?.name}!
          </p>
        </div>
      </div>

      {isEntrepreneur ? (
        <EntrepreneurDashboard />
      ) : (
        <CustomerDashboard />
      )}
    </div>
  );
};

const EntrepreneurDashboard = () => {
  const { t } = useLanguage();

  const stats = [
    { label: 'Total Products', value: '12', icon: Package, color: 'bg-blue-500' },
    { label: 'Total Orders', value: '45', icon: ShoppingCart, color: 'bg-green-500' },
    { label: 'Revenue', value: '₹25,000', icon: BarChart3, color: 'bg-purple-500' },
    { label: 'Customers', value: '32', icon: Users, color: 'bg-orange-500' },
  ];

  return (
    <div className="space-y-6">
      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat, index) => (
          <div key={index} className="card">
            <div className="card-body">
              <div className="flex items-center">
                <div className={`p-3 rounded-lg ${stat.color}`}>
                  <stat.icon className="w-6 h-6 text-white" />
                </div>
                <div className="ml-4">
                  <p className="text-sm font-medium text-gray-600">{stat.label}</p>
                  <p className="text-2xl font-bold text-gray-900">{stat.value}</p>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Quick Actions */}
      <div className="card">
        <div className="card-header">
          <h2 className="text-lg font-semibold text-gray-900">Quick Actions</h2>
        </div>
        <div className="card-body">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <button className="btn btn-primary">Add New Product</button>
            <button className="btn btn-outline">View Orders</button>
            <button className="btn btn-outline">Manage Products</button>
          </div>
        </div>
      </div>

      {/* Recent Activity */}
      <div className="card">
        <div className="card-header">
          <h2 className="text-lg font-semibold text-gray-900">Recent Activity</h2>
        </div>
        <div className="card-body">
          <div className="space-y-4">
            <div className="flex items-center space-x-3">
              <div className="w-2 h-2 bg-green-500 rounded-full"></div>
              <span className="text-gray-700">New order received for "Handmade Soap"</span>
              <span className="text-sm text-gray-500">2 hours ago</span>
            </div>
            <div className="flex items-center space-x-3">
              <div className="w-2 h-2 bg-blue-500 rounded-full"></div>
              <span className="text-gray-700">Product "Organic Honey" was viewed 15 times</span>
              <span className="text-sm text-gray-500">4 hours ago</span>
            </div>
            <div className="flex items-center space-x-3">
              <div className="w-2 h-2 bg-orange-500 rounded-full"></div>
              <span className="text-gray-700">Order #1234 was delivered successfully</span>
              <span className="text-sm text-gray-500">1 day ago</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

const CustomerDashboard = () => {
  const { t } = useLanguage();

  const stats = [
    { label: 'Total Orders', value: '8', icon: ShoppingCart, color: 'bg-blue-500' },
    { label: 'Pending Orders', value: '2', icon: Package, color: 'bg-orange-500' },
    { label: 'Total Spent', value: '₹5,200', icon: BarChart3, color: 'bg-green-500' },
    { label: 'Favorite Products', value: '12', icon: Users, color: 'bg-purple-500' },
  ];

  return (
    <div className="space-y-6">
      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat, index) => (
          <div key={index} className="card">
            <div className="card-body">
              <div className="flex items-center">
                <div className={`p-3 rounded-lg ${stat.color}`}>
                  <stat.icon className="w-6 h-6 text-white" />
                </div>
                <div className="ml-4">
                  <p className="text-sm font-medium text-gray-600">{stat.label}</p>
                  <p className="text-2xl font-bold text-gray-900">{stat.value}</p>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Quick Actions */}
      <div className="card">
        <div className="card-header">
          <h2 className="text-lg font-semibold text-gray-900">Quick Actions</h2>
        </div>
        <div className="card-body">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <button className="btn btn-primary">Browse Products</button>
            <button className="btn btn-outline">View Orders</button>
            <button className="btn btn-outline">Track Deliveries</button>
          </div>
        </div>
      </div>

      {/* Recent Orders */}
      <div className="card">
        <div className="card-header">
          <h2 className="text-lg font-semibold text-gray-900">Recent Orders</h2>
        </div>
        <div className="card-body">
          <div className="space-y-4">
            <div className="flex items-center justify-between p-4 border border-gray-200 rounded-lg">
              <div>
                <h3 className="font-medium text-gray-900">Handmade Soap Set</h3>
                <p className="text-sm text-gray-600">Order #1234 • ₹450</p>
              </div>
              <span className="badge badge-warning">Pending</span>
            </div>
            <div className="flex items-center justify-between p-4 border border-gray-200 rounded-lg">
              <div>
                <h3 className="font-medium text-gray-900">Organic Honey</h3>
                <p className="text-sm text-gray-600">Order #1233 • ₹300</p>
              </div>
              <span className="badge badge-success">Delivered</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
