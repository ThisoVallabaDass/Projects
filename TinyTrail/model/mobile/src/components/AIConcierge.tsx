// TODO: Integrate real AI API, add rate limiting, sanitize HTML in responses
// TODO: Add fallback for browsers without Web Speech API support
// TODO: Wire AI_API_KEY from environment for real OpenAI/Anthropic integration
import React, { useState, useRef } from 'react';
import { useTranslation } from 'react-i18next';
import {
  View,
  Text,
  TouchableOpacity,
  ScrollView,
  TextInput,
  StyleSheet,
  ActivityIndicator,
} from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';

interface AiResponse {
  text: string;
  intent: 'order' | 'search' | 'info';
  vendorSuggestions?: Array<{ vendorId: number; score: number }>;
  cartDraft?: Array<{ productId: number; quantity: number }>;
  uiActions?: Array<{ type: string; label: string; payload: any }>;
}

interface AIConciergeProps {
  userLocation: { latitude: number; longitude: number };
  onAddToCart?: (items: any[]) => void;
  locale?: 'en' | 'ta';
}

export const AIConcierge: React.FC<AIConciergeProps> = ({
  userLocation,
  onAddToCart,
  locale = 'en',
}) => {
  const { t } = useTranslation();
  const [transcript, setTranscript] = useState('');
  const [interimTranscript, setInterimTranscript] = useState('');
  const [isListening, setIsListening] = useState(false);
  const [response, setResponse] = useState<AiResponse | null>(null);
  const [loading, setLoading] = useState(false);
  const [editedText, setEditedText] = useState('');
  const recognitionRef = useRef<any>(null);

  // TODO: Add Web Speech API initialization with fallback
  const startListening = () => {
    if (!('webkitSpeechRecognition' in window) && !('SpeechRecognition' in window)) {
      alert('Speech Recognition not supported in this browser');
      return;
    }

    const SpeechRecognition = (window as any).webkitSpeechRecognition || (window as any).SpeechRecognition;
    recognitionRef.current = new SpeechRecognition();
    recognitionRef.current.lang = locale === 'ta' ? 'ta-IN' : 'en-IN';
    recognitionRef.current.interimResults = true;

    recognitionRef.current.onstart = () => {
      setIsListening(true);
      setTranscript('');
      setInterimTranscript('');
    };

    recognitionRef.current.onresult = (event: any) => {
      let interim = '';
      for (let i = event.resultIndex; i < event.results.length; i++) {
        const transcriptPart = event.results[i][0].transcript;
        if (event.results[i].isFinal) {
          setTranscript((prev) => prev + transcriptPart);
        } else {
          interim += transcriptPart;
        }
      }
      setInterimTranscript(interim);
    };

    recognitionRef.current.onerror = (event: any) => {
      console.error('Speech recognition error:', event.error);
      setIsListening(false);
    };

    recognitionRef.current.onend = () => {
      setIsListening(false);
    };

    recognitionRef.current.start();
  };

  const stopListening = () => {
    if (recognitionRef.current) {
      recognitionRef.current.stop();
      setIsListening(false);
    }
  };

  const sendQuery = async (text: string = transcript || editedText) => {
    if (!text.trim()) return;

    setLoading(true);
    try {
      // TODO: Add rate limiting (e.g., max 5 requests per minute)
      const res = await fetch('/api/ai/query', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          text,
          locale,
          userLocation,
          preferences: { maxVendors: 3 },
        }),
      });

      if (!res.ok) throw new Error('AI query failed');
      const data: AiResponse = await res.json();
      
      // TODO: Sanitize AI response text to prevent XSS
      setResponse(data);

      if (data.cartDraft && data.cartDraft.length > 0 && onAddToCart) {
        onAddToCart(data.cartDraft);
      }
    } catch (error) {
      console.error('Error querying AI:', error);
      setResponse({
        text: 'Sorry, I could not process your request. Please try again.',
        intent: 'info',
      });
    } finally {
      setLoading(false);
      setEditedText('');
    }
  };

  return (
    <ScrollView style={styles.container} showsVerticalScrollIndicator={false}>
      {/* Voice Recording */}
      <View style={styles.recordingSection}>
        <TouchableOpacity
          style={[styles.recordBtn, isListening && styles.recordBtnActive]}
          onPress={isListening ? stopListening : startListening}
        >
          <MaterialCommunityIcons
            name={isListening ? 'microphone-off' : 'microphone'}
            size={28}
            color={isListening ? '#D32F2F' : '#2E7D32'}
          />
        </TouchableOpacity>

        {isListening && (
          <View style={styles.pulseContainer}>
            <Text style={styles.listeningText}>{t('concierge.listeningText')}</Text>
            <View style={styles.pulse} />
          </View>
        )}
      </View>

      {/* Interim Transcript */}
      {interimTranscript && (
        <View style={styles.transcriptBox}>
          <Text style={styles.transcriptLabel}>{t('concierge.listeningText')}</Text>
          <Text style={styles.interimText}>{interimTranscript}</Text>
        </View>
      )}

      {/* Final Transcript */}
      {transcript && (
        <View style={styles.transcriptBox}>
          <Text style={styles.transcriptLabel}>{t('concierge.finalTranscript')}</Text>
          <Text style={styles.transcriptText}>{transcript}</Text>
        </View>
      )}

      {/* Edit Option */}
      {transcript && !loading && (
        <View style={styles.editSection}>
          <Text style={styles.editLabel}>{t('concierge.editTranscript')}</Text>
          <TextInput
            style={styles.input}
            value={editedText || transcript}
            onChangeText={setEditedText}
            multiline
            placeholder="Edit your message..."
          />
          <TouchableOpacity
            style={styles.sendBtn}
            onPress={() => sendQuery(editedText || transcript)}
          >
            <MaterialCommunityIcons name="send" size={18} color="#fff" />
            <Text style={styles.sendBtnText}>{t('concierge.sendButton')}</Text>
          </TouchableOpacity>
        </View>
      )}

      {/* Loading */}
      {loading && (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#2E7D32" />
          <Text style={styles.loadingText}>{t('common.loading')}</Text>
        </View>
      )}

      {/* Response */}
      {response && !loading && (
        <View style={styles.responseBox}>
          <Text style={styles.responseTitle}>{t('concierge.response')}</Text>
          <Text style={styles.responseText}>{response.text}</Text>

          {response.uiActions && response.uiActions.length > 0 && (
            <View style={styles.actionsContainer}>
              {response.uiActions.map((action, idx) => (
                <TouchableOpacity
                  key={idx}
                  style={styles.actionBtn}
                  onPress={() => {
                    if (action.type === 'add_to_cart' && onAddToCart) {
                      onAddToCart(response.cartDraft || []);
                    }
                  }}
                >
                  <Text style={styles.actionBtnText}>{action.label}</Text>
                </TouchableOpacity>
              ))}
            </View>
          )}
        </View>
      )}
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16,
    backgroundColor: '#f9f9f9',
  },
  recordingSection: {
    alignItems: 'center',
    marginBottom: 24,
  },
  recordBtn: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: '#f0f0f0',
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 2,
    borderColor: '#2E7D32',
  },
  recordBtnActive: {
    backgroundColor: '#ffebee',
    borderColor: '#D32F2F',
  },
  pulseContainer: {
    marginTop: 16,
    alignItems: 'center',
    gap: 8,
  },
  listeningText: {
    fontSize: 14,
    color: '#666',
    fontWeight: '500',
  },
  pulse: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: '#D32F2F',
  },
  transcriptBox: {
    backgroundColor: '#fff',
    borderLeftWidth: 4,
    borderLeftColor: '#2E7D32',
    padding: 12,
    borderRadius: 8,
    marginBottom: 12,
  },
  transcriptLabel: {
    fontSize: 12,
    color: '#999',
    marginBottom: 4,
  },
  transcriptText: {
    fontSize: 14,
    color: '#333',
    lineHeight: 20,
  },
  interimText: {
    fontSize: 14,
    color: '#999',
    fontStyle: 'italic',
    lineHeight: 20,
  },
  editSection: {
    backgroundColor: '#fff',
    padding: 12,
    borderRadius: 8,
    marginBottom: 12,
  },
  editLabel: {
    fontSize: 12,
    color: '#666',
    marginBottom: 8,
    fontWeight: '600',
  },
  input: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 6,
    padding: 10,
    fontSize: 14,
    marginBottom: 10,
    minHeight: 80,
    textAlignVertical: 'top',
  },
  sendBtn: {
    backgroundColor: '#2E7D32',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 10,
    borderRadius: 6,
    gap: 8,
  },
  sendBtnText: {
    color: '#fff',
    fontWeight: '600',
    fontSize: 14,
  },
  loadingContainer: {
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: 24,
  },
  loadingText: {
    marginTop: 12,
    color: '#666',
  },
  responseBox: {
    backgroundColor: '#e8f5e9',
    borderLeftWidth: 4,
    borderLeftColor: '#2E7D32',
    padding: 12,
    borderRadius: 8,
  },
  responseTitle: {
    fontSize: 12,
    fontWeight: '600',
    color: '#2E7D32',
    marginBottom: 8,
  },
  responseText: {
    fontSize: 14,
    color: '#333',
    lineHeight: 20,
    marginBottom: 12,
  },
  actionsContainer: {
    gap: 8,
  },
  actionBtn: {
    backgroundColor: '#2E7D32',
    paddingVertical: 10,
    borderRadius: 6,
    alignItems: 'center',
  },
  actionBtnText: {
    color: '#fff',
    fontWeight: '600',
    fontSize: 13,
  },
});
