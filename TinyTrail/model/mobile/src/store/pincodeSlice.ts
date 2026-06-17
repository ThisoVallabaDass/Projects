import { createSlice, PayloadAction } from '@reduxjs/toolkit';

interface PincodeState {
  currentPincode: string;
  isValid: boolean;
  location: {
    city: string;
    state: string;
  } | null;
}

const initialState: PincodeState = {
  currentPincode: '',
  isValid: false,
  location: null,
};

const pincodeSlice = createSlice({
  name: 'pincode',
  initialState,
  reducers: {
    setPincode: (state, action: PayloadAction<string>) => {
      state.currentPincode = action.payload;
      // Basic validation for Indian pincode (6 digits)
      state.isValid = /^\d{6}$/.test(action.payload);
    },
    
    setLocation: (state, action: PayloadAction<{ city: string; state: string }>) => {
      state.location = action.payload;
    },
    
    clearPincode: (state) => {
      state.currentPincode = '';
      state.isValid = false;
      state.location = null;
    },
  },
});

export const { setPincode, setLocation, clearPincode } = pincodeSlice.actions;
export default pincodeSlice.reducer;
