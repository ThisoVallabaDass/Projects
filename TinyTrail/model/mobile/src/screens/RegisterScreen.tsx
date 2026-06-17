import React, { useEffect, useState } from 'react';
import { View, StyleSheet, Alert, ScrollView, KeyboardAvoidingView, Platform } from 'react-native';
import { Text, TextInput, Button, HelperText } from 'react-native-paper';
import { useDispatch, useSelector } from 'react-redux';
import { useTranslation } from 'react-i18next';
import { NavigationProp, RouteProp, useNavigation, useRoute } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';

import { RootState, AppDispatch } from '../store';
import { register, clearError } from '../store/authSlice';
import { RootStackParamList } from '../navigation/types';

export default function RegisterScreen() {
  const { t } = useTranslation();
  const navigation = useNavigation<NavigationProp<RootStackParamList>>();
  const route = useRoute<RouteProp<RootStackParamList, 'Register'>>();
  const dispatch = useDispatch<AppDispatch>();
  
  const { isLoading, error } = useSelector((state: RootState) => state.auth);

  const [mode, setMode] = useState<'customer' | 'vendor'>(route.params?.mode ?? 'customer');
  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');

  const accent = mode === 'vendor' ? '#227A3B' : '#1667D9';
  const accentSoft = mode === 'vendor' ? '#E8F5E9' : '#EAF3FF';
  const accentDark = mode === 'vendor' ? '#0D4F23' : '#0F3D91';

  const handleRegister = async () => {
    if (!username.trim() || !email.trim() || !phone.trim() || !password.trim()) {
      Alert.alert(t('common.error'), 'Please fill in all fields');
      return;
    }

    if (password !== confirmPassword) {
      Alert.alert(t('common.error'), 'Passwords do not match');
      return;
    }

    if (password.length < 6) {
      Alert.alert(t('common.error'), 'Password must be at least 6 characters');
      return;
    }

    try {
      await dispatch(
        register({
          username,
          email,
          phone,
          password,
          role: mode === 'vendor' ? 'SELLER' : 'BUYER',
        })
      ).unwrap();
      navigation.goBack();
    } catch (error) {
      // Error is handled by the slice
    }
  };

  const handleLogin = () => {
    navigation.navigate('Login', { mode });
  };

  useEffect(() => {
    if (error) {
      Alert.alert(t('common.error'), error);
      dispatch(clearError());
    }
  }, [error]);

  useEffect(() => {
    if (route.params?.mode) {
      setMode(route.params.mode);
    }
  }, [route.params?.mode]);

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      keyboardVerticalOffset={Platform.OS === 'ios' ? 24 : 0}
    >
      <ScrollView
        style={styles.container}
        contentContainerStyle={styles.content}
        keyboardShouldPersistTaps="handled"
      >
        <View style={[styles.hero, { backgroundColor: accent }]}>
          <Text style={styles.brand}>Tiny Trail</Text>
          <Text style={styles.title}>{mode === 'vendor' ? 'Build your vendor identity' : 'Create your customer account'}</Text>
          <Text style={styles.subtitle}>
            {mode === 'vendor'
              ? 'Set up a seller profile that feels professional and trusted.'
              : 'Save favorites, place orders faster, and track your local finds.'}
          </Text>
        </View>

        <View style={[styles.panel, { borderColor: accentSoft }]}>
          <View style={[styles.modeChip, { backgroundColor: accentSoft }]}>
            <Ionicons name={mode === 'vendor' ? 'storefront' : 'person'} size={16} color={accent} />
            <Text style={[styles.modeChipText, { color: accentDark }]}>
              {mode === 'vendor' ? 'Vendor signup' : 'Customer signup'}
            </Text>
          </View>

          <HelperText type="info" style={styles.helper}>
            {mode === 'vendor'
              ? 'You can continue to the vendor tools after signup.'
              : 'This creates a buyer account by default.'}
          </HelperText>

          <TextInput
            label="Full name or username"
            value={username}
            onChangeText={setUsername}
            style={styles.input}
            mode="outlined"
            autoCapitalize="none"
            outlineColor="#D9E3F0"
            activeOutlineColor={accent}
          />

          <TextInput
            label="Gmail address"
            value={email}
            onChangeText={setEmail}
            style={styles.input}
            mode="outlined"
            keyboardType="email-address"
            autoCapitalize="none"
            outlineColor="#D9E3F0"
            activeOutlineColor={accent}
          />

          <TextInput
            label="Mobile number"
            value={phone}
            onChangeText={setPhone}
            style={styles.input}
            mode="outlined"
            keyboardType="phone-pad"
            outlineColor="#D9E3F0"
            activeOutlineColor={accent}
          />

          <TextInput
            label="Password"
            value={password}
            onChangeText={setPassword}
            style={styles.input}
            mode="outlined"
            secureTextEntry
            outlineColor="#D9E3F0"
            activeOutlineColor={accent}
          />

          <TextInput
            label="Confirm password"
            value={confirmPassword}
            onChangeText={setConfirmPassword}
            style={styles.input}
            mode="outlined"
            secureTextEntry
            outlineColor="#D9E3F0"
            activeOutlineColor={accent}
          />

          <Button
            mode="contained"
            onPress={handleRegister}
            style={[styles.registerButton, { backgroundColor: accent }]}
            loading={isLoading}
            disabled={isLoading}
            icon={mode === 'vendor' ? 'storefront-plus' : 'account-plus'}
          >
            {mode === 'vendor' ? 'Create vendor account' : 'Create customer account'}
          </Button>

          <View style={styles.footerRow}>
            <Text style={styles.footerText}>Already have an account?</Text>
            <Button
              mode="text"
              onPress={handleLogin}
              textColor={accent}
            >
              Back to login
            </Button>
          </View>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F6F8FC',
  },
  content: {
    padding: 20,
    paddingBottom: 32,
  },
  hero: {
    borderRadius: 28,
    padding: 22,
    minHeight: 180,
    justifyContent: 'flex-end',
  },
  brand: {
    color: '#FFFFFF',
    fontSize: 18,
    fontWeight: '700',
    marginBottom: 8,
  },
  title: {
    color: '#FFFFFF',
    fontSize: 30,
    fontWeight: '800',
    lineHeight: 36,
  },
  subtitle: {
    color: '#EEF4FF',
    marginTop: 10,
    fontSize: 15,
    lineHeight: 22,
  },
  panel: {
    marginTop: -20,
    backgroundColor: '#FFFFFF',
    borderRadius: 28,
    padding: 22,
    borderWidth: 1,
    shadowColor: '#0F172A',
    shadowOpacity: 0.08,
    shadowRadius: 16,
    shadowOffset: { width: 0, height: 8 },
    elevation: 5,
  },
  modeChip: {
    flexDirection: 'row',
    alignSelf: 'flex-start',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 999,
    gap: 8,
  },
  modeChipText: {
    fontWeight: '700',
  },
  helper: {
    marginBottom: 12,
    color: '#6C7A8E',
  },
  input: {
    marginBottom: 16,
    backgroundColor: '#FFFFFF',
  },
  registerButton: {
    marginTop: 8,
    borderRadius: 16,
    paddingVertical: 6,
  },
  footerRow: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 10,
  },
  footerText: {
    color: '#6C7A8E',
  },
});
