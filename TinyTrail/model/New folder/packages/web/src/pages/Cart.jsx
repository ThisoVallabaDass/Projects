import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import { FiTrash2, FiArrowLeft } from 'react-icons/fi';

const API_URL = 'http://localhost:8080/api';

function Cart({ token }) {
  const navigate = useNavigate();
  const [items, setItems] = useState([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(false);
  const [deliveryAddress, setDeliveryAddress] = useState('');
  const [phone, setPhone] = useState('');
  const [paymentMethod, setPaymentMethod] = useState('COD');
  const [placing, setPlacing] = useState(false);

  useEffect(() => {
    fetchCart();
  }, []);

  const fetchCart = async () => {
    setLoading(true);
    try {
      const response = await axios.get(`${API_URL}/cart`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      setItems(response.data.items || []);
      setTotal(response.data.total || 0);
    } catch (error) {
      console.error('Error fetching cart:', error);
    } finally {
      setLoading(false);
    }
  };

  const removeItem = async (productId) => {
    try {
      await axios.post(
        `${API_URL}/cart/remove`,
        { productId },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      fetchCart();
    } catch (error) {
      alert('Failed to remove item');
    }
  };

  const placeOrder = async (e) => {
    e.preventDefault();
    
    if (!deliveryAddress || !phone) {
      alert('Please fill in all fields');
      return;
    }

    setPlacing(true);
    try {
      const response = await axios.post(
        `${API_URL}/orders`,
        {
          deliveryAddress,
          phone,
          paymentMethod
        },
        { headers: { Authorization: `Bearer ${token}` } }
      );

      alert('Order placed successfully!');
      navigate('/orders');
    } catch (error) {
      alert('Failed to place order: ' + (error.response?.data?.error || error.message));
    } finally {
      setPlacing(false);
    }
  };

  if (loading) {
    return <div className="text-center py-12">Loading...</div>;
  }

  return (
    <div className="max-w-7xl mx-auto px-4 py-8">
      <div className="flex items-center gap-2 mb-8">
        <button onClick={() => navigate('/products')} className="text-green-600 hover:text-green-700">
          <FiArrowLeft size={24} />
        </button>
        <h1 className="text-4xl font-bold text-gray-800">Shopping Cart</h1>
      </div>

      {items.length === 0 ? (
        <div className="bg-white p-8 rounded-lg shadow-md text-center">
          <p className="text-gray-600 mb-4">Your cart is empty</p>
          <button
            onClick={() => navigate('/products')}
            className="bg-green-600 text-white px-6 py-2 rounded hover:bg-green-700"
          >
            Continue Shopping
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Cart Items */}
          <div className="lg:col-span-2">
            <div className="bg-white rounded-lg shadow-md overflow-hidden">
              {items.map((item) => (
                <div key={item.id} className="border-b p-4 flex gap-4">
                  <img
                    src={item.image_url || 'https://via.placeholder.com/100'}
                    alt={item.name}
                    className="w-24 h-24 object-cover rounded"
                  />
                  <div className="flex-1">
                    <h3 className="font-bold text-gray-800">{item.name}</h3>
                    <p className="text-sm text-gray-600 mb-2">{item.description}</p>
                    <div className="flex justify-between items-center">
                      <span className="font-semibold">
                        ₹{item.price} x {item.quantity} = ₹{item.price * item.quantity}
                      </span>
                      <button
                        onClick={() => removeItem(item.id)}
                        className="text-red-600 hover:text-red-700"
                      >
                        <FiTrash2 />
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Order Summary and Checkout */}
          <div className="bg-white rounded-lg shadow-md p-6 h-fit">
            <h2 className="text-2xl font-bold mb-6">Order Summary</h2>

            <div className="mb-4 pb-4 border-b">
              <div className="flex justify-between mb-2">
                <span>Subtotal:</span>
                <span>₹{total}</span>
              </div>
              <div className="flex justify-between mb-2">
                <span>Shipping:</span>
                <span>Free</span>
              </div>
              <div className="flex justify-between text-xl font-bold text-green-600">
                <span>Total:</span>
                <span>₹{total}</span>
              </div>
            </div>

            <form onSubmit={placeOrder} className="space-y-4">
              <div>
                <label className="block text-gray-700 font-semibold mb-2">Delivery Address</label>
                <textarea
                  value={deliveryAddress}
                  onChange={(e) => setDeliveryAddress(e.target.value)}
                  placeholder="Enter delivery address"
                  rows="3"
                  className="w-full border rounded px-3 py-2"
                  required
                />
              </div>

              <div>
                <label className="block text-gray-700 font-semibold mb-2">Phone</label>
                <input
                  type="tel"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  placeholder="Enter phone number"
                  className="w-full border rounded px-3 py-2"
                  required
                />
              </div>

              <div>
                <label className="block text-gray-700 font-semibold mb-2">Payment Method</label>
                <select
                  value={paymentMethod}
                  onChange={(e) => setPaymentMethod(e.target.value)}
                  className="w-full border rounded px-3 py-2"
                >
                  <option value="COD">Cash on Delivery</option>
                  <option value="UPI">UPI</option>
                  <option value="CARD">Credit/Debit Card</option>
                </select>
              </div>

              <button
                type="submit"
                disabled={placing}
                className="w-full bg-green-600 text-white font-bold py-3 rounded hover:bg-green-700 disabled:bg-gray-400"
              >
                {placing ? 'Placing order...' : 'Place Order'}
              </button>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

export default Cart;
