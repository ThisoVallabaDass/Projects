import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { FiArrowRight } from 'react-icons/fi';

const API_URL = 'http://localhost:8080/api';

function Orders({ token }) {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(false);
  const [selectedOrder, setSelectedOrder] = useState(null);

  useEffect(() => {
    fetchOrders();
  }, []);

  const fetchOrders = async () => {
    setLoading(true);
    try {
      const response = await axios.get(`${API_URL}/orders`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      setOrders(response.data.orders || []);
    } catch (error) {
      console.error('Error fetching orders:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return <div className="text-center py-12">Loading...</div>;
  }

  return (
    <div className="max-w-7xl mx-auto px-4 py-8">
      <h1 className="text-4xl font-bold mb-8 text-gray-800">Order History</h1>

      {orders.length === 0 ? (
        <div className="bg-white p-8 rounded-lg shadow-md text-center">
          <p className="text-gray-600">No orders yet</p>
        </div>
      ) : (
        <div className="space-y-4">
          {orders.map((order) => (
            <div key={order.id} className="bg-white p-6 rounded-lg shadow-md">
              <div className="flex justify-between items-start">
                <div>
                  <h3 className="font-bold text-lg">Order #{order.id}</h3>
                  <p className="text-gray-600">Shop: {order.shop_name}</p>
                  <p className="text-gray-600">Date: {new Date(order.created_at).toLocaleDateString()}</p>
                </div>
                <div className="text-right">
                  <span className={`px-4 py-2 rounded font-semibold ${
                    order.status === 'CONFIRMED' ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'
                  }`}>
                    {order.status}
                  </span>
                </div>
              </div>
              <div className="mt-4 pt-4 border-t flex justify-between items-center">
                <div>
                  <p className="text-gray-600">Delivery: {order.delivery_address}</p>
                  <p className="font-bold text-lg text-green-600">Total: ₹{order.total}</p>
                </div>
                <button
                  onClick={() => setSelectedOrder(order)}
                  className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700"
                >
                  View Details <FiArrowRight />
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

export default Orders;
