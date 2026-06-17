import React, { useEffect } from 'react';
import { View, StyleSheet, FlatList, Alert } from 'react-native';
import { Text, Card, Button, IconButton, Divider } from 'react-native-paper';
import { useDispatch, useSelector } from 'react-redux';
import { useTranslation } from 'react-i18next';
import { NavigationProp, useNavigation } from '@react-navigation/native';
import AsyncStorage from '@react-native-async-storage/async-storage';

import { RootState, AppDispatch } from '../store';
import { loadCartFromStorage, removeFromCart, updateQuantity, clearCart } from '../store/cartSlice';
import { RootStackParamList } from '../navigation/types';

export default function CartScreen() {
  const { t } = useTranslation();
  const navigation = useNavigation<NavigationProp<RootStackParamList>>();
  const dispatch = useDispatch<AppDispatch>();
  
  const { items, totalAmount, totalItems } = useSelector((state: RootState) => state.cart);
  const { user } = useSelector((state: RootState) => state.auth);

  useEffect(() => {
    loadCart();
  }, []);

  const loadCart = async () => {
    try {
      const cartData = await AsyncStorage.getItem('cart');
      if (cartData) {
        const cartItems = JSON.parse(cartData);
        dispatch(loadCartFromStorage(cartItems));
      }
    } catch (error) {
      console.error('Failed to load cart:', error);
    }
  };

  const handleRemoveItem = (productId: number) => {
    dispatch(removeFromCart(productId));
  };

  const handleUpdateQuantity = (productId: number, quantity: number) => {
    dispatch(updateQuantity({ productId, quantity }));
  };

  const handleProceedToCheckout = () => {
    if (!user) {
      Alert.alert(
        t('auth.login'),
        'Please login to proceed to checkout',
        [
          { text: t('common.cancel'), style: 'cancel' },
          { text: t('auth.login'), onPress: () => navigation.navigate('Login') }
        ]
      );
      return;
    }

    if (items.length === 0) {
      Alert.alert(t('common.error'), t('cart.emptyCart'));
      return;
    }

    navigation.navigate('Checkout');
  };

  const renderCartItem = ({ item }: { item: any }) => (
    <Card style={styles.cartItem}>
      <Card.Content style={styles.itemContent}>
        <View style={styles.itemInfo}>
          <Text variant="titleMedium" style={styles.itemName}>
            {item.product.name}
          </Text>
          <Text variant="bodySmall" style={styles.itemSeller}>
            {t('products.seller')}: {item.product.sellerName}
          </Text>
          <Text variant="titleMedium" style={styles.itemPrice}>
            ₹{item.product.price}
          </Text>
        </View>
        
        <View style={styles.quantityControls}>
          <IconButton
            icon="minus"
            size={20}
            onPress={() => handleUpdateQuantity(item.product.id, item.quantity - 1)}
            disabled={item.quantity <= 1}
          />
          <Text variant="titleMedium" style={styles.quantity}>
            {item.quantity}
          </Text>
          <IconButton
            icon="plus"
            size={20}
            onPress={() => handleUpdateQuantity(item.product.id, item.quantity + 1)}
          />
        </View>
        
        <IconButton
          icon="delete"
          size={20}
          onPress={() => handleRemoveItem(item.product.id)}
          iconColor="#D32F2F"
        />
      </Card.Content>
    </Card>
  );

  if (items.length === 0) {
    return (
      <View style={styles.emptyContainer}>
        <Card style={styles.emptyCard}>
          <Card.Content style={styles.emptyContent}>
            <Text variant="headlineSmall" style={styles.emptyText}>
              {t('cart.emptyCart')}
            </Text>
            <Button
              mode="contained"
              onPress={() => navigation.navigate('Home')}
              style={styles.browseButton}
            >
              Browse Products
            </Button>
          </Card.Content>
        </Card>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <FlatList
        data={items}
        renderItem={renderCartItem}
        keyExtractor={(item) => item.product.id.toString()}
        contentContainerStyle={styles.listContainer}
        showsVerticalScrollIndicator={false}
      />
      
      <Card style={styles.summaryCard}>
        <Card.Content>
          <View style={styles.summaryRow}>
            <Text variant="titleMedium">{t('common.total')}</Text>
            <Text variant="titleLarge" style={styles.totalAmount}>
              ₹{totalAmount.toFixed(2)}
            </Text>
          </View>
          
          <View style={styles.summaryRow}>
            <Text variant="bodyMedium">{t('common.quantity')}</Text>
            <Text variant="bodyMedium">{totalItems} items</Text>
          </View>
          
          <Divider style={styles.divider} />
          
          <Button
            mode="contained"
            onPress={handleProceedToCheckout}
            style={styles.checkoutButton}
            icon="credit-card"
          >
            {t('cart.proceedToCheckout')}
          </Button>
        </Card.Content>
      </Card>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F5F5F5',
  },
  listContainer: {
    padding: 16,
    paddingBottom: 100, // Space for summary card
  },
  cartItem: {
    marginBottom: 12,
    elevation: 2,
  },
  itemContent: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  itemInfo: {
    flex: 1,
  },
  itemName: {
    fontWeight: 'bold',
    color: '#2E7D32',
    marginBottom: 4,
  },
  itemSeller: {
    color: '#666',
    marginBottom: 4,
  },
  itemPrice: {
    fontWeight: 'bold',
    color: '#FF6F00',
  },
  quantityControls: {
    flexDirection: 'row',
    alignItems: 'center',
    marginHorizontal: 8,
  },
  quantity: {
    marginHorizontal: 8,
    minWidth: 30,
    textAlign: 'center',
  },
  summaryCard: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    elevation: 8,
  },
  summaryRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 8,
  },
  totalAmount: {
    fontWeight: 'bold',
    color: '#FF6F00',
  },
  divider: {
    marginVertical: 12,
  },
  checkoutButton: {
    marginTop: 8,
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 16,
  },
  emptyCard: {
    width: '100%',
    maxWidth: 300,
  },
  emptyContent: {
    alignItems: 'center',
    paddingVertical: 32,
  },
  emptyText: {
    textAlign: 'center',
    marginBottom: 16,
    color: '#666',
  },
  browseButton: {
    marginTop: 8,
  },
});
