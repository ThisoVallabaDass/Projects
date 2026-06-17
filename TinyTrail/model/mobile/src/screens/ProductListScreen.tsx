import React, { useMemo, useState } from 'react';
import { View, StyleSheet, FlatList, Alert } from 'react-native';
import { Text, Card, TextInput, Button } from 'react-native-paper';
import { useDispatch, useSelector } from 'react-redux';
import { useTranslation } from 'react-i18next';
import { NavigationProp, useNavigation } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';

import { RootState, AppDispatch } from '../store';
import { searchProductsByPincode, setSelectedCategory, Product } from '../store/productsSlice';
import ProductCard from '../components/ProductCard';
import { RootStackParamList } from '../navigation/types';

const categories = ['All', 'Home Kitchens', 'Fresh Produce', 'Street Snacks', 'Essentials'];

export default function ProductListScreen() {
  const { t } = useTranslation();
  const navigation = useNavigation<NavigationProp<RootStackParamList>>();
  const dispatch = useDispatch<AppDispatch>();
  
  const { currentPincode, isValid } = useSelector((state: RootState) => state.pincode);
  const { products, isLoading, selectedCategory } = useSelector((state: RootState) => state.products);

  const [searchQuery, setSearchQuery] = useState('');
  const [highHygieneOnly, setHighHygieneOnly] = useState(false);

  const handleSearch = () => {
    if (!isValid) {
      Alert.alert(t('common.error'), 'Please enter a valid pincode first');
      return;
    }
    dispatch(searchProductsByPincode(currentPincode));
  };

  const handleProductPress = (productId: number) => {
    navigation.navigate('ProductDetail', { productId });
  };

  const handleCategorySelect = (category: string) => {
    dispatch(setSelectedCategory(category === 'All' ? null : category));
  };

  const filteredProducts = useMemo(
    () =>
      products.filter((product) => {
        const friendlyCategory =
          product.category?.toLowerCase().includes('fruit') || product.category?.toLowerCase().includes('vegetable')
            ? 'Fresh Produce'
            : product.category?.toLowerCase().includes('snack')
              ? 'Street Snacks'
              : product.category?.toLowerCase().includes('essential')
                ? 'Essentials'
                : 'Home Kitchens';

        const matchesCategory = !selectedCategory || friendlyCategory === selectedCategory;
        const matchesSearch =
          !searchQuery ||
          product.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
          product.description.toLowerCase().includes(searchQuery.toLowerCase()) ||
          product.sellerName.toLowerCase().includes(searchQuery.toLowerCase());
        const passesHygiene = !highHygieneOnly || product.id % 2 === 0;
        return matchesCategory && matchesSearch && passesHygiene;
      }),
    [products, selectedCategory, searchQuery, highHygieneOnly]
  );

  const renderProduct = ({ item }: { item: Product }) => (
    <View style={styles.productColumn}>
      <ProductCard
        product={item}
        onPress={() => handleProductPress(item.id)}
      />
    </View>
  );

  return (
    <View style={styles.container}>
      <FlatList
        data={filteredProducts}
        renderItem={renderProduct}
        keyExtractor={(item) => item.id.toString()}
        numColumns={2}
        contentContainerStyle={styles.productsList}
        columnWrapperStyle={filteredProducts.length > 1 ? styles.columnWrapper : undefined}
        showsVerticalScrollIndicator={false}
        ListHeaderComponent={
          <>
            <View style={styles.searchWrap}>
              <View style={styles.searchRow}>
                <View style={styles.searchField}>
                  <Ionicons name="search" size={18} color="#607086" />
                  <TextInput
                    placeholder="Search local snacks, tailors, or fresh veggies..."
                    value={searchQuery}
                    onChangeText={setSearchQuery}
                    style={styles.searchInput}
                    mode="flat"
                    underlineColor="transparent"
                    activeUnderlineColor="transparent"
                    onSubmitEditing={handleSearch}
                  />
                  <Ionicons name="mic" size={18} color="#1667D9" />
                </View>
                <Button
                  mode="contained-tonal"
                  onPress={() => setHighHygieneOnly((value) => !value)}
                  style={styles.filterButton}
                  icon="tune-variant"
                >
                  {highHygieneOnly ? 'Safe' : 'Filter'}
                </Button>
              </View>

              <Text style={styles.pincodeHint}>
                Showing products around pincode {currentPincode || '600001'}
              </Text>
            </View>

            <FlatList
              horizontal
              showsHorizontalScrollIndicator={false}
              data={categories}
              keyExtractor={(item) => item}
              contentContainerStyle={styles.categoriesContainer}
              renderItem={({ item }) => {
                const selected = selectedCategory === item || (item === 'All' && !selectedCategory);
                return (
                  <Button
                    mode={selected ? 'contained' : 'outlined'}
                    onPress={() => handleCategorySelect(item)}
                    style={[styles.categoryPill, selected ? styles.categoryPillActive : styles.categoryPillInactive]}
                    textColor={selected ? '#FFFFFF' : '#173250'}
                    buttonColor={selected ? '#1954C8' : '#FFFFFF'}
                  >
                    {item}
                  </Button>
                );
              }}
            />
          </>
        }
        ListEmptyComponent={
          <Card style={styles.emptyCard}>
            <Card.Content style={styles.emptyContent}>
              <View style={styles.emptyIllustration}>
                <Ionicons name="basket-outline" size={44} color="#8AA0BE" />
              </View>
              <Text style={styles.emptyTitle}>
                It&apos;s quiet around here!
              </Text>
              <Text style={styles.emptyText}>
                No vendors are currently live in your area. Try a different pincode or come back in a bit.
              </Text>
              <Button
                mode="contained"
                onPress={() => navigation.navigate('Home')}
                style={styles.emptyButton}
                buttonColor="#1667D9"
              >
                Change Pincode
              </Button>
            </Card.Content>
          </Card>
        }
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F3F7FB',
  },
  searchWrap: {
    marginTop: 16,
    marginBottom: 12,
  },
  searchRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  searchField: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    borderColor: '#D7E0EA',
    borderWidth: 1,
    borderRadius: 999,
    paddingHorizontal: 14,
    minHeight: 52,
    shadowColor: '#0F172A',
    shadowOpacity: 0.04,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 2 },
    elevation: 1,
  },
  searchInput: {
    flex: 1,
    backgroundColor: 'transparent',
    marginLeft: 8,
    marginRight: 8,
  },
  categoriesContainer: {
    paddingBottom: 6,
    gap: 10,
  },
  filterButton: {
    borderRadius: 999,
  },
  pincodeHint: {
    color: '#607086',
    fontSize: 12,
    marginTop: 10,
    marginLeft: 2,
  },
  categoryPill: {
    marginRight: 10,
    borderRadius: 999,
  },
  categoryPillActive: {
    backgroundColor: '#1954C8',
  },
  categoryPillInactive: {
    borderColor: '#D7E0EA',
    borderWidth: 1,
  },
  productsList: {
    paddingHorizontal: 16,
    paddingBottom: 24,
    paddingTop: 6,
  },
  columnWrapper: {
    gap: 12,
    marginBottom: 12,
  },
  productColumn: {
    flex: 1,
  },
  emptyCard: {
    marginTop: 36,
    borderRadius: 24,
    backgroundColor: '#FFFFFF',
  },
  emptyContent: {
    alignItems: 'center',
    paddingVertical: 34,
    paddingHorizontal: 18,
  },
  emptyIllustration: {
    width: 88,
    height: 88,
    borderRadius: 999,
    backgroundColor: '#EEF4FA',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 14,
  },
  emptyTitle: {
    textAlign: 'center',
    fontSize: 22,
    fontWeight: '800',
    color: '#173250',
    marginBottom: 8,
  },
  emptyText: {
    textAlign: 'center',
    marginBottom: 18,
    color: '#607086',
    lineHeight: 21,
  },
  emptyButton: {
    borderRadius: 14,
  },
});
