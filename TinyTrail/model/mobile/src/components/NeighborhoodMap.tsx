// TODO: Integrate real Leaflet or Google Maps with actual geocoding
// TODO: Add support for MAPS_API_KEY from environment
// TODO: Implement real geolocation and distance calculation
import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  TextInput,
  FlatList,
} from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { VendorCard } from './VendorCard';

interface Vendor {
  id: number;
  name: string;
  tagline: string;
  avatar?: string;
  specialties: string[];
  distance: number;
  rating?: number;
  isVerifiedHomeKitchen?: boolean;
}

interface NeighborhoodMapProps {
  onVendorSelect?: (vendorId: number) => void;
  initialLocation?: { pincode: string; lat: number; lon: number };
}

export const NeighborhoodMap: React.FC<NeighborhoodMapProps> = ({
  onVendorSelect,
  initialLocation,
}) => {
  const { t } = useTranslation();
  const [vendors, setVendors] = useState<Vendor[]>([]);
  const [filteredVendors, setFilteredVendors] = useState<Vendor[]>([]);
  const [radius, setRadius] = useState(2); // km
  const [pincode, setPincode] = useState(initialLocation?.pincode || '');
  const [loading, setLoading] = useState(false);
  const [filters, setFilters] = useState({
    category: '' as string,
    openNow: false,
    subscriptionAvailable: false,
  });

  // TODO: Implement real geolocation API call
  const fetchVendorsNearby = async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams({
        radius: radius.toString(),
        pincode: pincode || 'current',
        ...(filters.category && { category: filters.category }),
        ...(filters.openNow && { openNow: 'true' }),
        ...(filters.subscriptionAvailable && { subscriptionAvailable: 'true' }),
      });

      const response = await fetch(`/api/vendors/nearby?${params}`, {
        headers: { 'Content-Type': 'application/json' },
      });

      if (!response.ok) throw new Error('Failed to fetch vendors');
      const data: Vendor[] = await response.json();
      setVendors(data);
      setFilteredVendors(data);
    } catch (error) {
      console.error('Error fetching vendors:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (pincode) {
      fetchVendorsNearby();
    }
  }, [radius, filters, pincode]);

  const handleCategoryChange = (category: string) => {
    setFilters((prev) => ({
      ...prev,
      category: prev.category === category ? '' : category,
    }));
  };

  const handleOpenNowToggle = () => {
    setFilters((prev) => ({
      ...prev,
      openNow: !prev.openNow,
    }));
  };

  const handleSubscriptionToggle = () => {
    setFilters((prev) => ({
      ...prev,
      subscriptionAvailable: !prev.subscriptionAvailable,
    }));
  };

  return (
    <ScrollView style={styles.container} showsVerticalScrollIndicator={false}>
      {/* Pincode Input */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>{t('vendor.story')}</Text>
        <View style={styles.pincodeInput}>
          <MaterialCommunityIcons name="map-marker" size={20} color="#666" />
          <TextInput
            style={styles.input}
            placeholder="Enter pincode"
            value={pincode}
            onChangeText={setPincode}
            placeholderTextColor="#999"
          />
        </View>
      </View>

      {/* Radius Slider */}
      <View style={styles.section}>
        <View style={styles.radiusHeader}>
          <Text style={styles.radiusLabel}>{t('map.radiusSlider')}</Text>
          <Text style={styles.radiusValue}>{radius.toFixed(1)} km</Text>
        </View>
        <View style={styles.sliderContainer}>
          {[0.5, 1, 2, 3, 5].map((r) => (
            <TouchableOpacity
              key={r}
              style={[styles.sliderButton, radius === r && styles.sliderButtonActive]}
              onPress={() => setRadius(r)}
            >
              <Text style={[styles.sliderText, radius === r && styles.sliderTextActive]}>
                {r}km
              </Text>
            </TouchableOpacity>
          ))}
        </View>
      </View>

      {/* Filters */}
      <View style={styles.section}>
        <Text style={styles.filterTitle}>Filters</Text>
        <View style={styles.filterRow}>
          <TouchableOpacity
            style={[styles.filterTag, filters.openNow && styles.filterTagActive]}
            onPress={handleOpenNowToggle}
          >
            <MaterialCommunityIcons
              name="clock-outline"
              size={14}
              color={filters.openNow ? '#fff' : '#666'}
            />
            <Text style={[styles.filterText, filters.openNow && styles.filterTextActive]}>
              {t('map.openNow')}
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.filterTag, filters.subscriptionAvailable && styles.filterTagActive]}
            onPress={handleSubscriptionToggle}
          >
            <MaterialCommunityIcons
              name="checkbox-marked"
              size={14}
              color={filters.subscriptionAvailable ? '#fff' : '#666'}
            />
            <Text style={[styles.filterText, filters.subscriptionAvailable && styles.filterTextActive]}>
              {t('map.subscriptionAvailable')}
            </Text>
          </TouchableOpacity>
        </View>
      </View>

      {/* Vendor List */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>
          {t('map.nearbyVendors')} ({filteredVendors.length})
        </Text>
        {loading ? (
          <Text style={styles.loadingText}>{t('common.loading')}</Text>
        ) : filteredVendors.length === 0 ? (
          <Text style={styles.emptyText}>No vendors found in this area</Text>
        ) : (
          <FlatList
            data={filteredVendors}
            keyExtractor={(item) => item.id.toString()}
            renderItem={({ item }) => (
              <VendorCard
                vendor={item}
                onViewProfile={() => onVendorSelect?.(item.id)}
                onVoiceOrder={() => onVendorSelect?.(item.id)}
                onSubscribe={() => onVendorSelect?.(item.id)}
              />
            )}
            scrollEnabled={false}
            nestedScrollEnabled={false}
          />
        )}
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f9f9f9',
    paddingBottom: 20,
  },
  section: {
    paddingHorizontal: 16,
    paddingVertical: 12,
    backgroundColor: '#fff',
    marginBottom: 12,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: '#000',
    marginBottom: 12,
  },
  pincodeInput: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    paddingHorizontal: 12,
    backgroundColor: '#f5f5f5',
  },
  input: {
    flex: 1,
    paddingVertical: 10,
    paddingHorizontal: 8,
    fontSize: 14,
    color: '#333',
  },
  radiusHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 10,
  },
  radiusLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: '#333',
  },
  radiusValue: {
    fontSize: 14,
    color: '#2E7D32',
    fontWeight: '700',
  },
  sliderContainer: {
    flexDirection: 'row',
    gap: 8,
  },
  sliderButton: {
    flex: 1,
    paddingVertical: 8,
    paddingHorizontal: 6,
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 6,
    alignItems: 'center',
  },
  sliderButtonActive: {
    backgroundColor: '#2E7D32',
    borderColor: '#2E7D32',
  },
  sliderText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#666',
  },
  sliderTextActive: {
    color: '#fff',
  },
  filterTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#333',
    marginBottom: 10,
  },
  filterRow: {
    flexDirection: 'row',
    gap: 8,
    flexWrap: 'wrap',
  },
  filterTag: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 20,
    backgroundColor: '#fff',
  },
  filterTagActive: {
    backgroundColor: '#2E7D32',
    borderColor: '#2E7D32',
  },
  filterText: {
    fontSize: 12,
    fontWeight: '500',
    color: '#666',
  },
  filterTextActive: {
    color: '#fff',
  },
  loadingText: {
    textAlign: 'center',
    color: '#999',
    paddingVertical: 20,
  },
  emptyText: {
    textAlign: 'center',
    color: '#999',
    paddingVertical: 20,
  },
});
