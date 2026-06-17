import React from 'react';
import { Text, StyleSheet } from 'react-native';

const ICONS = {
  'shopping-cart': '🛒',
  'user-circle': '👤',
  'envelope': '✉️',
  'phone': '📞',
  'map-marker': '📍',
  'user-tag': '🏷️',
  'map-o': '🗺️',
  'heart-o': '🤍',
  'star-o': '⭐',
  'bell-o': '🔔',
  'store': '🏪',
  'briefcase': '💼',
  'cog': '⚙️',
  'question-circle': '❓',
  'info-circle': 'ℹ️',
  'sign-out': '🚪',
  'home': '🏠',
  'list': '📋',
  'user': '👤',
  'chevron-right': '›',
  'image': '🖼️',
  'trash': '🗑️',
  'clock-o': '⏰',
  'cog': '⚙️',
  'truck': '🚚',
  'check-circle': '✓',
  'times-circle': '✕',
  'inbox': '📥',
  'location-arrow': '📍',
  'search': '🔍',
  'plus': '➕',
  'minus': '➖',
  'star': '⭐',
};

export default function Icon({ name, size = 20, color = '#000' }) {
  const iconChar = ICONS[name] || '❓';
  return (
    <Text style={[styles.icon, { fontSize: size * 0.8, color }]}>
      {iconChar}
    </Text>
  );
}

const styles = StyleSheet.create({
  icon: {
    textAlignVertical: 'center',
  },
});
