import React, { useMemo, useState } from 'react';
import { View, StyleSheet, Alert, ScrollView, KeyboardAvoidingView, Platform, Pressable } from 'react-native';
import { Text, TextInput, Button, HelperText } from 'react-native-paper';
import { useDispatch, useSelector } from 'react-redux';
import { useTranslation } from 'react-i18next';
import { NavigationProp, RouteProp, useNavigation, useRoute } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';

import { RootState, AppDispatch } from '../store';
import { login, clearError } from '../store/authSlice';
import { RootStackParamList } from '../navigation/types';

export default function LoginScreen() {
  const { t } = useTranslation();
  const navigation = useNavigation<NavigationProp<RootStackParamList>>();
  const route = useRoute<RouteProp<RootStackParamList, 'Login'>>();
  const dispatch = useDispatch<AppDispatch>();
  
  const { isLoading, error } = useSelector((state: RootState) => state.auth);

  const [mode, setMode] = useState<'customer' | 'vendor'>(route.params?.mode ?? 'customer');
  const [identifier, setIdentifier] = useState('');
  const [password, setPassword] = useState('');

  const accent = mode === 'vendor' ? '#227A3B' : '#1667D9';
  const accentSoft = mode === 'vendor' ? '#E8F5E9' : '#EAF3FF';
  const accentDark = mode === 'vendor' ? '#0D4F23' : '#0F3D91';
  const modeLabel = mode === 'vendor' ? 'Vendor Portal' : 'Customer Login';
  const subtitle =
    mode === 'vendor'
      ? 'Manage your shop, orders, and hygiene checks in one place.'
      : 'Discover trusted local sellers, home chefs, and neighborhood favorites.';
  const identifierLabel = mode === 'vendor' ? 'Vendor email or mobile' : 'Mobile number or Gmail';
  const sampleCreds = useMemo(
    () =>
      mode === 'vendor'
        ? {
            identifier: '9876543212',
            password: 'password123',
            label: 'Vendor sample',
            secondary: 'Phone: 9876543212',
            tertiary: 'Email: jane@example.com',
          }
        : {
            identifier: '9876543211',
            password: 'password123',
            label: 'Customer sample',
            secondary: 'Phone: 9876543211',
            tertiary: 'Email: john@example.com',
          },
    [mode]
  );

  const handleLogin = async () => {
    if (!identifier.trim() || !password.trim()) {
      Alert.alert(t('common.error'), 'Please fill in all fields');
      return;
    }

    try {
      await dispatch(login({ identifier, password })).unwrap();
    } catch (error) {
      // Error is handled by the slice
    }
  };

  const handleRegister = () => {
    navigation.navigate('Register', { mode });
  };

  const handleUseSample = () => {
    setIdentifier(sampleCreds.identifier);
    setPassword(sampleCreds.password);
  };

  React.useEffect(() => {
    if (error) {
      Alert.alert(t('common.error'), error);
      dispatch(clearError());
    }
  }, [error]);

  React.useEffect(() => {
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
          <View style={[styles.orbLarge, { backgroundColor: accentDark }]} />
          <View style={[styles.orbSmall, { backgroundColor: accentSoft }]} />
          <Text style={styles.brand}>Tiny Trail</Text>
          <Text style={styles.modeLabel}>{modeLabel}</Text>
          <Text style={styles.subtitle}>{subtitle}</Text>
        </View>

        <View style={[styles.panel, { borderColor: accentSoft }]}>
          <View style={[styles.toggleShell, { backgroundColor: accentSoft }]}>
            <Button
              mode={mode === 'customer' ? 'contained' : 'text'}
              onPress={() => setMode('customer')}
              buttonColor={mode === 'customer' ? '#1667D9' : 'transparent'}
              textColor={mode === 'customer' ? '#FFFFFF' : '#1667D9'}
              style={styles.toggleButton}
              icon="account"
            >
              Customer
            </Button>
            <Button
              mode={mode === 'vendor' ? 'contained' : 'text'}
              onPress={() => setMode('vendor')}
              buttonColor={mode === 'vendor' ? '#227A3B' : 'transparent'}
              textColor={mode === 'vendor' ? '#FFFFFF' : '#227A3B'}
              style={styles.toggleButton}
              icon="storefront"
            >
              Vendor
            </Button>
          </View>

          <View style={styles.cardHeader}>
            <Ionicons name={mode === 'vendor' ? 'leaf' : 'sparkles'} size={24} color={accent} />
            <Text style={[styles.cardTitle, { color: accentDark }]}>Sign in beautifully</Text>
          </View>

          <Text style={styles.cardDescription}>
            {mode === 'vendor'
              ? 'Use your seller account to open the vendor dashboard.'
              : 'Use your buyer account to explore products and place orders.'}
          </Text>

          <Pressable onPress={handleUseSample} style={[styles.sampleCard, { backgroundColor: accentSoft }]}>
            <View style={[styles.sampleBadge, { backgroundColor: accent }]}>
              <Ionicons name={mode === 'vendor' ? 'storefront' : 'person'} size={14} color="#FFFFFF" />
            </View>
            <View style={styles.sampleContent}>
              <Text style={[styles.sampleTitle, { color: accentDark }]}>{sampleCreds.label}</Text>
              <Text style={styles.sampleLine}>{sampleCreds.secondary}</Text>
              <Text style={styles.sampleLine}>{sampleCreds.tertiary}</Text>
              <Text style={styles.samplePassword}>Password: {sampleCreds.password}</Text>
            </View>
          </Pressable>

          <Button
            mode="outlined"
            onPress={handleUseSample}
            style={[styles.sampleButton, { borderColor: accent }]}
            textColor={accent}
            icon="flash"
          >
            Autofill sample credentials
          </Button>

          <HelperText type="info" style={styles.helper}>
            You can login with phone number, Gmail, or username.
          </HelperText>

          <TextInput
            label={identifierLabel}
            value={identifier}
            onChangeText={setIdentifier}
            style={styles.input}
            mode="outlined"
            autoCapitalize="none"
            outlineColor="#D9E3F0"
            activeOutlineColor={accent}
            left={<TextInput.Icon icon="email-outline" color={accent} />}
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
            left={<TextInput.Icon icon="lock-outline" color={accent} />}
          />

          <Button onPress={() => Alert.alert('Forgot password', 'Password reset can be connected next.')} textColor={accent}>
            Forgot password?
          </Button>

          <Button
            mode="contained"
            onPress={handleLogin}
            style={[styles.loginButton, { backgroundColor: accent }]}
            loading={isLoading}
            disabled={isLoading}
            icon={mode === 'vendor' ? 'storefront' : 'login'}
          >
            {mode === 'vendor' ? 'Open vendor login' : 'Login as customer'}
          </Button>

          <View style={styles.footerRow}>
            <Text style={styles.footerText}>New here?</Text>
            <Button
              mode="text"
              onPress={handleRegister}
              textColor={accent}
            >
              {mode === 'vendor' ? 'Create vendor account' : 'Sign up'}
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
    overflow: 'hidden',
    marginTop: 8,
    justifyContent: 'flex-end',
  },
  orbLarge: {
    position: 'absolute',
    width: 200,
    height: 200,
    borderRadius: 999,
    top: -70,
    right: -50,
    opacity: 0.28,
  },
  orbSmall: {
    position: 'absolute',
    width: 120,
    height: 120,
    borderRadius: 999,
    bottom: 30,
    right: 40,
    opacity: 0.18,
  },
  brand: {
    color: '#FFFFFF',
    fontSize: 18,
    fontWeight: '700',
    marginBottom: 10,
    letterSpacing: 0.8,
  },
  modeLabel: {
    color: '#FFFFFF',
    fontSize: 34,
    fontWeight: '800',
    lineHeight: 40,
  },
  subtitle: {
    color: '#EAF2FF',
    fontSize: 15,
    lineHeight: 22,
    marginTop: 10,
    maxWidth: '84%',
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
  toggleShell: {
    flexDirection: 'row',
    borderRadius: 18,
    padding: 4,
    marginBottom: 22,
  },
  toggleButton: {
    flex: 1,
  },
  cardHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  cardTitle: {
    fontSize: 24,
    fontWeight: '800',
  },
  cardDescription: {
    color: '#5E6A7D',
    fontSize: 14,
    lineHeight: 21,
    marginTop: 10,
    marginBottom: 14,
  },
  sampleButton: {
    borderRadius: 14,
    marginBottom: 6,
  },
  sampleCard: {
    borderRadius: 18,
    padding: 14,
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 12,
    marginBottom: 10,
  },
  sampleBadge: {
    width: 28,
    height: 28,
    borderRadius: 999,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 2,
  },
  sampleContent: {
    flex: 1,
  },
  sampleTitle: {
    fontSize: 16,
    fontWeight: '800',
    marginBottom: 4,
  },
  sampleLine: {
    color: '#56657A',
    fontSize: 13,
    marginBottom: 2,
  },
  samplePassword: {
    color: '#243042',
    fontSize: 13,
    fontWeight: '700',
    marginTop: 4,
  },
  helper: {
    marginBottom: 10,
    color: '#6C7A8E',
  },
  input: {
    marginBottom: 16,
    backgroundColor: '#FFFFFF',
  },
  loginButton: {
    marginTop: 6,
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
