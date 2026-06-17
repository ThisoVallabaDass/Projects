import React from 'react';
import { useLanguage } from '../contexts/LanguageContext';
import { CreditCard, MapPin, User } from 'lucide-react';

const Checkout = () => {
  const { t } = useLanguage();

  const formatPrice = (price) => {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR',
    }).format(price);
  };

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      <h1 className="text-3xl font-bold text-gray-900">
        Checkout
      </h1>

      <div className="grid lg:grid-cols-3 gap-8">
        {/* Checkout Form */}
        <div className="lg:col-span-2 space-y-6">
          {/* Delivery Address */}
          <div className="card">
            <div className="card-header">
              <h2 className="text-lg font-semibold text-gray-900 flex items-center space-x-2">
                <MapPin className="w-5 h-5" />
                <span>Delivery Address</span>
              </h2>
            </div>
            <div className="card-body space-y-4">
              <div className="grid md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Full Name
                  </label>
                  <input type="text" className="input" placeholder="Enter your full name" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Phone Number
                  </label>
                  <input type="tel" className="input" placeholder="Enter your phone number" />
                </div>
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Address
                </label>
                <textarea 
                  className="input h-24 resize-none" 
                  placeholder="Enter your complete address"
                ></textarea>
              </div>
              
              <div className="grid md:grid-cols-3 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    City
                  </label>
                  <input type="text" className="input" placeholder="City" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    State
                  </label>
                  <input type="text" className="input" placeholder="State" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Pincode
                  </label>
                  <input type="text" className="input" placeholder="Pincode" />
                </div>
              </div>
            </div>
          </div>

          {/* Payment Method */}
          <div className="card">
            <div className="card-header">
              <h2 className="text-lg font-semibold text-gray-900 flex items-center space-x-2">
                <CreditCard className="w-5 h-5" />
                <span>Payment Method</span>
              </h2>
            </div>
            <div className="card-body space-y-4">
              <div className="space-y-3">
                <label className="flex items-center p-4 border border-gray-300 rounded-lg cursor-pointer hover:bg-gray-50">
                  <input type="radio" name="payment" value="upi" className="mr-3" defaultChecked />
                  <div>
                    <div className="font-medium text-gray-900">UPI Payment</div>
                    <div className="text-sm text-gray-600">Pay using UPI apps like GPay, PhonePe, Paytm</div>
                  </div>
                </label>
                
                <label className="flex items-center p-4 border border-gray-300 rounded-lg cursor-pointer hover:bg-gray-50">
                  <input type="radio" name="payment" value="card" className="mr-3" />
                  <div>
                    <div className="font-medium text-gray-900">Credit/Debit Card</div>
                    <div className="text-sm text-gray-600">Pay using your credit or debit card</div>
                  </div>
                </label>
                
                <label className="flex items-center p-4 border border-gray-300 rounded-lg cursor-pointer hover:bg-gray-50">
                  <input type="radio" name="payment" value="netbanking" className="mr-3" />
                  <div>
                    <div className="font-medium text-gray-900">Net Banking</div>
                    <div className="text-sm text-gray-600">Pay using your bank account</div>
                  </div>
                </label>
              </div>
            </div>
          </div>
        </div>

        {/* Order Summary */}
        <div className="lg:col-span-1">
          <div className="card sticky top-4">
            <div className="card-header">
              <h2 className="text-lg font-semibold text-gray-900">
                Order Summary
              </h2>
            </div>
            <div className="card-body space-y-4">
              {/* Order Items */}
              <div className="space-y-3">
                <div className="flex justify-between items-start">
                  <div className="flex-1">
                    <h4 className="font-medium text-gray-900">Handmade Organic Soap Set</h4>
                    <p className="text-sm text-gray-600">Qty: 2</p>
                  </div>
                  <span className="font-medium">{formatPrice(900)}</span>
                </div>
                
                <div className="flex justify-between items-start">
                  <div className="flex-1">
                    <h4 className="font-medium text-gray-900">Organic Honey</h4>
                    <p className="text-sm text-gray-600">Qty: 1</p>
                  </div>
                  <span className="font-medium">{formatPrice(300)}</span>
                </div>
              </div>
              
              <div className="border-t pt-4 space-y-2">
                <div className="flex justify-between">
                  <span className="text-gray-600">Subtotal</span>
                  <span className="font-medium">{formatPrice(1200)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Shipping</span>
                  <span className="font-medium">{formatPrice(50)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Tax</span>
                  <span className="font-medium">{formatPrice(62.5)}</span>
                </div>
              </div>
              
              <div className="border-t pt-4">
                <div className="flex justify-between">
                  <span className="text-lg font-semibold text-gray-900">Total</span>
                  <span className="text-lg font-bold text-primary-600">
                    {formatPrice(1312.5)}
                  </span>
                </div>
              </div>
              
              <button className="w-full btn btn-primary">
                Place Order
              </button>
              
              <p className="text-xs text-gray-500 text-center">
                By placing your order, you agree to our Terms of Service and Privacy Policy.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Checkout;
