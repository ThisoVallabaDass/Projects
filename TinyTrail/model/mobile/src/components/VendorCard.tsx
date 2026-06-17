// TODO: Review vendor distance calculation and integrate with real maps
import React from 'react';
import { useTranslation } from 'react-i18next';
import { View, Text, Image, TouchableOpacity, StyleSheet } from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';

interface Vendor {
  id: number;
  name: string;
  tagline: string;
  avatar?: string;
  specialties: string[];
  distance: number; // in km
  rating?: number;
  isVerifiedHomeKitchen?: boolean;
}

interface VendorCardProps {
  vendor: Vendor;
  onViewProfile: (vendorId: number) => void;
  onVoiceOrder: (vendorId: number) => void;
  onSubscribe: (vendorId: number) => void;
}

export const VendorCard: React.FC<VendorCardProps> = ({
  vendor,
  onViewProfile,
  onVoiceOrder,
  onSubscribe,
}) => {
  const { t } = useTranslation();

  return (
    <View style={styles.card}>
      {/* Hero Image */}
      <View style={styles.imageContainer}>
        {vendor.avatar ? (
          <Image source={{ uri: vendor.avatar }} style={styles.image} />
        ) : (
          <View style={[styles.image, styles.placeholderImage]}>
            <MaterialCommunityIcons name="store" size={40} color="#ccc" />
          </View>
        )}
        {vendor.isVerifiedHomeKitchen && (
          <View style={styles.badge}>
            <MaterialCommunityIcons name="check-circle" size={16} color="#fff" />
            <Text style={styles.badgeText}>{t('vendor.verified')}</Text>
          </View>
        )}
      </View>

      {/* Content */}
      <View style={styles.content}>
        <Text style={styles.name}>{vendor.name}</Text>
        <Text style={styles.tagline}>{vendor.tagline}</Text>

        {/* Specialties */}
        {vendor.specialties && vendor.specialties.length > 0 && (
          <View style={styles.specialties}>
            {vendor.specialties.slice(0, 2).map((specialty, idx) => (
              <View key={idx} style={styles.badge}>
                <Text style={styles.badgeText}>{specialty}</Text>
              </View>
            ))}
          </View>
        )}

        {/* Distance and Rating */}
        <View style={styles.metaRow}>
          <View style={styles.distanceContainer}>
            <MaterialCommunityIcons name="map-marker" size={14} color="#666" />
            <Text style={styles.distance}>
              {vendor.distance.toFixed(1)} {t('vendor.distance')}
            </Text>
          </View>
          {vendor.rating && (
            <View style={styles.ratingContainer}>
              <MaterialCommunityIcons name="star" size={14} color="#FFC107" />
              <Text style={styles.rating}>{vendor.rating.toFixed(1)}</Text>
            </View>
          )}
        </View>

        {/* Actions */}
        <View style={styles.actions}>
          <TouchableOpacity
            style={[styles.btn, styles.btnOutline]}
            onPress={() => onViewProfile(vendor.id)}
          >
            <MaterialCommunityIcons name="information-outline" size={16} color="#2E7D32" />
            <Text style={styles.btnTextOutline}>{t('vendor.story')}</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.btn, styles.btnOutline]}
            onPress={() => onVoiceOrder(vendor.id)}
          >
            <MaterialCommunityIcons name="microphone" size={16} color="#2E7D32" />
            <Text style={styles.btnTextOutline}>{t('vendor.voiceOrder')}</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.btn, styles.btnPrimary]}
            onPress={() => onSubscribe(vendor.id)}
          >
            <Text style={styles.btnTextPrimary}>{t('vendor.subscribe')}</Text>
          </TouchableOpacity>
        </View>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#fff',
    borderRadius: 12,
    overflow: 'hidden',
    marginHorizontal: 8,
    marginVertical: 8,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 3,
    elevation: 3,
  },
  imageContainer: {
    position: 'relative',
    width: '100%',
    height: 160,
  },
  image: {
    width: '100%',
    height: '100%',
  },
  placeholderImage: {
    backgroundColor: '#f0f0f0',
    justifyContent: 'center',
    alignItems: 'center',
  },
  badge: {
    position: 'absolute',
    top: 8,
    right: 8,
    backgroundColor: '#2E7D32',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  badgeText: {
    color: '#fff',
    fontSize: 12,
    fontWeight: '600',
  },
  content: {
    padding: 12,
  },
  name: {
    fontSize: 18,
    fontWeight: '700',
    color: '#000',
    marginBottom: 4,
  },
  tagline: {
    fontSize: 12,
    color: '#666',
    marginBottom: 8,
  },
  specialties: {
    flexDirection: 'row',
    gap: 6,
    marginBottom: 8,
    flexWrap: 'wrap',
  },
  metaRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 10,
  },
  distanceContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  distance: {
    fontSize: 12,
    color: '#666',
  },
  ratingContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  rating: {
    fontSize: 12,
    fontWeight: '600',
    color: '#FFC107',
  },
  actions: {
    flexDirection: 'row',
    gap: 6,
    flexWrap: 'wrap',
  },
  btn: {
    paddingHorizontal: 10,
    paddingVertical: 8,
    borderRadius: 6,
    alignItems: 'center',
    justifyContent: 'center',
    flexDirection: 'row',
    gap: 4,
    flex: 1,
    minWidth: 80,
  },
  btnOutline: {
    borderWidth: 1,
    borderColor: '#2E7D32',
    backgroundColor: '#fff',
  },
  btnTextOutline: {
    fontSize: 11,
    color: '#2E7D32',
    fontWeight: '600',
  },
  btnPrimary: {
    backgroundColor: '#2E7D32',
  },
  btnTextPrimary: {
    fontSize: 11,
    color: '#fff',
    fontWeight: '600',
  },
});
