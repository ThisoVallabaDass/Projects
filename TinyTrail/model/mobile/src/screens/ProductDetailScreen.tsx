import React, { useState, useEffect } from 'react';
import { View, StyleSheet, ScrollView, Alert, Image } from 'react-native';
import { Text, Card, Button, Chip, Divider } from 'react-native-paper';
import { useDispatch, useSelector } from 'react-redux';
import { useTranslation } from 'react-i18next';
import { NavigationProp, RouteProp, useRoute, useNavigation } from '@react-navigation/native';

import { RootState, AppDispatch } from '../store';
import { addToCart } from '../store/cartSlice';
import { getProductById, Product } from '../store/productsSlice';
import { RootStackParamList } from '../navigation/types';

export default function ProductDetailScreen() {
  const { t } = useTranslation();
  const route = useRoute<RouteProp<RootStackParamList, 'ProductDetail'>>();
  const navigation = useNavigation<NavigationProp<RootStackParamList>>();
  const dispatch = useDispatch<AppDispatch>();
  
  const { productId } = route.params;
  const { user } = useSelector((state: RootState) => state.auth);
  const { products } = useSelector((state: RootState) => state.products);

  const [product, setProduct] = useState<Product | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadProduct();
  }, [productId]);

  const loadProduct = async () => {
    try {
      // First check if product is already in store
      const existingProduct = products.find(p => p.id === productId);
      if (existingProduct) {
        setProduct(existingProduct);
        setLoading(false);
        return;
      }

      // If not found, fetch from API
      const resultAction = await dispatch(getProductById(productId));
      if (getProductById.fulfilled.match(resultAction)) {
        setProduct(resultAction.payload);
      } else {
        Alert.alert('Error', 'Product not found');
        navigation.goBack();
      }
    } catch (error) {
      Alert.alert('Error', 'Failed to load product');
      navigation.goBack();
    } finally {
      setLoading(false);
    }
  };

  const handleAddToCart = () => {
    if (!user) {
      Alert.alert(
        t('auth.login'),
        'Please login to add items to cart',
        [
          { text: t('common.cancel'), style: 'cancel' },
          { text: t('auth.login'), onPress: () => navigation.navigate('Login') }
        ]
      );
      return;
    }

    if (!product) {
      return;
    }

    dispatch(addToCart(product));
    Alert.alert(t('common.success'), 'Product added to cart');
  };

  const handleBuyNow = () => {
    if (!user) {
      Alert.alert(
        t('auth.login'),
        'Please login to continue',
        [
          { text: t('common.cancel'), style: 'cancel' },
          { text: t('auth.login'), onPress: () => navigation.navigate('Login') }
        ]
      );
      return;
    }

    if (!product) {
      return;
    }

    dispatch(addToCart(product));
    navigation.navigate('Checkout');
  };

  if (loading) {
    return (
      <View style={styles.loadingContainer}>
        <Text>{t('common.loading')}</Text>
      </View>
    );
  }

  if (!product) {
    return (
      <View style={styles.errorContainer}>
        <Text>Product not found</Text>
      </View>
    );
  }

  return (
    <ScrollView style={styles.container}>
      {/* Product Image */}
      <Card style={styles.imageCard}>
        <Card.Content style={styles.imageContainer}>
          {product.imageUrl ? (
            <Image source={{ uri: product.imageUrl }} style={styles.productImage} />
          ) : (
            <View style={styles.placeholderImage}>
              <Text style={styles.placeholderText}>No Image</Text>
            </View>
          )}
        </Card.Content>
      </Card>

      {/* Product Info */}
      <Card style={styles.infoCard}>
        <Card.Content>
          <Text variant="headlineSmall" style={styles.productName}>
            {product.name}
          </Text>
          
          <View style={styles.priceContainer}>
            <Text variant="headlineMedium" style={styles.price}>
              ₹{product.price}
            </Text>
            {product.category && (
              <Chip style={styles.categoryChip}>
                {product.category}
              </Chip>
            )}
          </View>

          <Divider style={styles.divider} />

          <Text variant="titleMedium" style={styles.sectionTitle}>
            {t('products.description')}
          </Text>
          <Text variant="bodyMedium" style={styles.description}>
            {product.description}
          </Text>

          <Divider style={styles.divider} />

          <Text variant="titleMedium" style={styles.sectionTitle}>
            {t('products.seller')}
          </Text>
          <Text variant="bodyMedium" style={styles.sellerInfo}>
            {product.sellerName}
          </Text>
          <Text variant="bodySmall" style={styles.pincodeInfo}>
            Pincode: {product.pincode}
          </Text>
        </Card.Content>
      </Card>

      {/* Action Buttons */}
      <View style={styles.actionContainer}>
        <Button
          mode="outlined"
          onPress={handleAddToCart}
          style={styles.addToCartButton}
          icon="cart-plus"
        >
          {t('products.addToCart')}
        </Button>
        <Button
          mode="contained"
          onPress={handleBuyNow}
          style={styles.buyNowButton}
          icon="credit-card"
        >
          {t('products.buyNow')}
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
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  errorContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  imageCard: {
    margin: 16,
    marginBottom: 8,
  },
  imageContainer: {
    alignItems: 'center',
    paddingVertical: 16,
  },
  productImage: {
    width: 200,
    height: 200,
    borderRadius: 8,
  },
  placeholderImage: {
    width: 200,
    height: 200,
    backgroundColor: '#E0E0E0',
    borderRadius: 8,
    justifyContent: 'center',
    alignItems: 'center',
  },
  placeholderText: {
    color: '#666',
    fontSize: 16,
  },
  infoCard: {
    margin: 16,
    marginTop: 8,
  },
  productName: {
    fontWeight: 'bold',
    marginBottom: 8,
    color: '#2E7D32',
  },
  priceContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 16,
  },
  price: {
    fontWeight: 'bold',
    color: '#FF6F00',
  },
  categoryChip: {
    backgroundColor: '#E8F5E8',
  },
  divider: {
    marginVertical: 16,
  },
  sectionTitle: {
    fontWeight: 'bold',
    marginBottom: 8,
    color: '#2E7D32',
  },
  description: {
    lineHeight: 20,
    color: '#333',
  },
  sellerInfo: {
    fontWeight: '500',
    color: '#333',
  },
  pincodeInfo: {
    color: '#666',
    marginTop: 4,
  },
  actionContainer: {
    flexDirection: 'row',
    padding: 16,
    gap: 12,
  },
  addToCartButton: {
    flex: 1,
  },
  buyNowButton: {
    flex: 1,
  },
});
