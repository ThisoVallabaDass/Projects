import { configureStore } from '@reduxjs/toolkit';
import authSlice from './authSlice';
import productsSlice from './productsSlice';
import cartSlice from './cartSlice';
import pincodeSlice from './pincodeSlice';

export const store = configureStore({
  reducer: {
    auth: authSlice,
    products: productsSlice,
    cart: cartSlice,
    pincode: pincodeSlice,
  },
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
