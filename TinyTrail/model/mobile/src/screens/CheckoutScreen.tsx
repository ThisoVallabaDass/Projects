import React, { useState } from 'react';
import { View, StyleSheet, ScrollView, Alert } from 'react-native';
import { Text, Card, TextInput, Button, RadioButton, Divider } from 'react-native-paper';
import { useDispatch, useSelector } from 'react-redux';
import { useTranslation } from 'react-i18next';
import { NavigationProp, useNavigation } from '@react-navigation/native';

import { RootState, AppDispatch } from '../store';
import { clearCart } from '../store/cartSlice';
import { RootStackParamList } from '../navigation/types';

export default function CheckoutScreen() {
  const { t } = useTranslation();
  const navigation = useNavigation<NavigationProp<RootStackParamList>>();
  const dispatch = useDispatch<AppDispatch>();
  
  const { items, totalAmount } = useSelector((state: RootState) => state.cart);
  const { user } = useSelector((state: RootState) => state.auth);

  const [deliveryAddress, setDeliveryAddress] = useState('');
  const [paymentMethod, setPaymentMethod] = useState('upi');
  const [upiId, setUpiId] = useState('');
  const [isProcessing, setIsProcessing] = useState(false);

  const handlePlaceOrder = async () => {
    if (!deliveryAddress.trim()) {
      Alert.alert(t('common.error'), 'Please enter delivery address');
      return;
    }

    if (paymentMethod === 'upi' && !upiId.trim()) {
      Alert.alert(t('common.error'), 'Please enter UPI ID');
      return;
    }

    setIsProcessing(true);

    try {
      // Simulate order placement
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      // In a real app, you would call the backend API
      const orderData = {
        items: items.map(item => ({
          productId: item.product.id,
          quantity: item.quantity,
          price: item.product.price,
        })),
        totalAmount,
        deliveryAddress,
        paymentMethod,
        upiId: paymentMethod === 'upi' ? upiId : null,
      };

      console.log('Order data:', orderData);

      Alert.alert(
        t('common.success'),
        t('checkout.orderPlaced'),
        [
          {
            text: 'OK',
            onPress: () => {
              dispatch(clearCart());
              navigation.navigate('Orders');
            }
          }
        ]
      );
    } catch (error) {
      Alert.alert(t('common.error'), 'Failed to place order');
    } finally {
      setIsProcessing(false);
    }
  };

  const handleUPIPayment = () => {
    Alert.alert(
      'UPI Payment',
      'This is a demo. In production, this would open UPI payment gateway.',
      [
        { text: 'Cancel', style: 'cancel' },
        { text: 'Pay Now', onPress: handlePlaceOrder }
      ]
    );
  };

  return (
    <ScrollView style={styles.container}>
      {/* Order Summary */}
      <Card style={styles.card}>
        <Card.Content>
          <Text variant="titleMedium" style={styles.sectionTitle}>
            Order Summary
          </Text>
          {items.map((item) => (
            <View key={item.product.id} style={styles.orderItem}>
              <Text variant="bodyMedium">{item.product.name}</Text>
              <Text variant="bodyMedium">
                {item.quantity} × ₹{item.product.price} = ₹{(item.quantity * item.product.price).toFixed(2)}
              </Text>
            </View>
          ))}
          <Divider style={styles.divider} />
          <View style={styles.totalRow}>
            <Text variant="titleLarge" style={styles.totalLabel}>
              {t('common.total')}
            </Text>
            <Text variant="titleLarge" style={styles.totalAmount}>
              ₹{totalAmount.toFixed(2)}
            </Text>
          </View>
        </Card.Content>
      </Card>

      {/* Delivery Address */}
      <Card style={styles.card}>
        <Card.Content>
          <Text variant="titleMedium" style={styles.sectionTitle}>
            {t('checkout.deliveryAddress')}
          </Text>
          <TextInput
            label="Address"
            value={deliveryAddress}
            onChangeText={setDeliveryAddress}
            style={styles.input}
            mode="outlined"
            multiline
            placeholder="Enter your complete delivery address"
          />
        </Card.Content>
      </Card>

      {/* Payment Method */}
      <Card style={styles.card}>
        <Card.Content>
          <Text variant="titleMedium" style={styles.sectionTitle}>
            {t('checkout.paymentMethod')}
          </Text>
          
          <RadioButton.Group onValueChange={setPaymentMethod} value={paymentMethod}>
            <View style={styles.radioOption}>
              <RadioButton value="upi" />
              <Text variant="bodyMedium" style={styles.radioLabel}>
                {t('checkout.upiPayment')}
              </Text>
            </View>

            <View style={styles.radioOption}>
              <RadioButton value="cod" />
              <Text variant="bodyMedium" style={styles.radioLabel}>
                Cash on Delivery
              </Text>
            </View>
          </RadioButton.Group>

          {paymentMethod === 'upi' && (
            <TextInput
              label={t('checkout.upiId')}
              value={upiId}
              onChangeText={setUpiId}
              style={styles.input}
              mode="outlined"
              placeholder="Enter your UPI ID"
            />
          )}
        </Card.Content>
      </Card>

      {/* Place Order Button */}
      <View style={styles.buttonContainer}>
        <Button
          mode="contained"
          onPress={paymentMethod === 'upi' ? handleUPIPayment : handlePlaceOrder}
          style={styles.placeOrderButton}
          loading={isProcessing}
          disabled={isProcessing}
          icon="credit-card"
        >
          {isProcessing ? 'Processing...' : t('checkout.placeOrder')}
        </Button>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F5F5F5',
  },
  card: {
    margin: 16,
    marginBottom: 8,
  },
  sectionTitle: {
    fontWeight: 'bold',
    color: '#2E7D32',
    marginBottom: 12,
  },
  orderItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 8,
  },
  divider: {
    marginVertical: 12,
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
  input: {
    marginBottom: 12,
  },
  radioOption: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  radioLabel: {
    marginLeft: 8,
  },
  buttonContainer: {
    padding: 16,
    paddingBottom: 32,
  },
  placeOrderButton: {
    paddingVertical: 8,
  },
});
