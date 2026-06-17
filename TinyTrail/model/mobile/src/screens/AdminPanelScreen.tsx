import React, { useState } from 'react';
import { View, StyleSheet, ScrollView, Alert } from 'react-native';
import { Text, Card, Button, Chip, DataTable } from 'react-native-paper';
import { useTranslation } from 'react-i18next';

export default function AdminPanelScreen() {
  const { t } = useTranslation();

  const [orders] = useState([
    { id: 1, orderId: 'TT-001', customer: 'John Doe', amount: 250, status: 'PENDING' },
    { id: 2, orderId: 'TT-002', customer: 'Jane Smith', amount: 180, status: 'CONFIRMED' },
    { id: 3, orderId: 'TT-003', customer: 'Bob Johnson', amount: 320, status: 'SHIPPED' },
  ]);

  const handleUpdateOrderStatus = (orderId: string, newStatus: string) => {
    Alert.alert(
      'Update Order Status',
      `Update order ${orderId} to ${newStatus}?`,
      [
        { text: 'Cancel', style: 'cancel' },
        { text: 'Update', onPress: () => console.log(`Updated ${orderId} to ${newStatus}`) }
      ]
    );
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

  return (
    <ScrollView style={styles.container}>
      <Card style={styles.card}>
        <Card.Content>
          <Text variant="headlineSmall" style={styles.title}>
            {t('admin.adminPanel')}
          </Text>
          <Text variant="bodyMedium" style={styles.subtitle}>
            Manage orders, users, and products
          </Text>
        </Card.Content>
      </Card>

      {/* Quick Stats */}
      <Card style={styles.card}>
        <Card.Content>
          <Text variant="titleMedium" style={styles.sectionTitle}>
            Quick Stats
          </Text>
          <View style={styles.statsContainer}>
            <View style={styles.statItem}>
              <Text variant="headlineMedium" style={styles.statNumber}>12</Text>
              <Text variant="bodySmall">Total Orders</Text>
            </View>
            <View style={styles.statItem}>
              <Text variant="headlineMedium" style={styles.statNumber}>8</Text>
              <Text variant="bodySmall">Active Sellers</Text>
            </View>
            <View style={styles.statItem}>
              <Text variant="headlineMedium" style={styles.statNumber}>45</Text>
              <Text variant="bodySmall">Products</Text>
            </View>
          </View>
        </Card.Content>
      </Card>

      {/* Orders Management */}
      <Card style={styles.card}>
        <Card.Content>
          <Text variant="titleMedium" style={styles.sectionTitle}>
            {t('admin.manageOrders')}
          </Text>
          
          <DataTable>
            <DataTable.Header>
              <DataTable.Title>Order ID</DataTable.Title>
              <DataTable.Title>Customer</DataTable.Title>
              <DataTable.Title numeric>Amount</DataTable.Title>
              <DataTable.Title>Status</DataTable.Title>
            </DataTable.Header>

            {orders.map((order) => (
              <DataTable.Row key={order.id}>
                <DataTable.Cell>{order.orderId}</DataTable.Cell>
                <DataTable.Cell>{order.customer}</DataTable.Cell>
                <DataTable.Cell numeric>₹{order.amount}</DataTable.Cell>
                <DataTable.Cell>
                  <Chip 
                    style={[styles.statusChip, { backgroundColor: getStatusColor(order.status) + '20' }]}
                    textStyle={{ color: getStatusColor(order.status) }}
                  >
                    {order.status}
                  </Chip>
                </DataTable.Cell>
              </DataTable.Row>
            ))}
          </DataTable>
        </Card.Content>
      </Card>

      {/* Actions */}
      <Card style={styles.card}>
        <Card.Content>
          <Text variant="titleMedium" style={styles.sectionTitle}>
            Quick Actions
          </Text>
          
          <Button
            mode="contained"
            onPress={() => Alert.alert('Feature', 'Manage users feature coming soon')}
            style={styles.actionButton}
            icon="account-group"
          >
            {t('admin.manageUsers')}
          </Button>
          
          <Button
            mode="outlined"
            onPress={() => Alert.alert('Feature', 'Manage products feature coming soon')}
            style={styles.actionButton}
            icon="package-variant"
          >
            {t('admin.manageProducts')}
          </Button>
          
          <Button
            mode="outlined"
            onPress={() => Alert.alert('Feature', 'Analytics feature coming soon')}
            style={styles.actionButton}
            icon="chart-line"
          >
            {t('admin.analytics')}
          </Button>
        </Card.Content>
      </Card>
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
  title: {
    fontWeight: 'bold',
    color: '#2E7D32',
    marginBottom: 4,
  },
  subtitle: {
    color: '#666',
  },
  sectionTitle: {
    fontWeight: 'bold',
    color: '#2E7D32',
    marginBottom: 12,
  },
  statsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
  },
  statItem: {
    alignItems: 'center',
  },
  statNumber: {
    fontWeight: 'bold',
    color: '#FF6F00',
  },
  statusChip: {
    borderRadius: 16,
  },
  actionButton: {
    marginBottom: 8,
  },
});
