import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  Alert,
  SafeAreaView,
} from 'react-native';
import axios from 'axios';
import Icon from '../components/Icon';

const API_URL = 'http://localhost:8080/api';

export default function OrdersScreen() {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(false);
  const [expandedOrderId, setExpandedOrderId] = useState(null);

  useEffect(() => {
    fetchOrders();
  }, []);

  const fetchOrders = async () => {
    if (!global.tinytrailToken) {
      Alert.alert('Error', 'Please login first');
      return;
    }

    setLoading(true);
    try {
      const response = await axios.get(`${API_URL}/orders`, {
        headers: { Authorization: `Bearer ${global.tinytrailToken}` },
      });
      setOrders(response.data.orders || []);
    } catch (error) {
      Alert.alert('Error', 'Failed to fetch orders');
    } finally {
      setLoading(false);
    }
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'Pending':
        return '#f59e0b';
      case 'Processing':
        return '#3b82f6';
      case 'Shipped':
        return '#06b6d4';
      case 'Delivered':
        return '#10b981';
      case 'Cancelled':
        return '#ef4444';
      default:
        return '#666';
    }
  };

  const getStatusIcon = (status) => {
    switch (status) {
      case 'Pending':
        return 'clock-o';
      case 'Processing':
        return 'cog';
      case 'Shipped':
        return 'truck';
      case 'Delivered':
        return 'check-circle';
      case 'Cancelled':
        return 'times-circle';
      default:
        return 'question-circle';
    }
  };

  const renderOrderItem = ({ item }) => (
    <TouchableOpacity
      style={styles.orderCard}
      onPress={() =>
        setExpandedOrderId(expandedOrderId === item.id ? null : item.id)
      }
    >
      <View style={styles.orderHeader}>
        <View>
          <Text style={styles.orderId}>Order #{item.id}</Text>
          <Text style={styles.orderDate}>
            {new Date(item.createdAt).toLocaleDateString()}
          </Text>
        </View>
        <View style={[styles.statusBadge, { backgroundColor: getStatusColor(item.status) }]}>
          <Icon name={getStatusIcon(item.status)} size={14} color="#fff" />
          <Text style={styles.statusText}>{item.status}</Text>
        </View>
      </View>

      <View style={styles.orderSummary}>
        <Text style={styles.summaryLabel}>Total: ₹{item.totalAmount}</Text>
        <Text style={styles.summaryLabel}>Items: {item.itemCount}</Text>
      </View>

      {expandedOrderId === item.id && (
        <View style={styles.orderDetails}>
          <View style={styles.detailRow}>
            <Text style={styles.detailLabel}>Delivery Address:</Text>
            <Text style={styles.detailValue}>{item.deliveryAddress}</Text>
          </View>
          <View style={styles.detailRow}>
            <Text style={styles.detailLabel}>Phone:</Text>
            <Text style={styles.detailValue}>{item.phone}</Text>
          </View>
          <View style={styles.detailRow}>
            <Text style={styles.detailLabel}>Payment Method:</Text>
            <Text style={styles.detailValue}>{item.paymentMethod}</Text>
          </View>

          {item.items && item.items.length > 0 && (
            <View style={styles.itemsSection}>
              <Text style={styles.itemsTitle}>Items Ordered:</Text>
              {item.items.map((orderItem, index) => (
                <View key={index} style={styles.orderItemRow}>
                  <View>
                    <Text style={styles.orderItemName}>{orderItem.name}</Text>
                    <Text style={styles.orderItemQuantity}>
                      Qty: {orderItem.quantity}
                    </Text>
                  </View>
                  <Text style={styles.orderItemPrice}>
                    ₹{orderItem.price * orderItem.quantity}
                  </Text>
                </View>
              ))}
            </View>
          )}

          <TouchableOpacity
            style={styles.trackButton}
            onPress={() => Alert.alert('Track', 'Your order is on the way!')}
          >
            <Icon name="location-arrow" size={14} color="#fff" />
            <Text style={styles.trackButtonText}>Track Order</Text>
          </TouchableOpacity>
        </View>
      )}
    </TouchableOpacity>
  );

  if (loading) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#16a34a" />
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      {orders.length === 0 ? (
        <View style={styles.emptyContainer}>
          <Icon name="inbox" size={50} color="#ccc" />
          <Text style={styles.emptyText}>No orders yet</Text>
          <Text style={styles.emptySubText}>Start shopping to place your first order</Text>
        </View>
      ) : (
        <FlatList
          data={orders}
          renderItem={renderOrderItem}
          keyExtractor={(item) => item.id.toString()}
          contentContainerStyle={styles.ordersList}
          refreshing={loading}
          onRefresh={fetchOrders}
        />
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f3f4f6',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  emptyText: {
    marginTop: 10,
    fontSize: 18,
    fontWeight: 'bold',
    color: '#333',
  },
  emptySubText: {
    marginTop: 5,
    color: '#999',
  },
  ordersList: {
    padding: 10,
  },
  orderCard: {
    backgroundColor: '#fff',
    borderRadius: 8,
    margin: 10,
    padding: 15,
    marginBottom: 12,
    borderLeftWidth: 4,
    borderLeftColor: '#16a34a',
  },
  orderHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 10,
  },
  orderId: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#333',
  },
  orderDate: {
    fontSize: 12,
    color: '#999',
    marginTop: 4,
  },
  statusBadge: {
    flexDirection: 'row',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 20,
    alignItems: 'center',
  },
  statusText: {
    color: '#fff',
    fontSize: 12,
    fontWeight: 'bold',
    marginLeft: 6,
  },
  orderSummary: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 10,
    borderBottomWidth: 1,
    borderBottomColor: '#eee',
    marginBottom: 10,
  },
  summaryLabel: {
    fontSize: 14,
    fontWeight: 'bold',
    color: '#16a34a',
  },
  orderDetails: {
    marginTop: 10,
    paddingTop: 10,
    borderTopWidth: 1,
    borderTopColor: '#eee',
  },
  detailRow: {
    marginBottom: 12,
  },
  detailLabel: {
    fontSize: 12,
    color: '#999',
    marginBottom: 4,
  },
  detailValue: {
    fontSize: 14,
    color: '#333',
    fontWeight: '500',
  },
  itemsSection: {
    marginTop: 12,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: '#eee',
  },
  itemsTitle: {
    fontSize: 14,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 8,
  },
  orderItemRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 8,
  },
  orderItemName: {
    fontSize: 13,
    color: '#333',
  },
  orderItemQuantity: {
    fontSize: 12,
    color: '#999',
    marginTop: 2,
  },
  orderItemPrice: {
    fontSize: 13,
    fontWeight: 'bold',
    color: '#16a34a',
  },
  trackButton: {
    backgroundColor: '#16a34a',
    flexDirection: 'row',
    paddingVertical: 10,
    borderRadius: 6,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 12,
  },
  trackButtonText: {
    color: '#fff',
    fontWeight: 'bold',
    fontSize: 14,
    marginLeft: 6,
  },
});
