import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Product } from './productsSlice';

export interface CartItem {
  product: Product;
  quantity: number;
}

interface CartState {
  items: CartItem[];
  totalAmount: number;
  totalItems: number;
}

const initialState: CartState = {
  items: [],
  totalAmount: 0,
  totalItems: 0,
};

const cartSlice = createSlice({
  name: 'cart',
  initialState,
  reducers: {
    addToCart: (state, action: PayloadAction<Product>) => {
      const product = action.payload;
      const existingItem = state.items.find(item => item.product.id === product.id);
      
      if (existingItem) {
        existingItem.quantity += 1;
      } else {
        state.items.push({ product, quantity: 1 });
      }
      
      // Update totals
      state.totalItems = state.items.reduce((sum, item) => sum + item.quantity, 0);
      state.totalAmount = state.items.reduce((sum, item) => sum + (item.product.price * item.quantity), 0);
      
      // Persist to AsyncStorage
      AsyncStorage.setItem('cart', JSON.stringify(state.items));
    },
    
    removeFromCart: (state, action: PayloadAction<number>) => {
      const productId = action.payload;
      state.items = state.items.filter(item => item.product.id !== productId);
      
      // Update totals
      state.totalItems = state.items.reduce((sum, item) => sum + item.quantity, 0);
      state.totalAmount = state.items.reduce((sum, item) => sum + (item.product.price * item.quantity), 0);
      
      // Persist to AsyncStorage
      AsyncStorage.setItem('cart', JSON.stringify(state.items));
    },
    
    updateQuantity: (state, action: PayloadAction<{ productId: number; quantity: number }>) => {
      const { productId, quantity } = action.payload;
      const item = state.items.find(item => item.product.id === productId);
      
      if (item) {
        if (quantity <= 0) {
          state.items = state.items.filter(item => item.product.id !== productId);
        } else {
          item.quantity = quantity;
        }
        
        // Update totals
        state.totalItems = state.items.reduce((sum, item) => sum + item.quantity, 0);
        state.totalAmount = state.items.reduce((sum, item) => sum + (item.product.price * item.quantity), 0);
        
        // Persist to AsyncStorage
        AsyncStorage.setItem('cart', JSON.stringify(state.items));
      }
    },
    
    clearCart: (state) => {
      state.items = [];
      state.totalAmount = 0;
      state.totalItems = 0;
      AsyncStorage.removeItem('cart');
    },
    
    loadCartFromStorage: (state, action: PayloadAction<CartItem[]>) => {
      state.items = action.payload;
      state.totalItems = state.items.reduce((sum, item) => sum + item.quantity, 0);
      state.totalAmount = state.items.reduce((sum, item) => sum + (item.product.price * item.quantity), 0);
    },
  },
});

export const { addToCart, removeFromCart, updateQuantity, clearCart, loadCartFromStorage } = cartSlice.actions;
export default cartSlice.reducer;
