// TODO: Integrate image upload with /api/seller/generate-photo endpoint
// TODO: Add handwritten menu OCR and LLM text rewriting via /api/seller/clean-menu
// TODO: Handle multipart form data for image uploads
import React, { useState, useRef } from 'react';
import { useTranslation } from 'react-i18next';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  TextInput,
  ScrollView,
  Image,
  ActivityIndicator,
} from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';

interface ProductFormData {
  title: string;
  price: string;
  category: string;
  image?: string;
  handwrittenMenu?: string;
  spiceLevel: 'mild' | 'medium' | 'hot' | 'very_hot';
  delivery: boolean;
  pickup: boolean;
  customOptions: Array<{ key: string; value: string }>;
}

interface SellerProductFormProps {
  onSubmit?: (data: ProductFormData) => Promise<void>;
  onCancel?: () => void;
}

export const SellerProductForm: React.FC<SellerProductFormProps> = ({
  onSubmit,
  onCancel,
}) => {
  const { t } = useTranslation();
  const [form, setForm] = useState<ProductFormData>({
    title: '',
    price: '',
    category: 'snacks',
    spiceLevel: 'medium',
    delivery: true,
    pickup: true,
    customOptions: [],
  });
  const [interimVoiceText, setInterimVoiceText] = useState('');
  const [isListening, setIsListening] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [loading, setLoading] = useState(false);
  const recognitionRef = useRef<any>(null);

  const startVoiceInput = () => {
    if (!('webkitSpeechRecognition' in window) && !('SpeechRecognition' in window)) {
      alert('Speech Recognition not supported');
      return;
    }

    const SpeechRecognition = (window as any).webkitSpeechRecognition || (window as any).SpeechRecognition;
    recognitionRef.current = new SpeechRecognition();
    recognitionRef.current.lang = 'en-IN';
    recognitionRef.current.interimResults = true;

    recognitionRef.current.onstart = () => setIsListening(true);

    recognitionRef.current.onresult = (event: any) => {
      let interim = '';
      for (let i = event.resultIndex; i < event.results.length; i++) {
        if (event.results[i].isFinal) {
          setForm((prev) => ({
            ...prev,
            title: prev.title + event.results[i][0].transcript,
          }));
        } else {
          interim += event.results[i][0].transcript;
        }
      }
      setInterimVoiceText(interim);
    };

    recognitionRef.current.onend = () => setIsListening(false);
    recognitionRef.current.start();
  };

  const stopVoiceInput = () => {
    if (recognitionRef.current) {
      recognitionRef.current.stop();
      setIsListening(false);
    }
  };

  // TODO: Integrate image upload with /api/seller/generate-photo
  const handleImageUpload = async () => {
    // Placeholder for image picker
    setUploading(true);
    try {
      // Mock upload - real implementation would use ImagePicker
      const mockImageUrl = 'https://via.placeholder.com/200';
      setForm((prev) => ({ ...prev, image: mockImageUrl }));
    } catch (error) {
      console.error('Image upload failed:', error);
    } finally {
      setUploading(false);
    }
  };

  // TODO: Integrate menu cleaning via /api/seller/clean-menu
  const handleMenuUpload = async () => {
    setUploading(true);
    try {
      // Placeholder for menu OCR
      setForm((prev) => ({ ...prev, handwrittenMenu: 'Mock menu image URL' }));
    } catch (error) {
      console.error('Menu upload failed:', error);
    } finally {
      setUploading(false);
    }
  };

  const addCustomOption = () => {
    setForm((prev) => ({
      ...prev,
      customOptions: [...prev.customOptions, { key: '', value: '' }],
    }));
  };

  const removeCustomOption = (index: number) => {
    setForm((prev) => ({
      ...prev,
      customOptions: prev.customOptions.filter((_, i) => i !== index),
    }));
  };

  const handleSubmit = async () => {
    setLoading(true);
    try {
      if (onSubmit) {
        await onSubmit(form);
      }
    } catch (error) {
      console.error('Form submission failed:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <ScrollView style={styles.container} showsVerticalScrollIndicator={false}>
      {/* Title with Voice Input */}
      <View style={styles.section}>
        <View style={styles.label}>
          <Text style={styles.labelText}>{t('seller.productTitle')}</Text>
          <TouchableOpacity
            style={styles.voiceBtn}
            onPress={isListening ? stopVoiceInput : startVoiceInput}
          >
            <MaterialCommunityIcons
              name={isListening ? 'microphone-off' : 'microphone'}
              size={16}
              color="#2E7D32"
            />
          </TouchableOpacity>
        </View>
        <TextInput
          style={styles.input}
          placeholder="e.g., Homemade Murukku"
          value={form.title}
          onChangeText={(text) => setForm((prev) => ({ ...prev, title: text }))}
          placeholderTextColor="#999"
        />
        {interimVoiceText && (
          <Text style={styles.interimText}>{interimVoiceText}</Text>
        )}
      </View>

      {/* Price */}
      <View style={styles.section}>
        <Text style={styles.labelText}>{t('seller.price')}</Text>
        <View style={styles.priceInput}>
          <Text style={styles.currencySymbol}>₹</Text>
          <TextInput
            style={styles.input}
            placeholder="0.00"
            value={form.price}
            onChangeText={(text) => setForm((prev) => ({ ...prev, price: text }))}
            keyboardType="decimal-pad"
            placeholderTextColor="#999"
          />
        </View>
      </View>

      {/* Category */}
      <View style={styles.section}>
        <Text style={styles.labelText}>{t('seller.category')}</Text>
        <View style={styles.categoryGrid}>
          {['snacks', 'meals', 'sweets', 'beverages'].map((cat) => (
            <TouchableOpacity
              key={cat}
              style={[styles.categoryBtn, form.category === cat && styles.categoryBtnActive]}
              onPress={() => setForm((prev) => ({ ...prev, category: cat }))}
            >
              <Text
                style={[
                  styles.categoryBtnText,
                  form.category === cat && styles.categoryBtnTextActive,
                ]}
              >
                {cat}
              </Text>
            </TouchableOpacity>
          ))}
        </View>
      </View>

      {/* Image Upload */}
      <View style={styles.section}>
        <Text style={styles.labelText}>{t('seller.uploadImage')}</Text>
        {form.image ? (
          <View style={styles.imagePreview}>
            <Image source={{ uri: form.image }} style={styles.image} />
            <TouchableOpacity
              style={styles.removeImageBtn}
              onPress={() => setForm((prev) => ({ ...prev, image: undefined }))}
            >
              <MaterialCommunityIcons name="close" size={20} color="#fff" />
            </TouchableOpacity>
          </View>
        ) : (
          <TouchableOpacity
            style={styles.uploadBtn}
            onPress={handleImageUpload}
            disabled={uploading}
          >
            {uploading ? (
              <ActivityIndicator color="#2E7D32" />
            ) : (
              <>
                <MaterialCommunityIcons name="camera-plus" size={24} color="#2E7D32" />
                <Text style={styles.uploadBtnText}>Upload Image</Text>
              </>
            )}
          </TouchableOpacity>
        )}
      </View>

      {/* Handwritten Menu */}
      <View style={styles.section}>
        <Text style={styles.labelText}>{t('seller.uploadMenu')}</Text>
        <TouchableOpacity
          style={styles.uploadBtn}
          onPress={handleMenuUpload}
          disabled={uploading}
        >
          {uploading ? (
            <ActivityIndicator color="#2E7D32" />
          ) : (
            <>
              <MaterialCommunityIcons name="file-image-plus" size={24} color="#2E7D32" />
              <Text style={styles.uploadBtnText}>Upload Menu</Text>
            </>
          )}
        </TouchableOpacity>
      </View>

      {/* Spice Level */}
      <View style={styles.section}>
        <Text style={styles.labelText}>{t('seller.spiceLevel')}</Text>
        <View style={styles.spiceGrid}>
          {(['mild', 'medium', 'hot', 'very_hot'] as const).map((level) => (
            <TouchableOpacity
              key={level}
              style={[styles.spiceBtn, form.spiceLevel === level && styles.spiceBtnActive]}
              onPress={() => setForm((prev) => ({ ...prev, spiceLevel: level }))}
            >
              <Text
                style={[
                  styles.spiceBtnText,
                  form.spiceLevel === level && styles.spiceBtnTextActive,
                ]}
              >
                {level.replace('_', ' ')}
              </Text>
            </TouchableOpacity>
          ))}
        </View>
      </View>

      {/* Delivery / Pickup */}
      <View style={styles.section}>
        <View style={styles.toggleRow}>
          <TouchableOpacity
            style={[styles.toggleBtn, form.delivery && styles.toggleBtnActive]}
            onPress={() => setForm((prev) => ({ ...prev, delivery: !prev.delivery }))}
          >
            <MaterialCommunityIcons
              name={form.delivery ? 'checkbox-marked' : 'checkbox-blank-outline'}
              size={20}
              color={form.delivery ? '#2E7D32' : '#ccc'}
            />
            <Text style={styles.toggleLabel}>{t('seller.delivery')}</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.toggleBtn, form.pickup && styles.toggleBtnActive]}
            onPress={() => setForm((prev) => ({ ...prev, pickup: !prev.pickup }))}
          >
            <MaterialCommunityIcons
              name={form.pickup ? 'checkbox-marked' : 'checkbox-blank-outline'}
              size={20}
              color={form.pickup ? '#2E7D32' : '#ccc'}
            />
            <Text style={styles.toggleLabel}>{t('seller.pickup')}</Text>
          </TouchableOpacity>
        </View>
      </View>

      {/* Custom Options */}
      <View style={styles.section}>
        <View style={styles.optionHeader}>
          <Text style={styles.labelText}>{t('seller.addOption')}</Text>
          <TouchableOpacity onPress={addCustomOption}>
            <MaterialCommunityIcons name="plus-circle" size={24} color="#2E7D32" />
          </TouchableOpacity>
        </View>
        {form.customOptions.map((option, idx) => (
          <View key={idx} style={styles.optionRow}>
            <TextInput
              style={[styles.input, styles.optionInput]}
              placeholder="Key"
              value={option.key}
              onChangeText={(text) => {
                const updated = [...form.customOptions];
                updated[idx].key = text;
                setForm((prev) => ({ ...prev, customOptions: updated }));
              }}
              placeholderTextColor="#999"
            />
            <TextInput
              style={[styles.input, styles.optionInput]}
              placeholder="Value"
              value={option.value}
              onChangeText={(text) => {
                const updated = [...form.customOptions];
                updated[idx].value = text;
                setForm((prev) => ({ ...prev, customOptions: updated }));
              }}
              placeholderTextColor="#999"
            />
            <TouchableOpacity onPress={() => removeCustomOption(idx)}>
              <MaterialCommunityIcons name="trash-can-outline" size={20} color="#D32F2F" />
            </TouchableOpacity>
          </View>
        ))}
      </View>

      {/* Action Buttons */}
      <View style={styles.actionRow}>
        <TouchableOpacity
          style={[styles.btn, styles.btnOutline]}
          onPress={onCancel}
          disabled={loading}
        >
          <Text style={styles.btnTextOutline}>{t('common.cancel')}</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.btn, styles.btnPrimary]}
          onPress={handleSubmit}
          disabled={loading}
        >
          {loading ? (
            <ActivityIndicator color="#fff" />
          ) : (
            <Text style={styles.btnTextPrimary}>{t('common.save')}</Text>
          )}
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f9f9f9',
    padding: 16,
  },
  section: {
    backgroundColor: '#fff',
    padding: 12,
    borderRadius: 8,
    marginBottom: 12,
  },
  label: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  labelText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#333',
  },
  voiceBtn: {
    padding: 6,
    borderRadius: 6,
    backgroundColor: '#f0f0f0',
  },
  input: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 6,
    paddingHorizontal: 10,
    paddingVertical: 10,
    fontSize: 14,
    color: '#333',
  },
  interimText: {
    fontSize: 12,
    color: '#999',
    fontStyle: 'italic',
    marginTop: 6,
  },
  priceInput: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 6,
    paddingHorizontal: 10,
  },
  currencySymbol: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    marginRight: 4,
  },
  categoryGrid: {
    flexDirection: 'row',
    gap: 8,
    flexWrap: 'wrap',
  },
  categoryBtn: {
    flex: 0.5,
    paddingVertical: 8,
    paddingHorizontal: 10,
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 6,
    alignItems: 'center',
  },
  categoryBtnActive: {
    backgroundColor: '#2E7D32',
    borderColor: '#2E7D32',
  },
  categoryBtnText: {
    fontSize: 12,
    color: '#666',
    fontWeight: '500',
  },
  categoryBtnTextActive: {
    color: '#fff',
  },
  uploadBtn: {
    borderWidth: 2,
    borderColor: '#ddd',
    borderStyle: 'dashed',
    borderRadius: 8,
    paddingVertical: 30,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
  },
  uploadBtnText: {
    fontSize: 14,
    color: '#2E7D32',
    fontWeight: '600',
  },
  imagePreview: {
    position: 'relative',
    width: '100%',
    height: 150,
    borderRadius: 8,
    overflow: 'hidden',
  },
  image: {
    width: '100%',
    height: '100%',
  },
  removeImageBtn: {
    position: 'absolute',
    top: 8,
    right: 8,
    backgroundColor: 'rgba(0,0,0,0.5)',
    borderRadius: 12,
    padding: 4,
  },
  spiceGrid: {
    flexDirection: 'row',
    gap: 8,
    flexWrap: 'wrap',
  },
  spiceBtn: {
    flex: 0.5,
    paddingVertical: 8,
    paddingHorizontal: 10,
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 6,
    alignItems: 'center',
  },
  spiceBtnActive: {
    backgroundColor: '#FF6F00',
    borderColor: '#FF6F00',
  },
  spiceBtnText: {
    fontSize: 12,
    color: '#666',
    fontWeight: '500',
  },
  spiceBtnTextActive: {
    color: '#fff',
  },
  toggleRow: {
    flexDirection: 'row',
    gap: 12,
  },
  toggleBtn: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingVertical: 8,
  },
  toggleBtnActive: {},
  toggleLabel: {
    fontSize: 14,
    color: '#333',
    fontWeight: '500',
  },
  optionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 10,
  },
  optionRow: {
    flexDirection: 'row',
    gap: 8,
    alignItems: 'center',
    marginBottom: 8,
  },
  optionInput: {
    flex: 1,
  },
  actionRow: {
    flexDirection: 'row',
    gap: 10,
    marginBottom: 24,
  },
  btn: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: 6,
    alignItems: 'center',
    justifyContent: 'center',
  },
  btnOutline: {
    borderWidth: 1,
    borderColor: '#2E7D32',
    backgroundColor: '#fff',
  },
  btnTextOutline: {
    color: '#2E7D32',
    fontWeight: '600',
    fontSize: 14,
  },
  btnPrimary: {
    backgroundColor: '#2E7D32',
  },
  btnTextPrimary: {
    color: '#fff',
    fontWeight: '600',
    fontSize: 14,
  },
});
