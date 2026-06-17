import cartSlice, { addToCart, removeFromCart, updateQuantity, clearCart } from '../cartSlice';

describe('cartSlice', () => {
  const initialState = {
    items: [],
    totalAmount: 0,
    totalItems: 0,
  };

  const mockProduct = {
    id: 1,
    name: 'Test Product',
    price: 100,
    sellerId: 1,
    sellerName: 'Test Seller',
    pincode: '123456',
    description: 'Test description',
    createdAt: '2024-01-01',
  };

  it('should handle initial state', () => {
    expect(cartSlice(undefined, { type: 'unknown' })).toEqual(initialState);
  });

  it('should add product to cart', () => {
    const action = { type: addToCart.type, payload: mockProduct };
    const state = cartSlice(initialState, action);
    
    expect(state.items).toHaveLength(1);
    expect(state.items[0].product).toEqual(mockProduct);
    expect(state.items[0].quantity).toBe(1);
    expect(state.totalAmount).toBe(100);
    expect(state.totalItems).toBe(1);
  });

  it('should increase quantity when adding same product', () => {
    const stateWithProduct = {
      ...initialState,
      items: [{ product: mockProduct, quantity: 1 }],
      totalAmount: 100,
      totalItems: 1,
    };
    
    const action = { type: addToCart.type, payload: mockProduct };
    const state = cartSlice(stateWithProduct, action);
    
    expect(state.items).toHaveLength(1);
    expect(state.items[0].quantity).toBe(2);
    expect(state.totalAmount).toBe(200);
    expect(state.totalItems).toBe(2);
  });

  it('should remove product from cart', () => {
    const stateWithProduct = {
      ...initialState,
      items: [{ product: mockProduct, quantity: 1 }],
      totalAmount: 100,
      totalItems: 1,
    };
    
    const action = { type: removeFromCart.type, payload: mockProduct.id };
    const state = cartSlice(stateWithProduct, action);
    
    expect(state.items).toHaveLength(0);
    expect(state.totalAmount).toBe(0);
    expect(state.totalItems).toBe(0);
  });

  it('should update product quantity', () => {
    const stateWithProduct = {
      ...initialState,
      items: [{ product: mockProduct, quantity: 1 }],
      totalAmount: 100,
      totalItems: 1,
    };
    
    const action = { 
      type: updateQuantity.type, 
      payload: { productId: mockProduct.id, quantity: 3 } 
    };
    const state = cartSlice(stateWithProduct, action);
    
    expect(state.items[0].quantity).toBe(3);
    expect(state.totalAmount).toBe(300);
    expect(state.totalItems).toBe(3);
  });

  it('should clear cart', () => {
    const stateWithItems = {
      ...initialState,
      items: [{ product: mockProduct, quantity: 2 }],
      totalAmount: 200,
      totalItems: 2,
    };
    
    const action = { type: clearCart.type };
    const state = cartSlice(stateWithItems, action);
    
    expect(state.items).toHaveLength(0);
    expect(state.totalAmount).toBe(0);
    expect(state.totalItems).toBe(0);
  });
});
