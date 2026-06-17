import React from 'react';
import { useAuth } from '../contexts/AuthContext';
import { useLanguage } from '../contexts/LanguageContext';
import { Package, Clock, CheckCircle, XCircle } from 'lucide-react';

const Orders = () => {
  const { t } = useLanguage();

  // Mock orders data
  const orders = [
    {
      id: 1,
      productName: 'Handmade Soap Set',
      quantity: 2,
      totalAmount: 450,
      status: 'PENDING',
      createdAt: '2023-10-15T10:30:00',
      entrepreneur: 'Priya Crafts',
    },
    {
      id: 2,
      productName: 'Organic Honey',
      quantity: 1,
      totalAmount: 300,
      status: 'DELIVERED',
      createdAt: '2023-10-12T14:20:00',
      entrepreneur: 'Nature\'s Best',
    },
    {
      id: 3,
      productName: 'Cotton Bags',
      quantity: 3,
      totalAmount: 600,
      status: 'SHIPPED',
      createdAt: '2023-10-10T09:15:00',
      entrepreneur: 'Eco Friendly Store',
    },
  ];

  const getStatusIcon = (status) => {
    switch (status) {
      case 'PENDING':
        return <Clock className="w-5 h-5 text-orange-500" />;
      case 'CONFIRMED':
        return <CheckCircle className="w-5 h-5 text-blue-500" />;
      case 'SHIPPED':
        return <Package className="w-5 h-5 text-purple-500" />;
      case 'DELIVERED':
        return <CheckCircle className="w-5 h-5 text-green-500" />;
      case 'CANCELLED':
        return <XCircle className="w-5 h-5 text-red-500" />;
      default:
        return <Clock className="w-5 h-5 text-gray-500" />;
    }
  };

  const getStatusBadge = (status) => {
    const statusClasses = {
      PENDING: 'badge-warning',
      CONFIRMED: 'badge-info',
      SHIPPED: 'badge-info',
      DELIVERED: 'badge-success',
      CANCELLED: 'badge-error',
    };

    return (
      <span className={`badge ${statusClasses[status] || 'badge-info'}`}>
        {t(status.toLowerCase())}
      </span>
    );
  };

  const formatPrice = (price) => {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR',
    }).format(price);
  };

  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleDateString('en-IN', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">
            {t('myOrders')}
          </h1>
          <p className="text-gray-600">
            Track and manage your orders
          </p>
        </div>
      </div>

      {orders.length > 0 ? (
        <div className="space-y-4">
          {orders.map((order) => (
            <div key={order.id} className="card">
              <div className="card-body">
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="flex items-center space-x-3 mb-2">
                      {getStatusIcon(order.status)}
                      <h3 className="text-lg font-semibold text-gray-900">
                        {order.productName}
                      </h3>
                      {getStatusBadge(order.status)}
                    </div>
                    
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm text-gray-600">
                      <div>
                        <span className="font-medium">Order ID:</span> #{order.id}
                      </div>
                      <div>
                        <span className="font-medium">Quantity:</span> {order.quantity}
                      </div>
                      <div>
                        <span className="font-medium">Entrepreneur:</span> {order.entrepreneur}
                      </div>
                      <div>
                        <span className="font-medium">Order Date:</span> {formatDate(order.createdAt)}
                      </div>
                      <div>
                        <span className="font-medium">Total Amount:</span> {formatPrice(order.totalAmount)}
                      </div>
                    </div>
                  </div>
                  
                  <div className="flex flex-col space-y-2 ml-4">
                    <button className="btn btn-outline btn-sm">
                      View Details
                    </button>
                    {order.status === 'PENDING' && (
                      <button className="btn btn-outline btn-sm text-red-600 border-red-300 hover:bg-red-50">
                        Cancel Order
                      </button>
                    )}
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="text-center py-12">
          <div className="w-16 h-16 mx-auto mb-4 bg-gray-200 rounded-lg flex items-center justify-center">
            <Package className="w-8 h-8 text-gray-400" />
          </div>
          <h3 className="text-lg font-medium text-gray-900 mb-2">
            {t('noOrders')}
          </h3>
          <p className="text-gray-600 mb-4">
            You haven't placed any orders yet.
          </p>
          <button className="btn btn-primary">
            Start Shopping
          </button>
        </div>
      )}
    </div>
  );
};

export default Orders;
