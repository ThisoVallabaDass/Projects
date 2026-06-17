import React, { useState, useEffect } from 'react';
import { View, StyleSheet, ScrollView, Alert, Image } from 'react-native';
import { Text, Card, TextInput, Button, Divider } from 'react-native-paper';
import { useDispatch, useSelector } from 'react-redux';
import { useTranslation } from 'react-i18next';
import { NavigationProp, useNavigation } from '@react-navigation/native';
import * as ImagePicker from 'expo-image-picker';

import { RootState, AppDispatch } from '../store';
import { createProduct } from '../store/productsSlice';
import VoiceInputButton from '../components/VoiceInputButton';
import { RootStackParamList } from '../navigation/types';
import client from '../api/client';

interface HygieneResult {
  hygiene_score: number;
  badge_text: string;
  predicted_class: string;
  confidence: number;
}

export default function SellerOnboardScreen() {
  const { t } = useTranslation();
  const navigation = useNavigation<NavigationProp<RootStackParamList>>();
  const dispatch = useDispatch<AppDispatch>();
  
  const { user } = useSelector((state: RootState) => state.auth);
  const { isLoading } = useSelector((state: RootState) => state.products);

  const [shopName, setShopName] = useState('');
  const [address, setAddress] = useState('');
  const [pincode, setPincode] = useState('');
  const [description, setDescription] = useState('');
  const [productName, setProductName] = useState('');
  const [productDescription, setProductDescription] = useState('');
  const [productPrice, setProductPrice] = useState('');
  const [productImage, setProductImage] = useState<ImagePicker.ImagePickerAsset | null>(null);
  const [workspaceImage, setWorkspaceImage] = useState<ImagePicker.ImagePickerAsset | null>(null);
  const [hygieneResult, setHygieneResult] = useState<HygieneResult | null>(null);
  const [vendorId, setVendorId] = useState<number | null>(null);
  const [isCheckingHygiene, setIsCheckingHygiene] = useState(false);
  const [isOnboarded, setIsOnboarded] = useState(false);

  useEffect(() => {
    const loadVendorProfile = async () => {
      if (user?.role !== 'SELLER') {
        return;
      }

      try {
        const response = await client.get('/vendors/me');
        setIsOnboarded(true);
        setVendorId(response.data.id);
        setShopName(response.data.shop_name || '');
        setAddress(response.data.address || '');
        setPincode(response.data.pincode || '');
        setDescription(response.data.story_text || '');
        if (response.data.latest_hygiene) {
          setHygieneResult(response.data.latest_hygiene);
        }
      } catch (_error) {
        setIsOnboarded(false);
      }
    };

    loadVendorProfile();
  }, [user]);

  const handleImagePicker = async () => {
    const permissionResult = await ImagePicker.requestMediaLibraryPermissionsAsync();
    
    if (permissionResult.granted === false) {
      Alert.alert('Permission Required', 'Permission to access camera roll is required!');
      return;
    }

    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      allowsEditing: true,
      aspect: [4, 3],
      quality: 1,
    });

    if (!result.canceled) {
      setProductImage(result.assets[0]);
    }
  };

  const handleVoiceResult = (text: string) => {
    setProductDescription(text);
  };

  const handleWorkspaceImagePicker = async () => {
    const permissionResult = await ImagePicker.requestMediaLibraryPermissionsAsync();

    if (!permissionResult.granted) {
      Alert.alert('Permission Required', 'Permission to access photos is required!');
      return;
    }

    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      allowsEditing: true,
      aspect: [4, 3],
      quality: 1,
    });

    if (!result.canceled) {
      setWorkspaceImage(result.assets[0]);
    }
  };

  const handleRunHygieneCheck = async () => {
    if (!workspaceImage) {
      Alert.alert(t('common.error'), 'Please choose a workspace image first');
      return;
    }

    setIsCheckingHygiene(true);

    try {
      const formData = new FormData();
      formData.append('workspaceImage', {
        uri: workspaceImage.uri,
        type: 'image/jpeg',
        name: 'workspace.jpg',
      } as any);

      const response = await client.post('/hygiene/check', formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });

      setHygieneResult(response.data);
      Alert.alert(
        t('common.success'),
        `Hygiene score: ${response.data.hygiene_score}% (${response.data.badge_text})`
      );
    } catch (error: any) {
      Alert.alert(
        t('common.error'),
        error?.response?.data?.details || error?.response?.data?.error || 'Failed to run hygiene check'
      );
    } finally {
      setIsCheckingHygiene(false);
    }
  };

  const handleOnboard = async () => {
    if (!shopName || !address || !pincode) {
      Alert.alert(t('common.error'), 'Please fill in all required fields');
      return;
    }

    try {
      const response = await client.post('/vendors/onboard', {
        shop_name: shopName,
        address,
        pincode,
        story_text: description,
      });

      setVendorId(response.data.id);
      setIsOnboarded(true);
      Alert.alert(t('common.success'), 'Seller onboarding completed successfully!');
    } catch (error) {
      Alert.alert(t('common.error'), 'Failed to complete seller onboarding');
    }
  };

  const handleAddProduct = async () => {
    if (!productName || !productDescription || !productPrice) {
      Alert.alert(t('common.error'), 'Please fill in all product fields');
      return;
    }

    if (!productImage) {
      Alert.alert(t('common.error'), 'Please select a product image');
      return;
    }

    if (!hygieneResult) {
      Alert.alert(t('common.error'), 'Please complete the hygiene check before adding products');
      return;
    }

    try {
      const formData = new FormData();
      formData.append('name', productName);
      formData.append('description', productDescription);
      formData.append('price', productPrice);
      formData.append('pincode', pincode);
      formData.append('category', 'General');
      formData.append('image', {
        uri: productImage.uri,
        type: 'image/jpeg',
        name: 'product.jpg',
      } as any);

      await dispatch(createProduct(formData));
      
      Alert.alert(t('common.success'), t('seller.productAdded'));
      
      // Reset form
      setProductName('');
      setProductDescription('');
      setProductPrice('');
      setProductImage(null);
    } catch (error) {
      Alert.alert(t('common.error'), 'Failed to add product');
    }
  };

  if (!isOnboarded) {
    return (
      <ScrollView style={styles.container}>
        <Card style={styles.card}>
          <Card.Content>
            <Text variant="headlineSmall" style={styles.title}>
              {t('seller.becomeSeller')}
            </Text>
            
            <TextInput
              label={t('seller.shopName')}
              value={shopName}
              onChangeText={setShopName}
              style={styles.input}
              mode="outlined"
            />
            
            <TextInput
              label={t('seller.address')}
              value={address}
              onChangeText={setAddress}
              style={styles.input}
              mode="outlined"
              multiline
            />
            
            <TextInput
              label={t('seller.pincode')}
              value={pincode}
              onChangeText={setPincode}
              style={styles.input}
              mode="outlined"
              keyboardType="numeric"
              maxLength={6}
            />
            
            <TextInput
              label={t('seller.description')}
              value={description}
              onChangeText={setDescription}
              style={styles.input}
              mode="outlined"
              multiline
            />
            
            <Button
              mode="contained"
              onPress={handleOnboard}
              style={styles.button}
            >
              Complete Onboarding
            </Button>
          </Card.Content>
        </Card>
      </ScrollView>
    );
  }

  return (
    <ScrollView style={styles.container}>
      <Card style={styles.card}>
        <Card.Content>
          <Text variant="headlineSmall" style={styles.title}>
            {t('seller.addProduct')}
          </Text>

          <Card style={styles.hygieneCard}>
            <Card.Content>
              <Text variant="titleMedium" style={styles.hygieneTitle}>
                Daily Hygiene Check
              </Text>

              <Button
                mode="outlined"
                onPress={handleWorkspaceImagePicker}
                style={styles.imageButton}
                icon="image"
              >
                Select Workspace Photo
              </Button>

              {workspaceImage && (
                <View style={styles.imagePreview}>
                  <Image source={{ uri: workspaceImage.uri }} style={styles.previewImage} />
                </View>
              )}

              <Button
                mode="contained-tonal"
                onPress={handleRunHygieneCheck}
                style={styles.button}
                loading={isCheckingHygiene}
                disabled={isCheckingHygiene}
              >
                Run Hygiene Check
              </Button>

              {hygieneResult && (
                <View style={styles.resultBox}>
                  <Text variant="titleSmall">Score: {hygieneResult.hygiene_score}%</Text>
                  <Text variant="bodyMedium">Status: {hygieneResult.badge_text}</Text>
                  <Text variant="bodySmall">
                    Class: {hygieneResult.predicted_class} | Confidence:{' '}
                    {(hygieneResult.confidence * 100).toFixed(1)}%
                  </Text>
                </View>
              )}
            </Card.Content>
          </Card>
          
          <TextInput
            label={t('seller.productName')}
            value={productName}
            onChangeText={setProductName}
            style={styles.input}
            mode="outlined"
          />
          
          <TextInput
            label={t('seller.productDescription')}
            value={productDescription}
            onChangeText={setProductDescription}
            style={styles.input}
            mode="outlined"
            multiline
          />
          
          <VoiceInputButton onResult={handleVoiceResult} />
          
          <TextInput
            label={t('seller.productPrice')}
            value={productPrice}
            onChangeText={setProductPrice}
            style={styles.input}
            mode="outlined"
            keyboardType="numeric"
          />
          
          <Button
            mode="outlined"
            onPress={handleImagePicker}
            style={styles.imageButton}
            icon="camera"
          >
            {t('seller.productImage')}
          </Button>
          
          {productImage && (
            <View style={styles.imagePreview}>
              <Image source={{ uri: productImage.uri }} style={styles.previewImage} />
              <Text variant="bodySmall" style={styles.imageText}>
                Image selected
              </Text>
            </View>
          )}
          
          <Button
            mode="contained"
            onPress={handleAddProduct}
            style={styles.button}
            loading={isLoading}
            disabled={isLoading}
          >
            {t('seller.addProduct')}
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
  },
  title: {
    marginBottom: 16,
    color: '#2E7D32',
    fontWeight: 'bold',
  },
  input: {
    marginBottom: 16,
  },
  button: {
    marginTop: 8,
  },
  imageButton: {
    marginBottom: 16,
  },
  imagePreview: {
    alignItems: 'center',
    marginBottom: 16,
  },
  previewImage: {
    width: 150,
    height: 150,
    borderRadius: 8,
    marginBottom: 8,
  },
  imageText: {
    color: '#666',
  },
  hygieneCard: {
    marginBottom: 16,
    backgroundColor: '#F6FFF4',
  },
  hygieneTitle: {
    marginBottom: 12,
    color: '#2E7D32',
    fontWeight: 'bold',
  },
  resultBox: {
    marginTop: 12,
    padding: 12,
    borderRadius: 8,
    backgroundColor: '#E8F5E9',
  },
});
