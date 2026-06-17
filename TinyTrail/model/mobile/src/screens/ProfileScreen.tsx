import React, { useState } from 'react';
import { View, StyleSheet, ScrollView, Alert } from 'react-native';
import { Text, Card, Button, Switch, List, Divider } from 'react-native-paper';
import { useDispatch, useSelector } from 'react-redux';
import { useTranslation } from 'react-i18next';
import { NavigationProp, useNavigation } from '@react-navigation/native';

import { RootState, AppDispatch } from '../store';
import { logout } from '../store/authSlice';
import { RootStackParamList } from '../navigation/types';

export default function ProfileScreen() {
  const { t } = useTranslation();
  const navigation = useNavigation<NavigationProp<RootStackParamList>>();
  const dispatch = useDispatch<AppDispatch>();
  
  const { user } = useSelector((state: RootState) => state.auth);

  const [notificationsEnabled, setNotificationsEnabled] = useState(true);
  const [currentLanguage, setCurrentLanguage] = useState('en');

  const handleLogout = () => {
    Alert.alert(
      t('auth.logout'),
      'Are you sure you want to logout?',
      [
        { text: t('common.cancel'), style: 'cancel' },
        { 
          text: t('auth.logout'), 
          style: 'destructive',
          onPress: () => {
            dispatch(logout());
            navigation.navigate('Login');
          }
        }
      ]
    );
  };

  const handleLanguageChange = () => {
    const newLanguage = currentLanguage === 'en' ? 'ta' : 'en';
    setCurrentLanguage(newLanguage);
    // In a real app, you would update the i18n language here
    Alert.alert('Language Changed', `Language changed to ${newLanguage === 'en' ? 'English' : 'Tamil'}`);
  };

  const handleAdminPanel = () => {
    if (user?.role === 'ADMIN') {
      navigation.navigate('AdminPanel');
    } else {
      Alert.alert('Access Denied', 'Admin access required');
    }
  };

  return (
    <ScrollView style={styles.container}>
      {/* User Info */}
      <Card style={styles.card}>
        <Card.Content>
          <Text variant="headlineSmall" style={styles.userName}>
            {user?.username || 'Guest User'}
          </Text>
          <Text variant="bodyMedium" style={styles.userEmail}>
            {user?.email || 'Not logged in'}
          </Text>
          <Text variant="bodySmall" style={styles.userRole}>
            Role: {user?.role || 'GUEST'}
          </Text>
        </Card.Content>
      </Card>

      {/* Settings */}
      <Card style={styles.card}>
        <Card.Content>
          <Text variant="titleMedium" style={styles.sectionTitle}>
            {t('profile.settings')}
          </Text>
          
          <List.Item
            title={t('profile.language')}
            description={currentLanguage === 'en' ? 'English' : 'Tamil'}
            left={(props) => <List.Icon {...props} icon="translate" />}
            right={(props) => (
              <Button mode="outlined" onPress={handleLanguageChange}>
                Switch
              </Button>
            )}
          />
          
          <List.Item
            title={t('profile.notifications')}
            description="Push notifications"
            left={(props) => <List.Icon {...props} icon="bell" />}
            right={() => (
              <Switch
                value={notificationsEnabled}
                onValueChange={setNotificationsEnabled}
              />
            )}
          />
        </Card.Content>
      </Card>

      {/* Actions */}
      <Card style={styles.card}>
        <Card.Content>
          <Text variant="titleMedium" style={styles.sectionTitle}>
            Actions
          </Text>
          
          {!user && (
            <Button
              mode="contained"
              onPress={() => navigation.navigate('Login')}
              style={styles.actionButton}
              icon="login"
            >
              {t('auth.login')}
            </Button>
          )}
          
          {!user && (
            <Button
              mode="outlined"
              onPress={() => navigation.navigate('Register')}
              style={styles.actionButton}
              icon="account-plus"
            >
              {t('auth.register')}
            </Button>
          )}
          
          {user && (
            <Button
              mode="outlined"
              onPress={() => navigation.navigate('SellerOnboard')}
              style={styles.actionButton}
              icon="store"
            >
              {t('seller.becomeSeller')}
            </Button>
          )}
          
          {user?.role === 'ADMIN' && (
            <Button
              mode="contained"
              onPress={handleAdminPanel}
              style={styles.actionButton}
              icon="shield-account"
            >
              {t('admin.adminPanel')}
            </Button>
          )}
          
          {user && (
            <Button
              mode="outlined"
              onPress={handleLogout}
              style={[styles.actionButton, styles.logoutButton]}
              icon="logout"
              buttonColor="#D32F2F"
              textColor="white"
            >
              {t('auth.logout')}
            </Button>
          )}
        </Card.Content>
      </Card>

      {/* App Info */}
      <Card style={styles.card}>
        <Card.Content>
          <Text variant="titleMedium" style={styles.sectionTitle}>
            {t('profile.about')}
          </Text>
          
          <List.Item
            title="Tiny Trail"
            description="Local marketplace app"
            left={(props) => <List.Icon {...props} icon="store" />}
          />
          
          <List.Item
            title={t('profile.version')}
            description="1.0.0"
            left={(props) => <List.Icon {...props} icon="information" />}
          />
          
          <Button
            mode="text"
            onPress={() => Alert.alert('Help', 'Contact support for assistance')}
            style={styles.helpButton}
            icon="help-circle"
          >
            {t('profile.help')}
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
  userName: {
    fontWeight: 'bold',
    color: '#2E7D32',
    marginBottom: 4,
  },
  userEmail: {
    color: '#666',
    marginBottom: 4,
  },
  userRole: {
    color: '#999',
    textTransform: 'uppercase',
    fontWeight: '500',
  },
  sectionTitle: {
    fontWeight: 'bold',
    color: '#2E7D32',
    marginBottom: 12,
  },
  actionButton: {
    marginBottom: 8,
  },
  logoutButton: {
    marginTop: 8,
  },
  helpButton: {
    marginTop: 8,
  },
});
