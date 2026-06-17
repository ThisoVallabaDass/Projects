// TODO: Integrate with user profile API to persist preferredLocale
import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { View, TouchableOpacity, Text, StyleSheet } from 'react-native';

interface LanguageSwitcherProps {
  userId?: number;
}

export const LanguageSwitcher: React.FC<LanguageSwitcherProps> = ({ userId }) => {
  const { i18n } = useTranslation();
  const [currentLang, setCurrentLang] = useState<string>(i18n.language);

  const toggleLanguage = async (lang: 'en' | 'ta') => {
    setCurrentLang(lang);
    await i18n.changeLanguage(lang);

    // TODO: Persist to user profile via PUT /api/users/{id}/locale
    if (userId) {
      try {
        const response = await fetch(`/api/users/${userId}/locale`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ preferredLocale: lang }),
        });
        // Handle response
      } catch (error) {
        console.error('Failed to update locale:', error);
      }
    }
  };

  return (
    <View style={styles.container}>
      <TouchableOpacity
        style={[styles.button, currentLang === 'en' && styles.active]}
        onPress={() => toggleLanguage('en')}
      >
        <Text style={[styles.text, currentLang === 'en' && styles.activeText]}>
          English
        </Text>
      </TouchableOpacity>
      <TouchableOpacity
        style={[styles.button, currentLang === 'ta' && styles.active]}
        onPress={() => toggleLanguage('ta')}
      >
        <Text style={[styles.text, currentLang === 'ta' && styles.activeText]}>
          தமிழ்
        </Text>
      </TouchableOpacity>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    padding: 8,
    backgroundColor: '#f5f5f5',
    borderRadius: 8,
    gap: 8,
  },
  button: {
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 6,
    backgroundColor: '#fff',
    borderWidth: 1,
    borderColor: '#ddd',
  },
  active: {
    backgroundColor: '#2E7D32',
    borderColor: '#2E7D32',
  },
  text: {
    color: '#333',
    fontSize: 14,
    fontWeight: '500',
  },
  activeText: {
    color: '#fff',
  },
});
