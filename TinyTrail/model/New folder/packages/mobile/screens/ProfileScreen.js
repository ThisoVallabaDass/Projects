import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
  Alert,
  ScrollView,
} from 'react-native';
import Icon from '../components/Icon';

export default function ProfileScreen({ navigation }) {
  const [user, setUser] = useState(null);

  useEffect(() => {
    loadUserData();
  }, []);

  const loadUserData = () => {
    if (global.tinytrailUser) {
      setUser(global.tinytrailUser);
    }
  };

  const handleLogout = () => {
    Alert.alert('Logout', 'Are you sure you want to logout?', [
      {
        text: 'Cancel',
        onPress: () => {},
        style: 'cancel',
      },
      {
        text: 'Logout',
        onPress: () => {
          global.tinytrailToken = null;
          global.tinytrailUser = null;
          navigation.reset({
            index: 0,
            routes: [{ name: 'Login' }],
          });
        },
        style: 'destructive',
      },
    ]);
  };

  if (!user) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.loadingContainer}>
          <Text style={styles.loadingText}>Loading profile...</Text>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView contentContainerStyle={styles.content}>
        {/* User Avatar Section */}
        <View style={styles.avatarSection}>
          <View style={styles.avatar}>
            <Icon name="user-circle" size={60} color="#16a34a" />
          </View>
          <Text style={styles.userName}>{user.username}</Text>
          <Text style={styles.userEmail}>{user.email || 'No email'}</Text>
        </View>

        {/* User Info Cards */}
        <View style={styles.infoSection}>
          <View style={styles.infoCard}>
            <View style={styles.infoCardLeft}>
              <Icon name="envelope" size={20} color="#16a34a" />
              <View style={styles.infoCardContent}>
                <Text style={styles.infoCardLabel}>Email</Text>
                <Text style={styles.infoCardValue}>{user.email || 'N/A'}</Text>
              </View>
            </View>
            <Icon name="chevron-right" size={16} color="#ccc" />
          </View>

          <View style={styles.infoCard}>
            <View style={styles.infoCardLeft}>
              <Icon name="phone" size={20} color="#16a34a" />
              <View style={styles.infoCardContent}>
                <Text style={styles.infoCardLabel}>Phone</Text>
                <Text style={styles.infoCardValue}>{user.phone || 'N/A'}</Text>
              </View>
            </View>
            <Icon name="chevron-right" size={16} color="#ccc" />
          </View>

          <View style={styles.infoCard}>
            <View style={styles.infoCardLeft}>
              <Icon name="map-marker" size={20} color="#16a34a" />
              <View style={styles.infoCardContent}>
                <Text style={styles.infoCardLabel}>Pincode</Text>
                <Text style={styles.infoCardValue}>{user.pincode || '600001'}</Text>
              </View>
            </View>
            <Icon name="chevron-right" size={16} color="#ccc" />
          </View>

          <View style={styles.infoCard}>
            <View style={styles.infoCardLeft}>
              <Icon name="user-tag" size={20} color="#16a34a" />
              <View style={styles.infoCardContent}>
                <Text style={styles.infoCardLabel}>Account Type</Text>
                <Text style={styles.infoCardValue}>{user.role || 'Buyer'}</Text>
              </View>
            </View>
            <Icon name="chevron-right" size={16} color="#ccc" />
          </View>
        </View>

        {/* Action Buttons */}
        <View style={styles.actionSection}>
          <TouchableOpacity style={styles.actionButton}>
            <Icon name="map-o" size={18} color="#16a34a" />
            <Text style={styles.actionButtonText}>Saved Addresses</Text>
            <Icon name="chevron-right" size={16} color="#ccc" />
          </TouchableOpacity>

          <TouchableOpacity style={styles.actionButton}>
            <Icon name="heart-o" size={18} color="#16a34a" />
            <Text style={styles.actionButtonText}>Wishlist</Text>
            <Icon name="chevron-right" size={16} color="#ccc" />
          </TouchableOpacity>

          <TouchableOpacity style={styles.actionButton}>
            <Icon name="star-o" size={18} color="#16a34a" />
            <Text style={styles.actionButtonText}>My Ratings & Reviews</Text>
            <Icon name="chevron-right" size={16} color="#ccc" />
          </TouchableOpacity>

          <TouchableOpacity style={styles.actionButton}>
            <Icon name="bell-o" size={18} color="#16a34a" />
            <Text style={styles.actionButtonText}>Notifications</Text>
            <Icon name="chevron-right" size={16} color="#ccc" />
          </TouchableOpacity>
        </View>

        {/* Seller Section */}
        {user.role === 'seller' && (
          <View style={styles.sellerSection}>
            <TouchableOpacity style={styles.sellerButton}>
              <Icon name="store" size={18} color="#fff" />
              <Text style={styles.sellerButtonText}>Manage Shop</Text>
            </TouchableOpacity>
          </View>
        )}

        {user.role !== 'seller' && (
          <View style={styles.sellerSection}>
            <TouchableOpacity style={styles.sellerButton}>
              <Icon name="briefcase" size={18} color="#fff" />
              <Text style={styles.sellerButtonText}>Become a Seller</Text>
            </TouchableOpacity>
          </View>
        )}

        {/* Settings and Support */}
        <View style={styles.settingsSection}>
          <TouchableOpacity style={styles.settingsButton}>
            <Icon name="cog" size={18} color="#16a34a" />
            <Text style={styles.settingsButtonText}>Settings</Text>
            <Icon name="chevron-right" size={16} color="#ccc" />
          </TouchableOpacity>

          <TouchableOpacity style={styles.settingsButton}>
            <Icon name="question-circle" size={18} color="#16a34a" />
            <Text style={styles.settingsButtonText}>Help & Support</Text>
            <Icon name="chevron-right" size={16} color="#ccc" />
          </TouchableOpacity>

          <TouchableOpacity style={styles.settingsButton}>
            <Icon name="info-circle" size={18} color="#16a34a" />
            <Text style={styles.settingsButtonText}>About TinyTrail</Text>
            <Icon name="chevron-right" size={16} color="#ccc" />
          </TouchableOpacity>
        </View>

        {/* Logout Button */}
        <TouchableOpacity
          style={styles.logoutButton}
          onPress={handleLogout}
        >
          <Icon name="sign-out" size={18} color="#dc2626" />
          <Text style={styles.logoutButtonText}>Logout</Text>
        </TouchableOpacity>

        {/* Footer */}
        <View style={styles.footer}>
          <Text style={styles.footerText}>TinyTrail v1.0.0</Text>
          <Text style={styles.footerSubText}>© 2024 All rights reserved</Text>
        </View>
      </ScrollView>
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
  loadingText: {
    color: '#999',
  },
  content: {
    padding: 15,
  },
  avatarSection: {
    alignItems: 'center',
    marginBottom: 30,
    paddingVertical: 20,
    backgroundColor: '#fff',
    borderRadius: 12,
  },
  avatar: {
    marginBottom: 12,
  },
  userName: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#333',
  },
  userEmail: {
    fontSize: 14,
    color: '#999',
    marginTop: 4,
  },
  infoSection: {
    marginBottom: 20,
  },
  infoCard: {
    backgroundColor: '#fff',
    borderRadius: 8,
    padding: 15,
    marginBottom: 10,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  infoCardLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  infoCardContent: {
    marginLeft: 12,
    flex: 1,
  },
  infoCardLabel: {
    fontSize: 12,
    color: '#999',
    marginBottom: 4,
  },
  infoCardValue: {
    fontSize: 14,
    fontWeight: '600',
    color: '#333',
  },
  actionSection: {
    marginBottom: 20,
  },
  actionButton: {
    backgroundColor: '#fff',
    borderRadius: 8,
    padding: 15,
    marginBottom: 10,
    flexDirection: 'row',
    alignItems: 'center',
  },
  actionButtonText: {
    fontSize: 14,
    color: '#333',
    fontWeight: '500',
    flex: 1,
    marginLeft: 12,
  },
  sellerSection: {
    marginBottom: 20,
  },
  sellerButton: {
    backgroundColor: '#16a34a',
    borderRadius: 8,
    paddingVertical: 14,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  sellerButtonText: {
    color: '#fff',
    fontWeight: 'bold',
    fontSize: 14,
    marginLeft: 10,
  },
  settingsSection: {
    marginBottom: 20,
  },
  settingsButton: {
    backgroundColor: '#fff',
    borderRadius: 8,
    padding: 15,
    marginBottom: 10,
    flexDirection: 'row',
    alignItems: 'center',
  },
  settingsButtonText: {
    fontSize: 14,
    color: '#333',
    fontWeight: '500',
    flex: 1,
    marginLeft: 12,
  },
  logoutButton: {
    backgroundColor: '#fef2f2',
    borderWidth: 1,
    borderColor: '#dc2626',
    borderRadius: 8,
    paddingVertical: 14,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 20,
  },
  logoutButtonText: {
    color: '#dc2626',
    fontWeight: 'bold',
    fontSize: 14,
    marginLeft: 10,
  },
  footer: {
    alignItems: 'center',
    paddingVertical: 15,
  },
  footerText: {
    fontSize: 12,
    color: '#999',
  },
  footerSubText: {
    fontSize: 11,
    color: '#bbb',
    marginTop: 4,
  },
});
