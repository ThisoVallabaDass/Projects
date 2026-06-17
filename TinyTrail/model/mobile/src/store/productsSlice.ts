import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit';
import client from '../api/client';

export interface Product {
  id: number;
  name: string;
  description: string;
  price: number;
  imageUrl?: string;
  sellerId: number;
  sellerName: string;
  pincode: string;
  category?: string;
  createdAt: string;
}

interface ProductsState {
  products: Product[];
  isLoading: boolean;
  error: string | null;
  searchPincode: string;
  selectedCategory: string | null;
}

const initialState: ProductsState = {
  products: [],
  isLoading: false,
  error: null,
  searchPincode: '',
  selectedCategory: null,
};

const normalizeProduct = (product: any): Product => ({
  id: product.id,
  name: product.name,
  description: product.description ?? '',
  price: Number(product.price ?? 0),
  imageUrl: product.imageUrl ?? product.image_url ?? product.image ?? undefined,
  sellerId: product.sellerId ?? product.vendor_id ?? product.vendorId ?? 0,
  sellerName:
    product.sellerName ??
    product.vendor_name ??
    product.vendorName ??
    product.shop_name ??
    'Local Vendor',
  pincode: product.pincode ?? '',
  category: product.category ?? undefined,
  createdAt: product.createdAt ?? product.created_at ?? new Date().toISOString(),
});

// Async thunks
export const searchProductsByPincode = createAsyncThunk(
  'products/searchByPincode',
  async (pincode: string) => {
    const response = await client.get(`/products/search?pincode=${pincode}`);
    return (response.data || []).map(normalizeProduct);
  }
);

export const getProductById = createAsyncThunk(
  'products/getById',
  async (productId: number) => {
    const response = await client.get(`/products/${productId}`);
    return normalizeProduct(response.data);
  }
);

export const createProduct = createAsyncThunk(
  'products/create',
  async (productData: FormData) => {
    const response = await client.post('/products', productData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
    return normalizeProduct(response.data);
  }
);

const productsSlice = createSlice({
  name: 'products',
  initialState,
  reducers: {
    setSearchPincode: (state, action: PayloadAction<string>) => {
      state.searchPincode = action.payload;
    },
    setSelectedCategory: (state, action: PayloadAction<string | null>) => {
      state.selectedCategory = action.payload;
    },
    clearProducts: (state) => {
      state.products = [];
    },
    clearError: (state) => {
      state.error = null;
    },
  },
  extraReducers: (builder) => {
    builder
      // Search by pincode
      .addCase(searchProductsByPincode.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(searchProductsByPincode.fulfilled, (state, action) => {
        state.isLoading = false;
        state.products = action.payload;
        state.error = null;
      })
      .addCase(searchProductsByPincode.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.error.message || 'Search failed';
      })
      .addCase(getProductById.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(getProductById.fulfilled, (state, action) => {
        state.isLoading = false;
        state.error = null;

        const index = state.products.findIndex((product) => product.id === action.payload.id);
        if (index >= 0) {
          state.products[index] = action.payload;
        } else {
          state.products.push(action.payload);
        }
      })
      .addCase(getProductById.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.error.message || 'Failed to load product';
      })
      // Create product
      .addCase(createProduct.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(createProduct.fulfilled, (state, action) => {
        state.isLoading = false;
        state.products.unshift(action.payload);
        state.error = null;
      })
      .addCase(createProduct.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.error.message || 'Product creation failed';
      });
  },
});

export const { setSearchPincode, setSelectedCategory, clearProducts, clearError } = productsSlice.actions;
export default productsSlice.reducer;
