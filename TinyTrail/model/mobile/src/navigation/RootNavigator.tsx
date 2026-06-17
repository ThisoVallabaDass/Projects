import React from 'react';
import { createStackNavigator } from '@react-navigation/stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { Ionicons } from '@expo/vector-icons';
import { useSelector } from 'react-redux';
import { useTranslation } from 'react-i18next';

// Screens
import HomeScreen from '../screens/HomeScreen';
import ProductListScreen from '../screens/ProductListScreen';
import ProductDetailScreen from '../screens/ProductDetailScreen';
import SellerOnboardScreen from '../screens/SellerOnboardScreen';
import CartScreen from '../screens/CartScreen';
import CheckoutScreen from '../screens/CheckoutScreen';
import OrdersScreen from '../screens/OrdersScreen';
import ProfileScreen from '../screens/ProfileScreen';
import AdminPanelScreen from '../screens/AdminPanelScreen';
import LoginScreen from '../screens/LoginScreen';
import RegisterScreen from '../screens/RegisterScreen';
import VendorDashboardScreen from '../screens/VendorDashboardScreen';
import { RootState } from '../store';

const Stack = createStackNavigator();
const Tab = createBottomTabNavigator();

function CustomerTabNavigator() {
  const { t } = useTranslation();

  return (
    <Tab.Navigator
      screenOptions={({ route }) => ({
        tabBarIcon: ({ focused, color, size }) => {
          let iconName: keyof typeof Ionicons.glyphMap;

          if (route.name === 'Home') {
            iconName = focused ? 'home' : 'home-outline';
          } else if (route.name === 'Products') {
            iconName = focused ? 'grid' : 'grid-outline';
          } else if (route.name === 'Cart') {
            iconName = focused ? 'cart' : 'cart-outline';
          } else if (route.name === 'Orders') {
            iconName = focused ? 'receipt' : 'receipt-outline';
          } else if (route.name === 'Profile') {
            iconName = focused ? 'person' : 'person-outline';
          } else {
            iconName = 'help-outline';
          }

          return <Ionicons name={iconName} size={size} color={color} />;
        },
        tabBarActiveTintColor: '#1667D9',
        tabBarInactiveTintColor: 'gray',
        headerShown: false,
      })}
    >
      <Tab.Screen 
        name="Home" 
        component={HomeScreen} 
        options={{ title: t('navigation.home') }}
      />
      <Tab.Screen 
        name="Products" 
        component={ProductListScreen} 
        options={{ title: t('navigation.products') }}
      />
      <Tab.Screen 
        name="Cart" 
        component={CartScreen} 
        options={{ title: t('navigation.cart') }}
      />
      <Tab.Screen 
        name="Orders" 
        component={OrdersScreen} 
        options={{ title: t('navigation.orders') }}
      />
      <Tab.Screen 
        name="Profile" 
        component={ProfileScreen} 
        options={{ title: t('navigation.profile') }}
      />
    </Tab.Navigator>
  );
}

function VendorTabNavigator() {
  const { t } = useTranslation();

  return (
    <Tab.Navigator
      screenOptions={({ route }) => ({
        tabBarIcon: ({ focused, color, size }) => {
          let iconName: keyof typeof Ionicons.glyphMap;

          if (route.name === 'VendorDashboard') {
            iconName = focused ? 'radio' : 'radio-outline';
          } else if (route.name === 'SellerOnboard') {
            iconName = focused ? 'storefront' : 'storefront-outline';
          } else if (route.name === 'Orders') {
            iconName = focused ? 'receipt' : 'receipt-outline';
          } else if (route.name === 'Profile') {
            iconName = focused ? 'person' : 'person-outline';
          } else {
            iconName = 'ellipse-outline';
          }

          return <Ionicons name={iconName} size={size} color={color} />;
        },
        tabBarActiveTintColor: '#227A3B',
        tabBarInactiveTintColor: 'gray',
        headerShown: false,
      })}
    >
      <Tab.Screen
        name="VendorDashboard"
        component={VendorDashboardScreen}
        options={{ title: 'Dashboard' }}
      />
      <Tab.Screen
        name="SellerOnboard"
        component={SellerOnboardScreen}
        options={{ title: 'Studio' }}
      />
      <Tab.Screen
        name="Orders"
        component={OrdersScreen}
        options={{ title: t('navigation.orders') }}
      />
      <Tab.Screen
        name="Profile"
        component={ProfileScreen}
        options={{ title: t('navigation.profile') }}
      />
    </Tab.Navigator>
  );
}

// Root Stack Navigator
export default function RootNavigator() {
  const { user } = useSelector((state: RootState) => state.auth);

  return (
    <Stack.Navigator
      screenOptions={{
        headerShown: false,
      }}
    >
      {user ? (
        <>
          <Stack.Screen
            name="MainTabs"
            component={user.role === 'SELLER' ? VendorTabNavigator : CustomerTabNavigator}
          />
          <Stack.Screen
            name="ProductDetail"
            component={ProductDetailScreen}
            options={{ headerShown: true, title: 'Product Details' }}
          />
          <Stack.Screen
            name="Checkout"
            component={CheckoutScreen}
            options={{ headerShown: true, title: 'Checkout' }}
          />
          <Stack.Screen
            name="AdminPanel"
            component={AdminPanelScreen}
            options={{ headerShown: true, title: 'Admin Panel' }}
          />
        </>
      ) : (
        <>
          <Stack.Screen name="Login" component={LoginScreen} />
          <Stack.Screen name="Register" component={RegisterScreen} />
        </>
      )}
    </Stack.Navigator>
  );
}
