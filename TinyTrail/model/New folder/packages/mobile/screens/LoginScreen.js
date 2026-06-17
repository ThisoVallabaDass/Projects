import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  Alert,
  ScrollView,
  SafeAreaView,
} from 'react-native';
import axios from 'axios';
import Icon from '../components/Icon';

const API_URL = 'http://localhost:8080/api';

export default function LoginScreen({ navigation }) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);

  const handleLogin = async () => {
    if (!username || !password) {
      Alert.alert('Error', 'Please enter username and password');
      return;
    }

    setLoading(true);
    try {
      const response = await axios.post(`${API_URL}/auth/login`, {
        username,
        password,
      });

      global.tinytrailToken = response.data.token;
      global.tinytrailUser = response.data.user;

      // Navigate to home (in real app, would update App.js state)
      setUsername('');
      setPassword('');
      Alert.alert('Success', 'Logged in successfully!');
    } catch (error) {
      Alert.alert('Error', error.response?.data?.error || 'Login failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView contentContainerStyle={styles.scrollContent}>
        <View style={styles.header}>
          <Icon name="shopping-cart" size={50} color="#16a34a" />
          <Text style={styles.title}>TinyTrail</Text>
          <Text style={styles.subtitle}>Local Marketplace</Text>
        </View>

        <View style={styles.form}>
          <View style={styles.inputGroup}>
            <Icon name="user" size={20} color="#999" style={styles.icon} />
            <TextInput
              style={styles.input}
              placeholder="Username"
              value={username}
              onChangeText={setUsername}
              editable={!loading}
            />
          </View>

          <View style={styles.inputGroup}>
            <Icon name="lock" size={20} color="#999" style={styles.icon} />
            <TextInput
              style={styles.input}
              placeholder="Password"
              value={password}
              onChangeText={setPassword}
              secureTextEntry
              editable={!loading}
            />
          </View>

          <TouchableOpacity
            style={[styles.button, loading && styles.buttonDisabled]}
            onPress={handleLogin}
            disabled={loading}
          >
            {loading ? (
              <ActivityIndicator color="#fff" />
            ) : (
              <Text style={styles.buttonText}>Login</Text>
            )}
          </TouchableOpacity>

          <TouchableOpacity onPress={() => navigation.navigate('Register')}>
            <Text style={styles.registerLink}>
              Don't have an account? <Text style={styles.registerLinkBold}>Register</Text>
            </Text>
          </TouchableOpacity>
        </View>

        <View style={styles.demo}>
          <Text style={styles.demoTitle}>Demo Credentials:</Text>
          <Text style={styles.demoText}>admin / password123</Text>
          <Text style={styles.demoText}>john_buyer / password123</Text>
          <Text style={styles.demoText}>jane_seller / password123</Text>
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
  scrollContent: {
    flexGrow: 1,
    justifyContent: 'center',
    padding: 20,
  },
  header: {
    alignItems: 'center',
    marginBottom: 40,
  },
  title: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#16a34a',
    marginTop: 10,
  },
  subtitle: {
    fontSize: 16,
    color: '#666',
    marginTop: 5,
  },
  form: {
    backgroundColor: '#fff',
    padding: 20,
    borderRadius: 10,
    marginBottom: 30,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 3.84,
    elevation: 5,
  },
  inputGroup: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#f5f5f5',
    borderRadius: 8,
    marginBottom: 15,
    paddingHorizontal: 15,
  },
  icon: {
    marginRight: 10,
  },
  input: {
    flex: 1,
    paddingVertical: 12,
    fontSize: 16,
  },
  button: {
    backgroundColor: '#16a34a',
    paddingVertical: 14,
    borderRadius: 8,
    alignItems: 'center',
    marginBottom: 15,
  },
  buttonDisabled: {
    backgroundColor: '#ccc',
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
  },
  registerLink: {
    textAlign: 'center',
    color: '#666',
  },
  registerLinkBold: {
    color: '#16a34a',
    fontWeight: 'bold',
  },
  demo: {
    backgroundColor: '#e0f7f4',
    padding: 15,
    borderRadius: 8,
    marginBottom: 20,
  },
  demoTitle: {
    fontWeight: 'bold',
    color: '#047857',
    marginBottom: 8,
  },
  demoText: {
    color: '#047857',
    fontSize: 13,
    marginBottom: 4,
  },
});
