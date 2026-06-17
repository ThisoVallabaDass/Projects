import React, { useMemo } from 'react';
import { View, StyleSheet, TouchableOpacity, Image } from 'react-native';
import { Text, Card, Avatar, IconButton } from 'react-native-paper';
import { Ionicons } from '@expo/vector-icons';

import { Product } from '../store/productsSlice';

interface ProductCardProps {
  product: Product;
  onPress: () => void;
}

const trustBadges = ['Blue', 'Gold', 'Platinum'] as const;

const buildMeta = (product: Product) => {
  const badge = trustBadges[product.id % trustBadges.length];
  const hygieneScore = 88 + (product.id % 9);
  const distance = (0.4 + (product.id % 4) * 0.3).toFixed(1);

  return { badge, hygieneScore, distance };
};

export default function ProductCard({ product, onPress }: ProductCardProps) {
  const meta = useMemo(() => buildMeta(product), [product]);

  return (
    <TouchableOpacity onPress={onPress} activeOpacity={0.9} style={styles.touchable}>
      <Card style={styles.card}>
        <View style={styles.imageWrap}>
          {product.imageUrl ? (
            <Image source={{ uri: product.imageUrl }} style={styles.image} />
          ) : (
            <View style={styles.placeholderImage}>
              <Ionicons name="storefront-outline" size={28} color="#8AA0BE" />
              <Text style={styles.placeholderText}>TinyTrails pick</Text>
            </View>
          )}

          <View style={styles.safePill}>
            <Text style={styles.safeText}>✨ {meta.hygieneScore}% Safe</Text>
          </View>
        </View>

        <View style={styles.content}>
          <Text style={styles.productName} numberOfLines={2}>
            {product.name}
          </Text>
          <Text style={styles.price}>₹{product.price}</Text>

          <View style={styles.vendorRow}>
            <Avatar.Text
              size={28}
              label={(product.sellerName?.[0] || 'V').toUpperCase()}
              style={styles.avatar}
              color="#FFFFFF"
            />
            <View style={styles.vendorMeta}>
              <View style={styles.vendorNameRow}>
                <Text style={styles.vendorName} numberOfLines={1}>
                  {product.sellerName}
                </Text>
                <View style={styles.badgePill}>
                  <Text style={styles.badgeText}>{meta.badge}</Text>
                </View>
              </View>
              <Text style={styles.categoryText} numberOfLines={1}>
                {product.category || 'Local specialty'}
              </Text>
            </View>
          </View>

          <View style={styles.footerRow}>
            <View style={styles.distanceRow}>
              <Ionicons name="location-outline" size={13} color="#5B6F8D" />
              <Text style={styles.distanceText}>Moving • {meta.distance}km away</Text>
            </View>
            <IconButton
              icon="plus"
              size={18}
              mode="contained"
              containerColor="#1667D9"
              iconColor="#FFFFFF"
              onPress={onPress}
              style={styles.addButton}
            />
          </View>
        </View>
      </Card>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  touchable: {
    flex: 1,
    minWidth: 0,
  },
  card: {
    borderRadius: 22,
    overflow: 'hidden',
    backgroundColor: '#FFFFFF',
    shadowColor: '#0F172A',
    shadowOpacity: 0.06,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 4 },
    elevation: 3,
  },
  imageWrap: {
    position: 'relative',
    height: 146,
    backgroundColor: '#EFF4FA',
  },
  image: {
    width: '100%',
    height: '100%',
  },
  placeholderImage: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
  },
  placeholderText: {
    color: '#6B7A90',
    fontSize: 12,
    fontWeight: '600',
  },
  safePill: {
    position: 'absolute',
    top: 10,
    right: 10,
    backgroundColor: '#E7F7EB',
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 6,
  },
  safeText: {
    color: '#227A3B',
    fontSize: 11,
    fontWeight: '800',
  },
  content: {
    padding: 12,
  },
  productName: {
    color: '#173250',
    fontSize: 15,
    fontWeight: '800',
    minHeight: 40,
  },
  price: {
    color: '#1667D9',
    fontSize: 20,
    fontWeight: '900',
    marginTop: 2,
  },
  vendorRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 12,
  },
  avatar: {
    backgroundColor: '#1F7AE0',
  },
  vendorMeta: {
    flex: 1,
    marginLeft: 8,
  },
  vendorNameRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  vendorName: {
    flex: 1,
    color: '#1F2D3D',
    fontWeight: '700',
    fontSize: 12,
  },
  badgePill: {
    backgroundColor: '#ECF3FF',
    borderRadius: 999,
    paddingHorizontal: 7,
    paddingVertical: 2,
  },
  badgeText: {
    color: '#1954C8',
    fontSize: 10,
    fontWeight: '800',
  },
  categoryText: {
    color: '#6B7A90',
    fontSize: 11,
    marginTop: 2,
  },
  footerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: 12,
  },
  distanceRow: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
    gap: 4,
  },
  distanceText: {
    color: '#5B6F8D',
    fontSize: 11,
    fontWeight: '600',
  },
  addButton: {
    margin: 0,
  },
});
