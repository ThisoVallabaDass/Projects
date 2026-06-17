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
  TextInput,
} from 'react-native';
import axios from 'axios';
import Icon from '../components/Icon';

const API_URL = 'http://localhost:8080/api';

export default function CartScreen() {
  const [items, setItems] = useState([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(false);
  const [address, setAddress] = useState('');
  const [phone, setPhone] = useState('');
  const [paymentMethod, setPaymentMethod] = useState('COD');
  const [placing, setPlacing] = useState(false);

  useEffect(() => {
    fetchCart();
  }, []);

  const fetchCart = async () => {
    if (!global.tinytrailToken) {
      Alert.alert('Error', 'Please login first');
      return;
    }

    setLoading(true);
    try {
      const response = await axios.get(`${API_URL}/cart`, {
        headers: { Authorization: `Bearer ${global.tinytrailToken}` },
      });
      setItems(response.data.items || []);
      setTotal(response.data.total || 0);
    } catch (error) {
      Alert.alert('Error', 'Failed to fetch cart');
    } finally {
      setLoading(false);
    }
  };

  const removeItem = async (productId) => {
    try {
      await axios.post(
        `${API_URL}/cart/remove`,
        { productId },
        { headers: { Authorization: `Bearer ${global.tinytrailToken}` } }
      );
      fetchCart();
    } catch (error) {
      Alert.alert('Error', 'Failed to remove item');
    }
  };

  const placeOrder = async () => {
    if (!address || !phone) {
      Alert.alert('Error', 'Please fill in address and phone');
      return;
    }

    setPlacing(true);
    try {
      await axios.post(
        `${API_URL}/orders`,
        { deliveryAddress: address, phone, paymentMethod },
        { headers: { Authorization: `Bearer ${global.tinytrailToken}` } }
      );
      Alert.alert('Success', 'Order placed successfully!');
      setItems([]);
      setTotal(0);
      setAddress('');
      setPhone('');
    } catch (error) {
      Alert.alert('Error', error.response?.data?.error || 'Failed to place order');
    } finally {
      setPlacing(false);
    }
  };

  const renderItem = ({ item }) => (
    <View style={styles.cartItem}>
      <View style={styles.itemImagePlaceholder}>
        <Icon name="image" size={30} color="#ccc" />
      </View>
      <View style={styles.itemDetails}>
        <Text style={styles.itemName}>{item.name}</Text>
        <Text style={styles.itemPrice}>₹{item.price}</Text>
        <Text style={styles.itemQuantity}>Qty: {item.quantity}</Text>
      </View>
      <View style={styles.itemTotal}>
        <Text style={styles.itemTotalText}>₹{item.price * item.quantity}</Text>
        <TouchableOpacity
          style={styles.removeButton}
          onPress={() => removeItem(item.id)}
        >
          <Icon name="trash" size={16} color="#dc2626" />
        </TouchableOpacity>
      </View>
    </View>
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
      {items.length === 0 ? (
        <View style={styles.emptyContainer}>
          <Icon name="shopping-cart" size={50} color="#ccc" />
          <Text style={styles.emptyText}>Your cart is empty</Text>
        </View>
      ) : (
        <FlatList
          data={items}
          renderItem={renderItem}
          keyExtractor={(item) => item.id.toString()}
          ListFooterComponent={
            <View style={styles.footer}>
              <View style={styles.orderForm}>
                <Text style={styles.formLabel}>Delivery Address</Text>
                <TextInput
                  style={styles.textInput}
                  placeholder="Enter your address"
                  value={address}
                  onChangeText={setAddress}
                  multiline
                />

                <Text style={styles.formLabel}>Phone Number</Text>
                <TextInput
                  style={styles.textInput}
                  placeholder="Enter phone number"
                  value={phone}
                  onChangeText={setPhone}
                  keyboardType="phone-pad"
                />

                <Text style={styles.formLabel}>Payment Method</Text>
                <View style={styles.paymentMethods}>
                  {['COD', 'UPI', 'CARD'].map((method) => (
                    <TouchableOpacity
                      key={method}
                      style={[
                        styles.paymentMethod,
                        paymentMethod === method && styles.paymentMethodActive,
                      ]}
                      onPress={() => setPaymentMethod(method)}
                    >
                      <Text
                        style={[
                          styles.paymentMethodText,
                          paymentMethod === method && styles.paymentMethodTextActive,
                        ]}
                      >
                        {method}
                      </Text>
                    </TouchableOpacity>
                  ))}
                </View>
              </View>

              <View style={styles.summary}>
                <View style={styles.summaryRow}>
                  <Text style={styles.summaryLabel}>Subtotal:</Text>
                  <Text style={styles.summaryValue}>₹{total}</Text>
                </View>
                <View style={styles.summaryRow}>
                  <Text style={styles.summaryLabel}>Shipping:</Text>
                  <Text style={styles.summaryValue}>Free</Text>
                </View>
                <View style={[styles.summaryRow, styles.totalRow]}>
                  <Text style={styles.totalLabel}>Total:</Text>
                  <Text style={styles.totalValue}>₹{total}</Text>
                </View>

                <TouchableOpacity
                  style={[styles.placeOrderButton, placing && styles.buttonDisabled]}
                  onPress={placeOrder}
                  disabled={placing}
                >
                  <Text style={styles.placeOrderButtonText}>
                    {placing ? 'Placing order...' : 'Place Order'}
                  </Text>
                </TouchableOpacity>
              </View>
            </View>
          }
          contentContainerStyle={styles.cartList}
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
    color: '#999',
  },
  cartList: {
    padding: 10,
  },
  cartItem: {
    flexDirection: 'row',
    backgroundColor: '#fff',
    borderRadius: 8,
    margin: 10,
    padding: 12,
    alignItems: 'center',
  },
  itemImagePlaceholder: {
    width: 80,
    height: 80,
    backgroundColor: '#f5f5f5',
    borderRadius: 8,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  itemDetails: {
    flex: 1,
  },
  itemName: {
    fontSize: 14,
    fontWeight: 'bold',
    color: '#333',
  },
  itemPrice: {
    fontSize: 12,
    color: '#16a34a',
    marginTop: 4,
  },
  itemQuantity: {
    fontSize: 12,
    color: '#666',
    marginTop: 4,
  },
  itemTotal: {
    alignItems: 'center',
  },
  itemTotalText: {
    fontSize: 14,
    fontWeight: 'bold',
    color: '#16a34a',
    marginBottom: 8,
  },
  removeButton: {
    padding: 8,
  },
  footer: {
    padding: 15,
  },
  orderForm: {
    backgroundColor: '#fff',
    borderRadius: 8,
    padding: 15,
    marginBottom: 15,
  },
  formLabel: {
    fontSize: 14,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 8,
    marginTop: 12,
  },
  textInput: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 6,
    padding: 10,
    fontSize: 14,
  },
  paymentMethods: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 8,
  },
  paymentMethod: {
    flex: 1,
    paddingVertical: 10,
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 6,
    marginHorizontal: 4,
    alignItems: 'center',
  },
  paymentMethodActive: {
    backgroundColor: '#16a34a',
    borderColor: '#16a34a',
  },
  paymentMethodText: {
    fontSize: 12,
    color: '#666',
  },
  paymentMethodTextActive: {
    color: '#fff',
    fontWeight: 'bold',
  },
  summary: {
    backgroundColor: '#fff',
    borderRadius: 8,
    padding: 15,
  },
  summaryRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 8,
  },
  summaryLabel: {
    color: '#666',
  },
  summaryValue: {
    fontWeight: '600',
  },
  totalRow: {
    borderTopWidth: 1,
    borderTopColor: '#eee',
    paddingTopY: 12,
    marginBottom: 15,
  },
  totalLabel: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#16a34a',
  },
  totalValue: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#16a34a',
  },
  placeOrderButton: {
    backgroundColor: '#16a34a',
    paddingVertical: 12,
    borderRadius: 6,
    alignItems: 'center',
  },
  buttonDisabled: {
    backgroundColor: '#ccc',
  },
  placeOrderButtonText: {
    color: '#fff',
    fontWeight: 'bold',
    fontSize: 16,
  },
});
