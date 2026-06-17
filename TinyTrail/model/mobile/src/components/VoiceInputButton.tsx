import React, { useState, useEffect } from 'react';
import { View, StyleSheet, Alert } from 'react-native';
import { Text, Button, ActivityIndicator } from 'react-native-paper';
import { Ionicons } from '@expo/vector-icons';
import { useTranslation } from 'react-i18next';

// Note: This is a placeholder implementation
// In a real app, you would use react-native-voice or expo-speech
// For now, we'll simulate voice input

interface VoiceInputButtonProps {
  onResult: (text: string) => void;
  disabled?: boolean;
}

export default function VoiceInputButton({ onResult, disabled = false }: VoiceInputButtonProps) {
  const { t } = useTranslation();
  const [listening, setListening] = useState(false);
  const [permissionGranted, setPermissionGranted] = useState(false);

  useEffect(() => {
    // Check microphone permission
    checkPermission();
  }, []);

  const checkPermission = async () => {
    // In a real implementation, you would check microphone permissions
    // For now, we'll assume permission is granted
    setPermissionGranted(true);
  };

  const startListening = async () => {
    if (!permissionGranted) {
      Alert.alert(
        'Permission Required',
        'Microphone permission is required for voice input. Please enable it in settings.',
        [{ text: 'OK' }]
      );
      return;
    }

    setListening(true);
    
    // Simulate voice recognition process
    setTimeout(() => {
      // Mock voice recognition result
      const mockResults = [
        'Fresh tomatoes from local farm',
        'Organic vegetables available',
        'Homemade dairy products',
        'Fresh fruits and vegetables',
        'Local spices and herbs'
      ];
      
      const randomResult = mockResults[Math.floor(Math.random() * mockResults.length)];
      onResult(randomResult);
      setListening(false);
    }, 2000);
  };

  const stopListening = () => {
    setListening(false);
  };

  if (!permissionGranted) {
    return (
      <Button
        mode="outlined"
        onPress={checkPermission}
        disabled={disabled}
        icon="microphone-off"
        style={styles.button}
      >
        Enable Microphone
      </Button>
    );
  }

  return (
    <View style={styles.container}>
      <Button
        mode={listening ? "contained" : "outlined"}
        onPress={listening ? stopListening : startListening}
        disabled={disabled}
        icon={listening ? "stop" : "microphone"}
        style={[
          styles.button,
          listening && styles.listeningButton
        ]}
        contentStyle={styles.buttonContent}
      >
        {listening ? t('seller.listening') : t('seller.tapToSpeak')}
      </Button>
      
      {listening && (
        <View style={styles.listeningIndicator}>
          <ActivityIndicator size="small" color="#2E7D32" />
          <Text variant="bodySmall" style={styles.listeningText}>
            Speak now...
          </Text>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
  },
  button: {
    marginVertical: 8,
    borderColor: '#2E7D32',
  },
  listeningButton: {
    backgroundColor: '#2E7D32',
  },
  buttonContent: {
    paddingVertical: 8,
  },
  listeningIndicator: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 8,
  },
  listeningText: {
    marginLeft: 8,
    color: '#2E7D32',
  },
});
