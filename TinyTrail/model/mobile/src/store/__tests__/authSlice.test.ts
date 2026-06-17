import authSlice, { login, logout } from '../authSlice';

describe('authSlice', () => {
  const initialState = {
    user: null,
    token: null,
    isLoading: false,
    error: null,
  };

  it('should handle initial state', () => {
    expect(authSlice(undefined, { type: 'unknown' })).toEqual(initialState);
  });

  it('should handle login pending', () => {
    const action = { type: login.pending.type };
    const state = authSlice(initialState, action);
    expect(state.isLoading).toBe(true);
    expect(state.error).toBe(null);
  });

  it('should handle login fulfilled', () => {
    const mockUser = { id: 1, username: 'test', email: 'test@test.com', role: 'BUYER' };
    const mockToken = 'mock-token';
    const action = {
      type: login.fulfilled.type,
      payload: { user: mockUser, token: mockToken }
    };
    const state = authSlice(initialState, action);
    expect(state.user).toEqual(mockUser);
    expect(state.token).toBe(mockToken);
    expect(state.isLoading).toBe(false);
    expect(state.error).toBe(null);
  });

  it('should handle login rejected', () => {
    const action = {
      type: login.rejected.type,
      error: { message: 'Login failed' }
    };
    const state = authSlice(initialState, action);
    expect(state.isLoading).toBe(false);
    expect(state.error).toBe('Login failed');
  });

  it('should handle logout', () => {
    const stateWithUser = {
      ...initialState,
      user: {
        id: 1,
        username: 'test',
        email: 'test@test.com',
        phone: '9999999999',
        role: 'BUYER' as const,
      },
      token: 'mock-token'
    };
    const action = { type: logout.fulfilled.type };
    const state = authSlice(stateWithUser, action);
    expect(state.user).toBe(null);
    expect(state.token).toBe(null);
    expect(state.error).toBe(null);
  });
});
