import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { useAuth } from '../../contexts/AuthContext';
import { useLanguage } from '../../contexts/LanguageContext';
import { Eye, EyeOff, Mail, Lock, User, MapPin, Phone } from 'lucide-react';

const Register = () => {
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const { register: registerUser, isAuthenticated } = useAuth();
  const { t } = useLanguage();
  const navigate = useNavigate();

  const {
    register,
    handleSubmit,
    formState: { errors },
    watch,
  } = useForm({
    defaultValues: {
      role: 'CUSTOMER',
    },
  });

  // Redirect if already authenticated
  React.useEffect(() => {
    if (isAuthenticated) {
      navigate('/dashboard', { replace: true });
    }
  }, [isAuthenticated, navigate]);

  const onSubmit = async (data) => {
    setLoading(true);
    const result = await registerUser(data);
    setLoading(false);

    if (result.success) {
      navigate('/login');
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8">
        <div className="text-center">
          <div className="mx-auto w-16 h-16 bg-primary-600 rounded-full flex items-center justify-center mb-4">
            <span className="text-white font-bold text-xl">TT</span>
          </div>
          <h2 className="text-3xl font-bold text-gray-900">
            Create Account
          </h2>
          <p className="mt-2 text-sm text-gray-600">
            Join Tiny Trail marketplace
          </p>
        </div>

        <div className="card">
          <div className="card-body">
            <form className="space-y-6" onSubmit={handleSubmit(onSubmit)}>
              <div>
                <label htmlFor="name" className="block text-sm font-medium text-gray-700 mb-2">
                  {t('name')}
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <User className="h-5 w-5 text-gray-400" />
                  </div>
                  <input
                    id="name"
                    type="text"
                    autoComplete="name"
                    className={`input pl-10 ${errors.name ? 'border-red-500' : ''}`}
                    placeholder="Enter your full name"
                    {...register('name', {
                      required: 'Name is required',
                      minLength: {
                        value: 2,
                        message: 'Name must be at least 2 characters',
                      },
                    })}
                  />
                </div>
                {errors.name && (
                  <p className="mt-1 text-sm text-red-600">{errors.name.message}</p>
                )}
              </div>

              <div>
                <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-2">
                  {t('email')}
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <Mail className="h-5 w-5 text-gray-400" />
                  </div>
                  <input
                    id="email"
                    type="email"
                    autoComplete="email"
                    className={`input pl-10 ${errors.email ? 'border-red-500' : ''}`}
                    placeholder="Enter your email"
                    {...register('email', {
                      required: 'Email is required',
                      pattern: {
                        value: /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i,
                        message: 'Invalid email address',
                      },
                    })}
                  />
                </div>
                {errors.email && (
                  <p className="mt-1 text-sm text-red-600">{errors.email.message}</p>
                )}
              </div>

              <div>
                <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-2">
                  {t('password')}
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <Lock className="h-5 w-5 text-gray-400" />
                  </div>
                  <input
                    id="password"
                    type={showPassword ? 'text' : 'password'}
                    autoComplete="new-password"
                    className={`input pl-10 pr-10 ${errors.password ? 'border-red-500' : ''}`}
                    placeholder="Create a password"
                    {...register('password', {
                      required: 'Password is required',
                      minLength: {
                        value: 6,
                        message: 'Password must be at least 6 characters',
                      },
                    })}
                  />
                  <button
                    type="button"
                    className="absolute inset-y-0 right-0 pr-3 flex items-center"
                    onClick={() => setShowPassword(!showPassword)}
                  >
                    {showPassword ? (
                      <EyeOff className="h-5 w-5 text-gray-400" />
                    ) : (
                      <Eye className="h-5 w-5 text-gray-400" />
                    )}
                  </button>
                </div>
                {errors.password && (
                  <p className="mt-1 text-sm text-red-600">{errors.password.message}</p>
                )}
              </div>

              <div>
                <label htmlFor="pincode" className="block text-sm font-medium text-gray-700 mb-2">
                  {t('pincode')}
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <MapPin className="h-5 w-5 text-gray-400" />
                  </div>
                  <input
                    id="pincode"
                    type="text"
                    className={`input pl-10 ${errors.pincode ? 'border-red-500' : ''}`}
                    placeholder="Enter your pincode"
                    {...register('pincode', {
                      required: 'Pincode is required',
                      pattern: {
                        value: /^[0-9]{6}$/,
                        message: 'Pincode must be 6 digits',
                      },
                    })}
                  />
                </div>
                {errors.pincode && (
                  <p className="mt-1 text-sm text-red-600">{errors.pincode.message}</p>
                )}
              </div>

              <div>
                <label htmlFor="phoneNumber" className="block text-sm font-medium text-gray-700 mb-2">
                  {t('phoneNumber')} (Optional)
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <Phone className="h-5 w-5 text-gray-400" />
                  </div>
                  <input
                    id="phoneNumber"
                    type="tel"
                    className={`input pl-10 ${errors.phoneNumber ? 'border-red-500' : ''}`}
                    placeholder="Enter your phone number"
                    {...register('phoneNumber', {
                      pattern: {
                        value: /^[0-9]{10}$/,
                        message: 'Phone number must be 10 digits',
                      },
                    })}
                  />
                </div>
                {errors.phoneNumber && (
                  <p className="mt-1 text-sm text-red-600">{errors.phoneNumber.message}</p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  {t('role')}
                </label>
                <div className="grid grid-cols-2 gap-4">
                  <label className="flex items-center p-3 border border-gray-300 rounded-lg cursor-pointer hover:bg-gray-50">
                    <input
                      type="radio"
                      value="CUSTOMER"
                      className="sr-only"
                      {...register('role', { required: 'Please select a role' })}
                    />
                    <div className={`w-4 h-4 rounded-full border-2 mr-3 ${
                      watch('role') === 'CUSTOMER' 
                        ? 'border-primary-600 bg-primary-600' 
                        : 'border-gray-300'
                    }`}>
                      {watch('role') === 'CUSTOMER' && (
                        <div className="w-2 h-2 bg-white rounded-full mx-auto mt-0.5"></div>
                      )}
                    </div>
                    <div>
                      <div className="text-sm font-medium text-gray-900">
                        {t('customer')}
                      </div>
                      <div className="text-xs text-gray-500">
                        Buy products from local entrepreneurs
                      </div>
                    </div>
                  </label>

                  <label className="flex items-center p-3 border border-gray-300 rounded-lg cursor-pointer hover:bg-gray-50">
                    <input
                      type="radio"
                      value="ENTREPRENEUR"
                      className="sr-only"
                      {...register('role', { required: 'Please select a role' })}
                    />
                    <div className={`w-4 h-4 rounded-full border-2 mr-3 ${
                      watch('role') === 'ENTREPRENEUR' 
                        ? 'border-primary-600 bg-primary-600' 
                        : 'border-gray-300'
                    }`}>
                      {watch('role') === 'ENTREPRENEUR' && (
                        <div className="w-2 h-2 bg-white rounded-full mx-auto mt-0.5"></div>
                      )}
                    </div>
                    <div>
                      <div className="text-sm font-medium text-gray-900">
                        {t('entrepreneur')}
                      </div>
                      <div className="text-xs text-gray-500">
                        Sell your products to local customers
                      </div>
                    </div>
                  </label>
                </div>
                {errors.role && (
                  <p className="mt-1 text-sm text-red-600">{errors.role.message}</p>
                )}
              </div>

              <button
                type="submit"
                disabled={loading}
                className="w-full btn btn-primary flex items-center justify-center"
              >
                {loading ? (
                  <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white"></div>
                ) : (
                  t('register')
                )}
              </button>
            </form>

            <div className="mt-6 text-center">
              <p className="text-sm text-gray-600">
                Already have an account?{' '}
                <Link
                  to="/login"
                  className="font-medium text-primary-600 hover:text-primary-500"
                >
                  {t('login')}
                </Link>
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Register;
