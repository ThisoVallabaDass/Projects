import React, { createContext, useContext, useState, useEffect } from 'react';

const LanguageContext = createContext();

export const useLanguage = () => {
  const context = useContext(LanguageContext);
  if (!context) {
    throw new Error('useLanguage must be used within a LanguageProvider');
  }
  return context;
};

// Translation strings
const translations = {
  en: {
    // Navigation
    home: 'Home',
    products: 'Products',
    orders: 'Orders',
    dashboard: 'Dashboard',
    login: 'Login',
    register: 'Register',
    logout: 'Logout',
    profile: 'Profile',
    
    // Common
    search: 'Search',
    filter: 'Filter',
    sort: 'Sort',
    category: 'Category',
    price: 'Price',
    quantity: 'Quantity',
    total: 'Total',
    submit: 'Submit',
    cancel: 'Cancel',
    save: 'Save',
    edit: 'Edit',
    delete: 'Delete',
    loading: 'Loading...',
    
    // Auth
    email: 'Email',
    password: 'Password',
    name: 'Name',
    pincode: 'Pincode',
    phoneNumber: 'Phone Number',
    role: 'Role',
    customer: 'Customer',
    entrepreneur: 'Entrepreneur',
    
    // Products
    productName: 'Product Name',
    description: 'Description',
    addProduct: 'Add Product',
    editProduct: 'Edit Product',
    myProducts: 'My Products',
    addToCart: 'Add to Cart',
    buyNow: 'Buy Now',
    
    // Orders
    myOrders: 'My Orders',
    orderHistory: 'Order History',
    orderStatus: 'Order Status',
    pending: 'Pending',
    confirmed: 'Confirmed',
    shipped: 'Shipped',
    delivered: 'Delivered',
    cancelled: 'Cancelled',
    
    // Marketplace
    marketplace: 'Marketplace',
    nearbyProducts: 'Nearby Products',
    allCategories: 'All Categories',
    
    // Messages
    welcome: 'Welcome to Tiny Trail',
    tagline: 'From Home to Your Hands',
    noProducts: 'No products found',
    noOrders: 'No orders found',
  },
  ta: {
    // Navigation
    home: 'முகப்பு',
    products: 'பொருட்கள்',
    orders: 'ஆர்டர்கள்',
    dashboard: 'டாஷ்போர்டு',
    login: 'உள்நுழைய',
    register: 'பதிவு செய்ய',
    logout: 'வெளியேறு',
    profile: 'சுயவிவரம்',
    
    // Common
    search: 'தேடு',
    filter: 'வடிகட்டு',
    sort: 'வரிசைப்படுத்து',
    category: 'வகை',
    price: 'விலை',
    quantity: 'அளவு',
    total: 'மொத்தம்',
    submit: 'சமர்பிக்க',
    cancel: 'ரத்து செய்',
    save: 'சேமி',
    edit: 'திருத்து',
    delete: 'நீக்கு',
    loading: 'ஏற்றுகிறது...',
    
    // Auth
    email: 'மின்னஞ்சல்',
    password: 'கடவுச்சொல்',
    name: 'பெயர்',
    pincode: 'பின்கோடு',
    phoneNumber: 'தொலைபேசி எண்',
    role: 'பாத்திரம்',
    customer: 'வாடிக்கையாளர்',
    entrepreneur: 'தொழில்முனைவோர்',
    
    // Products
    productName: 'பொருளின் பெயர்',
    description: 'விளக்கம்',
    addProduct: 'பொருள் சேர்க்க',
    editProduct: 'பொருள் திருத்த',
    myProducts: 'என் பொருட்கள்',
    addToCart: 'கார்ட்டில் சேர்க்க',
    buyNow: 'இப்போது வாங்க',
    
    // Orders
    myOrders: 'என் ஆர்டர்கள்',
    orderHistory: 'ஆர்டர் வரலாறு',
    orderStatus: 'ஆர்டர் நிலை',
    pending: 'நிலுவையில்',
    confirmed: 'உறுதிப்படுத்தப்பட்டது',
    shipped: 'அனுப்பப்பட்டது',
    delivered: 'வழங்கப்பட்டது',
    cancelled: 'ரத்து செய்யப்பட்டது',
    
    // Marketplace
    marketplace: 'சந்தை',
    nearbyProducts: 'அருகிலுள்ள பொருட்கள்',
    allCategories: 'அனைத்து வகைகள்',
    
    // Messages
    welcome: 'டைனி ட்ரெயிலுக்கு வரவேற்கிறோம்',
    tagline: 'வீட்டிலிருந்து உங்கள் கைகளுக்கு',
    noProducts: 'பொருட்கள் எதுவும் கிடைக்கவில்லை',
    noOrders: 'ஆர்டர்கள் எதுவும் கிடைக்கவில்லை',
  },
};

export const LanguageProvider = ({ children }) => {
  const [language, setLanguage] = useState('en');

  useEffect(() => {
    const savedLanguage = localStorage.getItem('language');
    if (savedLanguage && translations[savedLanguage]) {
      setLanguage(savedLanguage);
    }
  }, []);

  const changeLanguage = (lang) => {
    if (translations[lang]) {
      setLanguage(lang);
      localStorage.setItem('language', lang);
    }
  };

  const t = (key) => {
    return translations[language][key] || key;
  };

  const value = {
    language,
    changeLanguage,
    t,
    isEnglish: language === 'en',
    isTamil: language === 'ta',
  };

  return (
    <LanguageContext.Provider value={value}>
      {children}
    </LanguageContext.Provider>
  );
};
