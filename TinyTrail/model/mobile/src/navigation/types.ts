export type RootStackParamList = {
  MainTabs: undefined;
  Home: undefined;
  Products: undefined;
  Cart: undefined;
  Orders: undefined;
  Profile: undefined;
  Login: { mode?: 'customer' | 'vendor' } | undefined;
  Register: { mode?: 'customer' | 'vendor' } | undefined;
  ProductDetail: { productId: number };
  SellerOnboard: undefined;
  VendorDashboard: undefined;
  Checkout: undefined;
  AdminPanel: undefined;
};
