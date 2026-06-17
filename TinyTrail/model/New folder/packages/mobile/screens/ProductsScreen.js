import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  TextInput,
  Alert,
  SafeAreaView,
} from 'react-native';
import axios from 'axios';
import Icon from '../components/Icon';

const API_URL = 'http://localhost:8080/api';

export default function ProductsScreen() {
  const [products, setProducts] = useState([]);
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(false);
  const [pincode, setPincode] = useState('600001');
  const [selectedCategory, setSelectedCategory] = useState('');

  useEffect(() => {
    fetchCategories();
    fetchProducts();
  }, []);

  const fetchCategories = async () => {
    try {
      const response = await axios.get(`${API_URL}/categories`);
      setCategories(response.data.categories || []);
    } catch (error) {
      console.log('Error fetching categories:', error);
    }
  };

  const fetchProducts = async () => {
    setLoading(true);
    try {
      let url = `${API_URL}/products?pincode=${pincode}`;
      if (selectedCategory) {
        url += `&category=${selectedCategory}`;
      }

      const response = await axios.get(url);
      setProducts(response.data.products || []);
    } catch (error) {
      Alert.alert('Error', 'Failed to fetch products');
    } finally {
      setLoading(false);
    }
  };

  const addToCart = async (productId) => {
    try {
      if (!global.tinytrailToken) {
        Alert.alert('Error', 'Please login first');
        return;
      }

      await axios.post(
        `${API_URL}/cart/add`,
        { productId, quantity: 1 },
        { headers: { Authorization: `Bearer ${global.tinytrailToken}` } }
      );
      Alert.alert('Success', 'Item added to cart!');
    } catch (error) {
      Alert.alert('Error', 'Failed to add to cart');
    }
  };

  const renderProduct = ({ item }) => (
    <View style={styles.productCard}>
      <View style={styles.productImagePlaceholder}>
        <Icon name="image" size={40} color="#ccc" />
      </View>
      <Text style={styles.productName}>{item.name}</Text>
      <Text style={styles.productShop}>{item.shop_name}</Text>
      <Text style={styles.productDescription} numberOfLines={2}>{item.description}</Text>
      
      <View style={styles.productFooter}>
        <View>
          <Text style={styles.productPrice}>₹{item.price}</Text>
          <View style={styles.rating}>
            <Icon name="star" size={14} color="#fbbf24" />
            <Text style={styles.ratingText}>{item.rating}</Text>
          </View>
        </View>
        <TouchableOpacity
          style={styles.addButton}
          onPress={() => addToCart(item.id)}
        >
          <Icon name="shopping-cart" size={18} color="#fff" />
          <Text style={styles.addButtonText}>Add</Text>
        </TouchableOpacity>
      </View>
    </View>
  );

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.filterContainer}>
        <TextInput
          style={styles.pincodeInput}
          placeholder="Pincode"
          value={pincode}
          onChangeText={setPincode}
          keyboardType="numeric"
        />
        <TouchableOpacity
          style={styles.filterButton}
          onPress={fetchProducts}
        >
          <Text style={styles.filterButtonText}>Filter</Text>
        </TouchableOpacity>
      </View>

      {categories.length > 0 && (
        <View style={styles.categoriesContainer}>
          <FlatList
            horizontal
            data={[{ id: 'all', name: 'All' }, ...categories.map(c => ({ id: c, name: c }))]}
            keyExtractor={(item) => item.id}
            renderItem={({ item }) => (
              <TouchableOpacity
                style={[
                  styles.categoryBadge,
                  selectedCategory === item.id || (item.id === 'all' && selectedCategory === '') ? styles.categoryBadgeActive : {},
                ]}
                onPress={() => {
                  setSelectedCategory(item.id === 'all' ? '' : item.id);
                }}
              >
                <Text
                  style={[
                    styles.categoryBadgeText,
                    selectedCategory === item.id || (item.id === 'all' && selectedCategory === '') ? styles.categoryBadgeTextActive : {},
                  ]}
                >
                  {item.name}
                </Text>
              </TouchableOpacity>
            )}
            scrollEnabled
            showsHorizontalScrollIndicator={false}
          />
        </View>
      )}

      {loading ? (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#16a34a" />
        </View>
      ) : products.length === 0 ? (
        <View style={styles.emptyContainer}>
          <Icon name="inbox" size={50} color="#ccc" />
          <Text style={styles.emptyText}>No products found</Text>
        </View>
      ) : (
        <FlatList
          data={products}
          renderItem={renderProduct}
          keyExtractor={(item) => item.id.toString()}
          numColumns={2}
          contentContainerStyle={styles.productsList}
          scrollEnabled
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
  filterContainer: {
    flexDirection: 'row',
    padding: 15,
    backgroundColor: '#fff',
    marginBottom: 10,
  },
  pincodeInput: {
    flex: 1,
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    paddingHorizontal: 10,
    paddingVertical: 10,
    marginRight: 10,
  },
  filterButton: {
    backgroundColor: '#16a34a',
    paddingHorizontal: 20,
    borderRadius: 8,
    justifyContent: 'center',
  },
  filterButtonText: {
    color: '#fff',
    fontWeight: 'bold',
  },
  categoriesContainer: {
    backgroundColor: '#fff',
    paddingHorizontal: 15,
    paddingVertical: 10,
    marginBottom: 10,
  },
  categoryBadge: {
    paddingHorizontal: 15,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: '#f5f5f5',
    marginRight: 10,
  },
  categoryBadgeActive: {
    backgroundColor: '#16a34a',
  },
  categoryBadgeText: {
    fontSize: 12,
    color: '#666',
  },
  categoryBadgeTextActive: {
    color: '#fff',
  },
  productsList: {
    paddingHorizontal: 10,
    paddingVertical: 10,
  },
  productCard: {
    flex: 1,
    backgroundColor: '#fff',
    borderRadius: 10,
    margin: 5,
    padding: 10,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 3.84,
    elevation: 5,
  },
  productImagePlaceholder: {
    height: 120,
    backgroundColor: '#f5f5f5',
    borderRadius: 8,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 10,
  },
  productName: {
    fontSize: 14,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 4,
  },
  productShop: {
    fontSize: 12,
    color: '#999',
    marginBottom: 4,
  },
  productDescription: {
    fontSize: 12,
    color: '#666',
    marginBottom: 8,
  },
  productFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-end',
  },
  productPrice: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#16a34a',
  },
  rating: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 4,
  },
  ratingText: {
    fontSize: 12,
    marginLeft: 4,
    color: '#666',
  },
  addButton: {
    backgroundColor: '#16a34a',
    padding: 8,
    borderRadius: 6,
    flexDirection: 'row',
    alignItems: 'center',
  },
  addButtonText: {
    color: '#fff',
    marginLeft: 4,
    fontSize: 12,
    fontWeight: 'bold',
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
});
