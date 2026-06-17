import React, { useState, useEffect } from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { createStackNavigator } from '@react-navigation/stack';
import { View, Text, StyleSheet, ActivityIndicator } from 'react-native';
import Icon from './components/Icon';
import axios from 'axios';

// Import screens
import LoginScreen from './screens/LoginScreen';
import RegisterScreen from './screens/RegisterScreen';
import ProductsScreen from './screens/ProductsScreen';
import CartScreen from './screens/CartScreen';
import OrdersScreen from './screens/OrdersScreen';
import ProfileScreen from './screens/ProfileScreen';

const Tab = createBottomTabNavigator();
const Stack = createStackNavigator();

const API_URL = 'http://localhost:8080/api';

const HomeStack = () => {
  return (
    <Stack.Navigator
      screenOptions={{
        headerStyle: {
          backgroundColor: '#16a34a',
        },
        headerTintColor: '#fff',
        headerTitleStyle: {
          fontWeight: 'bold',
        },
      }}
    >
      <Stack.Screen 
        name="ProductsList" 
        component={ProductsScreen} 
        options={{ title: 'TinyTrail - Products' }}
      />
    </Stack.Navigator>
  );
};

const AuthStack = () => {
  return (
    <Stack.Navigator
      screenOptions={{
        headerShown: false,
      }}
    >
      <Stack.Screen name="Login" component={LoginScreen} />
      <Stack.Screen name="Register" component={RegisterScreen} />
    </Stack.Navigator>
  );
};

const HomeTabsStack = ({ user, onLogout }) => {
  return (
    <Tab.Navigator
      screenOptions={({ route }) => ({
        tabBarIcon: ({ focused, color, size }) => {
          let iconName;

          if (route.name === 'Home') {
            iconName = focused ? 'home' : 'home';
          } else if (route.name === 'Cart') {
            iconName = focused ? 'shopping-cart' : 'shopping-cart';
          } else if (route.name === 'Orders') {
            iconName = focused ? 'list' : 'list';
          } else if (route.name === 'Profile') {
            iconName = focused ? 'user' : 'user';
          }

          return <Icon name={iconName} size={size} color={color} />;
        },
        tabBarActiveTintColor: '#16a34a',
        tabBarInactiveTintColor: '#999',
        headerShown: true,
        headerStyle: {
          backgroundColor: '#16a34a',
        },
        headerTintColor: '#fff',
        headerTitleStyle: {
          fontWeight: 'bold',
          color: '#fff',
        },
      })}
    >
      <Tab.Screen 
        name="Home" 
        component={HomeStack}
        options={{ 
          title: 'Products',
          headerShown: false,
        }}
      />
      <Tab.Screen 
        name="Cart" 
        component={CartScreen}
        options={{ title: 'Shopping Cart' }}
      />
      <Tab.Screen 
        name="Orders" 
        component={OrdersScreen}
        options={{ title: 'My Orders' }}
      />
      <Tab.Screen 
        name="Profile" 
        component={() => <ProfileScreen user={user} onLogout={onLogout} />}
        options={{ title: 'Profile' }}
      />
    </Tab.Navigator>
  );
};

export default function App() {
  const [user, setUser] = useState(null);
  const [token, setToken] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Check if user is already logged in
    checkLoginStatus();
  }, []);

  const checkLoginStatus = async () => {
    try {
      // Try to load token from device storage (in production, use AsyncStorage)
      const savedToken = global.tinytrailToken;
      if (savedToken) {
        setToken(savedToken);
        // Verify token is still valid
        const response = await axios.get(`${API_URL}/auth/me`, {
          headers: { Authorization: `Bearer ${savedToken}` }
        });
        setUser(response.data);
      }
    } catch (error) {
      console.log('Token invalid or expired');
      global.tinytrailToken = null;
    } finally {
      setLoading(false);
    }
  };

  const handleLogin = (userData, authToken) => {
    setUser(userData);
    setToken(authToken);
    global.tinytrailToken = authToken;
  };

  const handleLogout = () => {
    setUser(null);
    setToken(null);
    global.tinytrailToken = null;
  };

  if (loading) {
    return (
      <View style={styles.container}>
        <ActivityIndicator size="large" color="#16a34a" />
      </View>
    );
  }

  return (
    <NavigationContainer>
      {user && token ? (
        <HomeTabsStack user={user} onLogout={handleLogout} />
      ) : (
        <AuthStack />
      )}
    </NavigationContainer>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#f3f4f6',
  },
});
