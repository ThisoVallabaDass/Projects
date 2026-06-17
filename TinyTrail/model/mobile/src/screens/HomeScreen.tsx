import React, { useMemo, useState } from 'react';
import { View, StyleSheet, ScrollView, Alert, TouchableOpacity } from 'react-native';
import { Text, Card, TextInput, Button, Avatar } from 'react-native-paper';
import { useDispatch, useSelector } from 'react-redux';
import { useTranslation } from 'react-i18next';
import { Ionicons } from '@expo/vector-icons';
import { NavigationProp, useNavigation } from '@react-navigation/native';

import { RootState, AppDispatch } from '../store';
import { setPincode } from '../store/pincodeSlice';
import { searchProductsByPincode } from '../store/productsSlice';
import ProductCard from '../components/ProductCard';
import { RootStackParamList } from '../navigation/types';

const categoryCards = [
  { icon: 'restaurant-outline', label: 'Home Kitchens', tint: '#FFEAD7', color: '#CC6B1C' },
  { icon: 'leaf-outline', label: 'Fresh Produce', tint: '#E1F4E8', color: '#227A3B' },
  { icon: 'fast-food-outline', label: 'Street Snacks', tint: '#FFE3E8', color: '#CC3E63' },
  { icon: 'cut-outline', label: 'Tailoring & Repairs', tint: '#E3E8FF', color: '#3359C9' },
  { icon: 'color-palette-outline', label: 'Local Artisans', tint: '#F4E7FF', color: '#7A40B5' },
  { icon: 'basket-outline', label: 'Daily Essentials', tint: '#E4F6FF', color: '#0E7490' },
];

const promoBanners = [
  {
    title: 'Live carts near you',
    subtitle: 'Track moving vendors and hail them when they enter your street.',
    colors: ['#1954C8', '#45A4FF'],
  },
  {
    title: 'Verified home kitchens',
    subtitle: 'Support local cooks with daily hygiene checks and trust badges.',
    colors: ['#1E7A39', '#67C587'],
  },
];

const vendorFeed = [
  {
    id: 1,
    name: "Lakshmi's Kitchen",
    badge: 'Gold',
    hygiene: '95% Safe',
    note: 'Tamil meals and lunch boxes',
  },
  {
    id: 2,
    name: 'Fresh Cart Ravi',
    badge: 'Blue',
    hygiene: '89% Safe',
    note: 'Vegetables and cut fruits',
  },
  {
    id: 3,
    name: 'Anita Snacks',
    badge: 'Platinum',
    hygiene: '97% Safe',
    note: 'Evening snacks and chaat',
  },
];

export default function HomeScreen() {
  const { t } = useTranslation();
  const navigation = useNavigation<NavigationProp<RootStackParamList>>();
  const dispatch = useDispatch<AppDispatch>();
  
  const { currentPincode, isValid } = useSelector((state: RootState) => state.pincode);
  const { products, isLoading } = useSelector((state: RootState) => state.products);
  const { user } = useSelector((state: RootState) => state.auth);
  const [draftPincode, setDraftPincode] = useState(currentPincode || '600062');

  const handlePincodeSearch = () => {
    const cleanPincode = draftPincode.replace(/\D/g, '').slice(0, 6);
    dispatch(setPincode(cleanPincode));

    if (!/^\d{6}$/.test(cleanPincode)) {
      Alert.alert(t('common.error'), 'Please enter a valid 6-digit pincode');
      return;
    }
    dispatch(searchProductsByPincode(cleanPincode));
  };

  const handleProductPress = (productId: number) => {
    navigation.navigate('ProductDetail', { productId });
  };

  const featuredProducts = useMemo(() => products.slice(0, 4), [products]);

  return (
    <View style={styles.container}>
      <ScrollView style={styles.scrollView} contentContainerStyle={styles.scrollContent}>
        <View style={styles.headerBar}>
          <TouchableOpacity style={styles.locationPill} activeOpacity={0.85}>
            <Ionicons name="location" size={16} color="#2563EB" />
            <Text style={styles.locationText}>Delivering to {draftPincode || '600062'} ▼</Text>
          </TouchableOpacity>
          <View style={styles.headerActions}>
            <TouchableOpacity style={styles.headerIcon}>
              <Ionicons name="notifications-outline" size={20} color="#16324F" />
            </TouchableOpacity>
            <Avatar.Text
              size={34}
              label={(user?.username?.[0] || 'U').toUpperCase()}
              style={styles.avatar}
              color="#FFFFFF"
            />
          </View>
        </View>

        <View style={styles.searchShell}>
          <View style={styles.searchBar}>
            <Ionicons name="search" size={18} color="#4B6280" />
            <Text style={styles.searchPlaceholder}>
              Search for local snacks, tailors, or fresh veggies...
            </Text>
            <TouchableOpacity style={styles.micButton}>
              <Ionicons name="mic" size={18} color="#1667D9" />
            </TouchableOpacity>
          </View>
          <View style={styles.pincodeRow}>
            <TextInput
              mode="outlined"
              label="Pincode"
              value={draftPincode}
              onChangeText={(value) => setDraftPincode(value.replace(/\D/g, '').slice(0, 6))}
              keyboardType="numeric"
              style={styles.pincodeInput}
              outlineColor="#D6E2F2"
              activeOutlineColor="#1667D9"
            />
            <Button
              mode="contained"
              onPress={handlePincodeSearch}
              style={styles.pincodeButton}
              disabled={isLoading}
            >
              {isLoading ? 'Loading' : 'Update'}
            </Button>
          </View>
        </View>

        <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.bannerRow}>
          {promoBanners.map((banner) => (
            <View
              key={banner.title}
              style={[styles.bannerCard, { backgroundColor: banner.colors[0] }]}
            >
              <View style={[styles.bannerGlow, { backgroundColor: banner.colors[1] }]} />
              <Text style={styles.bannerTitle}>{banner.title}</Text>
              <Text style={styles.bannerSubtitle}>{banner.subtitle}</Text>
            </View>
          ))}
        </ScrollView>

        <View style={styles.sectionHeader}>
          <Text style={styles.sectionTitle}>Shop by category</Text>
          <Text style={styles.sectionLink}>See all</Text>
        </View>
        <View style={styles.categoryGrid}>
          {categoryCards.map((category) => (
            <TouchableOpacity key={category.label} style={[styles.categoryTile, { backgroundColor: category.tint }]}>
              <View style={[styles.categoryIcon, { backgroundColor: '#FFFFFF' }]}>
                <Ionicons name={category.icon as any} size={20} color={category.color} />
              </View>
              <Text style={styles.categoryLabel}>{category.label}</Text>
            </TouchableOpacity>
          ))}
        </View>

        <Card style={styles.liveMapCard}>
          <Card.Content>
            <View style={styles.sectionHeader}>
              <View>
                <Text style={styles.sectionTitle}>Moving vendors near you</Text>
                <Text style={styles.sectionSubtext}>Live carts update here as they move around your area.</Text>
              </View>
            </View>
            <View style={styles.radar}>
              <View style={[styles.radarDot, styles.dotOne]} />
              <View style={[styles.radarDot, styles.dotTwo]} />
              <View style={[styles.radarDot, styles.dotThree]} />
            </View>
            <Button
              mode="contained-tonal"
              onPress={() => Alert.alert('Live Map', 'Live map screen can be connected next.')}
              style={styles.mapButton}
            >
              Open Live Map
            </Button>
          </Card.Content>
        </Card>

        <View style={styles.sectionHeader}>
          <Text style={styles.sectionTitle}>Popular in your pincode</Text>
          <Text style={styles.sectionLink}>Trusted locals</Text>
        </View>
        <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.vendorFeed}>
          {vendorFeed.map((vendor) => (
            <View key={vendor.id} style={styles.vendorCard}>
              <View style={styles.vendorAvatarWrap}>
                <Avatar.Text size={48} label={vendor.name[0]} style={styles.vendorAvatar} color="#FFFFFF" />
                <View style={styles.badgePill}>
                  <Text style={styles.badgeText}>{vendor.badge}</Text>
                </View>
              </View>
              <Text style={styles.vendorName}>{vendor.name}</Text>
              <Text style={styles.vendorNote}>{vendor.note}</Text>
              <View style={styles.safePill}>
                <Text style={styles.safeText}>✨ {vendor.hygiene}</Text>
              </View>
            </View>
          ))}
        </ScrollView>

        <View style={styles.sectionHeader}>
          <Text style={styles.sectionTitle}>Popular picks</Text>
          <Text style={styles.sectionLink}>{draftPincode || currentPincode || 'Local feed'}</Text>
        </View>
        {featuredProducts.length > 0 ? (
          featuredProducts.map((product) => (
            <ProductCard
              key={product.id}
              product={product}
              onPress={() => handleProductPress(product.id)}
            />
          ))
        ) : (
          <Card style={styles.emptyCard}>
            <Card.Content>
              <Text style={styles.emptyTitle}>Search a pincode to load products</Text>
              <Text style={styles.emptyText}>
                Try `600001` first to see seeded products from the sample backend.
              </Text>
            </Card.Content>
          </Card>
        )}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F3F7FB',
  },
  scrollView: {
    flex: 1,
  },
  scrollContent: {
    padding: 18,
    paddingBottom: 32,
  },
  headerBar: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 18,
  },
  locationPill: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    borderRadius: 18,
    paddingHorizontal: 14,
    paddingVertical: 10,
    gap: 8,
    flex: 1,
    marginRight: 10,
    shadowColor: '#0F172A',
    shadowOpacity: 0.06,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 2 },
    elevation: 2,
  },
  locationText: {
    color: '#16324F',
    fontWeight: '700',
    fontSize: 13,
  },
  headerActions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  headerIcon: {
    width: 38,
    height: 38,
    borderRadius: 19,
    backgroundColor: '#FFFFFF',
    alignItems: 'center',
    justifyContent: 'center',
    elevation: 2,
  },
  avatar: {
    backgroundColor: '#1667D9',
  },
  searchShell: {
    backgroundColor: '#FFFFFF',
    borderRadius: 24,
    padding: 16,
    marginBottom: 18,
    shadowColor: '#0F172A',
    shadowOpacity: 0.06,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 4 },
    elevation: 2,
  },
  searchBar: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1.5,
    borderColor: '#B9D2F8',
    borderRadius: 18,
    backgroundColor: '#F8FBFF',
    paddingHorizontal: 14,
    paddingVertical: 12,
  },
  searchPlaceholder: {
    flex: 1,
    marginLeft: 10,
    color: '#607086',
    fontSize: 13,
  },
  micButton: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: '#E7F1FF',
    alignItems: 'center',
    justifyContent: 'center',
  },
  pincodeRow: {
    flexDirection: 'row',
    gap: 12,
    marginTop: 14,
    alignItems: 'center',
  },
  pincodeInput: {
    flex: 1,
    backgroundColor: '#FFFFFF',
  },
  pincodeButton: {
    borderRadius: 14,
    backgroundColor: '#1667D9',
  },
  bannerRow: {
    paddingBottom: 8,
    gap: 12,
  },
  bannerCard: {
    width: 284,
    borderRadius: 24,
    padding: 18,
    overflow: 'hidden',
  },
  bannerGlow: {
    position: 'absolute',
    width: 160,
    height: 160,
    borderRadius: 999,
    right: -30,
    top: -30,
    opacity: 0.32,
  },
  bannerTitle: {
    color: '#FFFFFF',
    fontSize: 21,
    fontWeight: '800',
    marginBottom: 8,
    width: '75%',
  },
  bannerSubtitle: {
    color: '#E8F2FF',
    fontSize: 13,
    lineHeight: 20,
    width: '78%',
  },
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: 18,
    marginBottom: 12,
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: '800',
    color: '#173250',
  },
  sectionLink: {
    color: '#1667D9',
    fontWeight: '700',
    fontSize: 12,
  },
  sectionSubtext: {
    marginTop: 4,
    color: '#6B7A90',
    fontSize: 13,
  },
  categoryGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
    gap: 10,
  },
  categoryTile: {
    width: '31%',
    borderRadius: 22,
    padding: 14,
    minHeight: 106,
    justifyContent: 'space-between',
  },
  categoryIcon: {
    width: 42,
    height: 42,
    borderRadius: 14,
    alignItems: 'center',
    justifyContent: 'center',
  },
  categoryLabel: {
    color: '#173250',
    fontWeight: '700',
    fontSize: 12,
    lineHeight: 17,
  },
  liveMapCard: {
    marginTop: 18,
    borderRadius: 24,
    backgroundColor: '#FFFFFF',
  },
  radar: {
    marginTop: 14,
    height: 120,
    borderRadius: 20,
    backgroundColor: '#E9F2FF',
    position: 'relative',
    overflow: 'hidden',
  },
  radarDot: {
    position: 'absolute',
    width: 16,
    height: 16,
    borderRadius: 999,
    backgroundColor: '#2563EB',
    borderWidth: 4,
    borderColor: '#B8D2FF',
  },
  dotOne: {
    top: 26,
    left: 44,
  },
  dotTwo: {
    top: 62,
    right: 56,
  },
  dotThree: {
    bottom: 22,
    left: 130,
  },
  mapButton: {
    marginTop: 14,
    borderRadius: 16,
  },
  vendorFeed: {
    gap: 12,
  },
  vendorCard: {
    width: 172,
    backgroundColor: '#FFFFFF',
    borderRadius: 22,
    padding: 14,
    shadowColor: '#0F172A',
    shadowOpacity: 0.06,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 3 },
    elevation: 2,
  },
  vendorAvatarWrap: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 12,
  },
  vendorAvatar: {
    backgroundColor: '#227A3B',
  },
  badgePill: {
    backgroundColor: '#EAF2FF',
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 4,
  },
  badgeText: {
    color: '#1667D9',
    fontWeight: '700',
    fontSize: 11,
  },
  vendorName: {
    color: '#173250',
    fontWeight: '800',
    fontSize: 15,
    marginBottom: 4,
  },
  vendorNote: {
    color: '#6B7A90',
    fontSize: 12,
    minHeight: 34,
  },
  safePill: {
    alignSelf: 'flex-start',
    marginTop: 12,
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 6,
    backgroundColor: '#E7F7EB',
  },
  safeText: {
    color: '#227A3B',
    fontWeight: '700',
    fontSize: 11,
  },
  emptyCard: {
    borderRadius: 22,
    marginTop: 4,
    backgroundColor: '#FFFFFF',
  },
  emptyTitle: {
    fontSize: 18,
    fontWeight: '800',
    color: '#173250',
    marginBottom: 8,
  },
  emptyText: {
    color: '#6B7A90',
    lineHeight: 20,
  },
});
