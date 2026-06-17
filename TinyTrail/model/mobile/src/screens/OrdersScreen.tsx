import React, { useState, useEffect } from 'react';
import { View, StyleSheet, FlatList, Alert } from 'react-native';
import { Text, Card, Button, Chip, Divider } from 'react-native-paper';
import { useDispatch, useSelector } from 'react-redux';
import { useTranslation } from 'react-i18next';
import { NavigationProp, useNavigation } from '@react-navigation/native';

import { RootState, AppDispatch } from '../store';
import { RootStackParamList } from '../navigation/types';

interface Order {
  id: number;
  orderId: string;
  totalAmount: number;
  status: 'PENDING' | 'CONFIRMED' | 'SHIPPED' | 'DELIVERED' | 'CANCELLED';
  orderDate: string;
  deliveryDate?: string;
  items: Array<{
    productName: string;
    quantity: number;
    price: number;
  }>;
}

export default function OrdersScreen() {
  const { t } = useTranslation();
  const navigation = useNavigation<NavigationProp<RootStackParamList>>();
  const dispatch = useDispatch<AppDispatch>();
  
  const { user } = useSelector((state: RootState) => state.auth);

  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadOrders();
  }, []);

  const loadOrders = async () => {
    try {
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Mock orders data
      const mockOrders: Order[] = [
        {
          id: 1,
          orderId: 'TT-001',
          totalAmount: 250.00,
          status: 'DELIVERED',
          orderDate: '2024-01-15',
          deliveryDate: '2024-01-17',
          items: [
            { productName: 'Fresh Tomatoes', quantity: 2, price: 50.00 },
            { productName: 'Organic Spinach', quantity: 1, price: 30.00 },
            { productName: 'Local Potatoes', quantity: 3, price: 60.00 },
          ]
        },
        {
          id: 2,
          orderId: 'TT-002',
          totalAmount: 180.00,
          status: 'SHIPPED',
          orderDate: '2024-01-20',
          items: [
            { productName: 'Fresh Mangoes', quantity: 2, price: 80.00 },
            { productName: 'Bananas', quantity: 1, price: 20.00 },
          ]
        },
        {
          id: 3,
          orderId: 'TT-003',
          totalAmount: 320.00,
          status: 'PENDING',
          orderDate: '2024-01-22',
          items: [
            { productName: 'Dairy Products', quantity: 1, price: 120.00 },
            { productName: 'Grains', quantity: 2, price: 100.00 },
          ]
        }
      ];
      
      setOrders(mockOrders);
    } catch (error) {
      Alert.alert(t('common.error'), 'Failed to load orders');
    } finally {
      setLoading(false);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'PENDING': return '#FF9800';
      case 'CONFIRMED': return '#2196F3';
      case 'SHIPPED': return '#9C27B0';
      case 'DELIVERED': return '#4CAF50';
      case 'CANCELLED': return '#F44336';
      default: return '#666';
    }
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case 'PENDING': return t('orders.pending');
      case 'CONFIRMED': return t('orders.confirmed');
      case 'SHIPPED': return t('orders.shipped');
      case 'DELIVERED': return t('orders.delivered');
      case 'CANCELLED': return t('orders.cancelled');
      default: return status;
    }
  };

  const renderOrder = ({ item }: { item: Order }) => (
    <Card style={styles.orderCard}>
      <Card.Content>
        <View style={styles.orderHeader}>
          <Text variant="titleMedium" style={styles.orderId}>
            {t('orders.orderId')}: {item.orderId}
          </Text>
          <Chip 
            style={[styles.statusChip, { backgroundColor: getStatusColor(item.status) + '20' }]}
            textStyle={{ color: getStatusColor(item.status) }}
          >
            {getStatusText(item.status)}
          </Chip>
        </View>
        
        <Text variant="bodySmall" style={styles.orderDate}>
          {t('orders.orderDate')}: {new Date(item.orderDate).toLocaleDateString()}
        </Text>
        
        {item.deliveryDate && (
          <Text variant="bodySmall" style={styles.deliveryDate}>
            {t('orders.deliveryDate')}: {new Date(item.deliveryDate).toLocaleDateString()}
          </Text>
        )}
        
        <Divider style={styles.divider} />
        
        <View style={styles.itemsContainer}>
          {item.items.map((orderItem, index) => (
            <View key={index} style={styles.orderItem}>
              <Text variant="bodyMedium">{orderItem.productName}</Text>
              <Text variant="bodyMedium">
                {orderItem.quantity} × ₹{orderItem.price} = ₹{(orderItem.quantity * orderItem.price).toFixed(2)}
              </Text>
            </View>
          ))}
        </View>
        
        <Divider style={styles.divider} />
        
        <View style={styles.totalRow}>
          <Text variant="titleMedium" style={styles.totalLabel}>
            {t('common.total')}
          </Text>
          <Text variant="titleMedium" style={styles.totalAmount}>
            ₹{item.totalAmount.toFixed(2)}
          </Text>
        </View>
        
        {item.status !== 'DELIVERED' && item.status !== 'CANCELLED' && (
          <Button
            mode="outlined"
            onPress={() => handleTrackOrder(item)}
            style={styles.trackButton}
            icon="map-marker"
          >
            {t('orders.trackOrder')}
          </Button>
        )}
      </Card.Content>
    </Card>
  );

  const handleTrackOrder = (order: Order) => {
    Alert.alert(
      'Track Order',
      `Order ${order.orderId} is currently ${getStatusText(order.status).toLowerCase()}.`,
      [{ text: 'OK' }]
    );
  };

  if (loading) {
    return (
      <View style={styles.loadingContainer}>
        <Text>{t('common.loading')}</Text>
      </View>
    );
  }

  if (orders.length === 0) {
    return (
      <View style={styles.emptyContainer}>
        <Card style={styles.emptyCard}>
          <Card.Content style={styles.emptyContent}>
            <Text variant="headlineSmall" style={styles.emptyText}>
              {t('orders.orderHistory')}
            </Text>
            <Text variant="bodyMedium" style={styles.emptySubtext}>
              You haven't placed any orders yet.
            </Text>
            <Button
              mode="contained"
              onPress={() => navigation.navigate('Home')}
              style={styles.browseButton}
            >
              Start Shopping
            </Button>
          </Card.Content>
        </Card>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <FlatList
        data={orders}
        renderItem={renderOrder}
        keyExtractor={(item) => item.id.toString()}
        contentContainerStyle={styles.listContainer}
        showsVerticalScrollIndicator={false}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F5F5F5',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  listContainer: {
    padding: 16,
  },
  orderCard: {
    marginBottom: 16,
    elevation: 2,
  },
  orderHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  orderId: {
    fontWeight: 'bold',
    color: '#2E7D32',
  },
  statusChip: {
    borderRadius: 16,
  },
  orderDate: {
    color: '#666',
    marginBottom: 4,
  },
  deliveryDate: {
    color: '#666',
    marginBottom: 8,
  },
  divider: {
    marginVertical: 12,
  },
  itemsContainer: {
    marginBottom: 8,
  },
  orderItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 4,
  },
  totalRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  totalLabel: {
    fontWeight: 'bold',
  },
  totalAmount: {
    fontWeight: 'bold',
    color: '#FF6F00',
  },
  trackButton: {
    marginTop: 12,
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
    marginBottom: 8,
    color: '#666',
  },
  emptySubtext: {
    textAlign: 'center',
    marginBottom: 16,
    color: '#999',
  },
  browseButton: {
    marginTop: 8,
  },
});
