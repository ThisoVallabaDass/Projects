import React from 'react';
import { View, StyleSheet, TouchableOpacity } from 'react-native';
import { Text, Card, Button } from 'react-native-paper';
import { useDispatch, useSelector } from 'react-redux';
import { useTranslation } from 'react-i18next';

import { RootState, AppDispatch } from '../store';
import { setPincode } from '../store/pincodeSlice';

export default function PincodeSearch() {
  const { t } = useTranslation();
  const dispatch = useDispatch<AppDispatch>();
  
  const { currentPincode, isValid } = useSelector((state: RootState) => state.pincode);

  const handlePincodeChange = (pincode: string) => {
    // Only allow digits and limit to 6 characters
    const cleanPincode = pincode.replace(/\D/g, '').slice(0, 6);
    dispatch(setPincode(cleanPincode));
  };

  return (
    <View style={styles.container}>
      <Text variant="bodyMedium" style={styles.label}>
        {t('home.enterPincode')}
      </Text>
      <View style={styles.inputContainer}>
        <Text
          style={[
            styles.pincodeInput,
            isValid ? styles.validInput : styles.invalidInput
          ]}
        >
          {currentPincode || 'Enter 6-digit pincode'}
        </Text>
        <Button
          mode="text"
          onPress={() => handlePincodeChange('')}
          disabled={!currentPincode}
          style={styles.clearButton}
        >
          Clear
        </Button>
      </View>
      
      {/* Pincode Digits */}
      <View style={styles.digitsContainer}>
        {[1, 2, 3, 4, 5, 6].map((digit) => (
          <TouchableOpacity
            key={digit}
            style={[
              styles.digitButton,
              currentPincode.length >= digit ? styles.filledDigit : styles.emptyDigit
            ]}
            onPress={() => {
              const newPincode = currentPincode + digit.toString();
              if (newPincode.length <= 6) {
                dispatch(setPincode(newPincode));
              }
            }}
          >
            <Text style={styles.digitText}>
              {currentPincode[digit - 1] || ''}
            </Text>
          </TouchableOpacity>
        ))}
      </View>
      
      {/* Number Pad */}
      <View style={styles.numberPad}>
        {[
          [1, 2, 3],
          [4, 5, 6],
          [7, 8, 9],
          ['', 0, '⌫']
        ].map((row, rowIndex) => (
          <View key={rowIndex} style={styles.numberRow}>
            {row.map((num, colIndex) => (
              <TouchableOpacity
                key={colIndex}
                style={styles.numberButton}
                onPress={() => {
                  if (num === '⌫') {
                    dispatch(setPincode(currentPincode.slice(0, -1)));
                  } else if (typeof num === 'number') {
                    const newPincode = currentPincode + num.toString();
                    if (newPincode.length <= 6) {
                      dispatch(setPincode(newPincode));
                    }
                  }
                }}
              >
                <Text style={styles.numberText}>
                  {num === '⌫' ? '⌫' : num}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        ))}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    paddingVertical: 16,
  },
  label: {
    marginBottom: 8,
    fontWeight: '500',
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 16,
  },
  pincodeInput: {
    fontSize: 18,
    fontWeight: 'bold',
    paddingVertical: 8,
    paddingHorizontal: 12,
    borderRadius: 8,
    borderWidth: 2,
    borderColor: '#E0E0E0',
    minWidth: 200,
    textAlign: 'center',
  },
  validInput: {
    borderColor: '#2E7D32',
    backgroundColor: '#E8F5E8',
  },
  invalidInput: {
    borderColor: '#E0E0E0',
    backgroundColor: '#F5F5F5',
  },
  clearButton: {
    marginLeft: 8,
  },
  digitsContainer: {
    flexDirection: 'row',
    justifyContent: 'center',
    marginBottom: 24,
    gap: 8,
  },
  digitButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 2,
  },
  filledDigit: {
    backgroundColor: '#2E7D32',
    borderColor: '#2E7D32',
  },
  emptyDigit: {
    backgroundColor: 'transparent',
    borderColor: '#E0E0E0',
  },
  digitText: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#2E7D32',
  },
  numberPad: {
    gap: 8,
  },
  numberRow: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 8,
  },
  numberButton: {
    width: 60,
    height: 60,
    borderRadius: 30,
    backgroundColor: '#E0E0E0',
    justifyContent: 'center',
    alignItems: 'center',
  },
  numberText: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#333',
  },
});
