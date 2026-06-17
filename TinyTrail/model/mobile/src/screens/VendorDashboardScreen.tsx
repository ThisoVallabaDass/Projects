import React, { useEffect, useState } from 'react';
import { View, StyleSheet, ScrollView, Alert } from 'react-native';
import { Text, Card, Button, SegmentedButtons, ActivityIndicator } from 'react-native-paper';
import * as ImagePicker from 'expo-image-picker';
import * as Location from 'expo-location';
import { Ionicons } from '@expo/vector-icons';
import client from '../api/client';

interface HygieneResult {
  hygiene_score: number;
  badge_text: string;
  predicted_class: string;
  confidence: number;
  go_live_allowed?: boolean;
  reason?: string;
}

type ShiftStage = 'ready' | 'camera' | 'processing' | 'result' | 'live';

export default function VendorDashboardScreen() {
  const [vendorType, setVendorType] = useState<'food' | 'nonFood'>('food');
  const [stage, setStage] = useState<ShiftStage>('ready');
  const [locationLabel, setLocationLabel] = useState('600062');
  const [hygieneResult, setHygieneResult] = useState<HygieneResult | null>(null);
  const [resultPassed, setResultPassed] = useState(false);

  useEffect(() => {
    const loadVendorProfile = async () => {
      try {
        const response = await client.get('/vendors/me');
        setLocationLabel(response.data.pincode || '600062');
      } catch (_error) {
        setLocationLabel('600062');
      }
    };

    loadVendorProfile();
  }, []);

  const startShift = async () => {
    if (vendorType === 'nonFood') {
      const { status } = await Location.requestForegroundPermissionsAsync();
      if (status !== 'granted') {
        Alert.alert('Location needed', 'Please allow GPS so nearby customers can find you.');
        return;
      }

      setStage('live');
      return;
    }

    setStage('camera');
  };

  const runHygieneCheck = async () => {
    const permission = await ImagePicker.requestCameraPermissionsAsync();
    if (!permission.granted) {
      Alert.alert('Camera needed', 'Please allow camera access for the hygiene check.');
      return;
    }

    const result = await ImagePicker.launchCameraAsync({
      allowsEditing: true,
      aspect: [4, 3],
      quality: 0.9,
    });

    if (result.canceled) {
      return;
    }

    setStage('processing');

    try {
      const asset = result.assets[0];
      const formData = new FormData();
      formData.append('workspaceImage', {
        uri: asset.uri,
        type: 'image/jpeg',
        name: 'workspace.jpg',
      } as any);

      const response = await client.post('/hygiene/check', formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });

      const passed = response.data.go_live_allowed !== false;
      setHygieneResult(response.data);
      setResultPassed(passed);
      setStage('result');

      if (passed) {
        setTimeout(() => {
          setStage('live');
        }, 1200);
      }
    } catch (error: any) {
      setStage('camera');
      Alert.alert(
        'Hygiene check failed',
        error?.response?.data?.details || error?.response?.data?.error || 'Please try again.'
      );
    }
  };

  const renderReady = () => (
    <View style={styles.centerStage}>
      <View style={styles.readyBadge}>
        <Ionicons name="storefront" size={28} color="#FFFFFF" />
      </View>
      <Text style={styles.readyEyebrow}>VENDOR MODE</Text>
      <Text style={styles.readyTitle}>Start My Shift</Text>
      <Text style={styles.readyText}>
        Go live only when you are ready to take hails, incoming orders, and nearby customer requests.
      </Text>

      <SegmentedButtons
        value={vendorType}
        onValueChange={(value) => setVendorType(value as 'food' | 'nonFood')}
        style={styles.segmented}
        buttons={[
          { value: 'food', label: 'Food Vendor' },
          { value: 'nonFood', label: 'Non-Food Vendor' },
        ]}
      />

      <Card style={styles.logicCard}>
        <Card.Content>
          <Text style={styles.logicTitle}>
            {vendorType === 'food' ? 'Daily hygiene check required' : 'Quick go-live flow'}
          </Text>
          <Text style={styles.logicText}>
            {vendorType === 'food'
              ? 'We will open the camera, scan your workspace, and allow you to go live only after the hygiene check passes.'
              : 'We will ask for GPS permission, mark you active, and start broadcasting your live location to nearby customers.'}
          </Text>
        </Card.Content>
      </Card>

      <Button mode="contained" onPress={startShift} style={styles.startButton} buttonColor="#227A3B" icon="play-circle">
        Start My Shift
      </Button>
    </View>
  );

  const renderCamera = () => (
    <View style={styles.cameraStage}>
      <Text style={styles.cameraTitle}>Center your workspace or cart inside the box</Text>
      <View style={styles.cameraFrame}>
        <View style={styles.dashedBox}>
          <Ionicons name="scan-outline" size={42} color="#FFFFFF" />
          <Text style={styles.cameraHint}>Tap capture to open the camera and take today&apos;s hygiene photo.</Text>
        </View>
      </View>
      <Button mode="contained" onPress={runHygieneCheck} style={styles.captureButton} buttonColor="#1667D9" icon="camera">
        Capture and Check
      </Button>
    </View>
  );

  const renderProcessing = () => (
    <View style={styles.centerStage}>
      <ActivityIndicator size="large" color="#227A3B" />
      <Text style={styles.readyTitle}>TinyTrails AI is checking your workspace...</Text>
      <Text style={styles.readyText}>Scanning hygiene markers and preparing your go-live result.</Text>
    </View>
  );

  const renderResult = () => (
    <View style={styles.centerStage}>
      <Ionicons
        name={resultPassed ? 'checkmark-circle' : 'alert-circle'}
        size={92}
        color={resultPassed ? '#1F9D55' : '#D97706'}
      />
      <Text style={styles.readyTitle}>
        {resultPassed ? 'Hygiene Standards Met!' : 'Hold on! Our AI noticed something missing.'}
      </Text>
      <Text style={styles.readyText}>
        {resultPassed
          ? `Score: ${hygieneResult?.hygiene_score}%. Have a great day of sales.`
          : hygieneResult?.reason || 'Please tidy the workspace and try again.'}
      </Text>

      {!!hygieneResult?.reason && resultPassed && (
        <Text style={styles.resultHint}>{hygieneResult.reason}</Text>
      )}

      {!resultPassed && (
        <Button mode="contained" onPress={() => setStage('camera')} style={styles.retryButton} buttonColor="#D97706">
          Fix it and Try Again
        </Button>
      )}
    </View>
  );

  const renderLiveDashboard = () => (
    <ScrollView contentContainerStyle={styles.liveContent}>
      <Card style={styles.statusCard}>
        <Card.Content>
          <View style={styles.statusHeader}>
            <View>
              <Text style={styles.statusTitle}>Live Status</Text>
              <Text style={styles.statusSubtext}>Broadcasting from: {locationLabel} (Moving)</Text>
            </View>
            <View style={styles.liveDotWrap}>
              <View style={styles.liveDot} />
              <Text style={styles.liveText}>Active</Text>
            </View>
          </View>

          <Button
            mode="contained-tonal"
            onPress={() => setStage('ready')}
            style={styles.endShiftButton}
            buttonColor="#FDE8E8"
            textColor="#B42318"
            icon="stop-circle-outline"
          >
            End Shift
          </Button>
        </Card.Content>
      </Card>

      <Card style={styles.meritCard}>
        <Card.Content>
          <Text style={styles.meritBadge}>Gold Star Vendor</Text>
          <Text style={styles.meritScore}>Your Merit Score: 4.8 / 5.0</Text>
          <Text style={styles.meritText}>
            You are in the Top 10% of vendors in your pincode. You are currently being recommended to 50+ nearby customers.
          </Text>
        </Card.Content>
      </Card>

      <Card style={styles.queueCard}>
        <Card.Content>
          <Text style={styles.queueTitle}>Digital Hails</Text>
          <View style={styles.hailCard}>
            <Text style={styles.hailText}>Someone 200m away wants you to stop.</Text>
            <View style={styles.queueActions}>
              <Button mode="contained" buttonColor="#227A3B">Accept</Button>
              <Button mode="outlined" textColor="#173250">Ignore</Button>
            </View>
          </View>
        </Card.Content>
      </Card>

      <Card style={styles.queueCard}>
        <Card.Content>
          <Text style={styles.queueTitle}>Incoming Orders</Text>
          <View style={styles.orderRow}>
            <Text style={styles.orderName}>2x Mini Meals</Text>
            <Text style={styles.orderMeta}>Ready in 15 mins</Text>
          </View>
          <View style={styles.orderRow}>
            <Text style={styles.orderName}>1x Lemon Rice Combo</Text>
            <Text style={styles.orderMeta}>Pickup queue</Text>
          </View>
        </Card.Content>
      </Card>
    </ScrollView>
  );

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Vendor Live Console</Text>
        <Text style={styles.headerSubtitle}>Start shift, clear hygiene, and go live for nearby customers.</Text>
      </View>

      {stage === 'ready' && renderReady()}
      {stage === 'camera' && renderCamera()}
      {stage === 'processing' && renderProcessing()}
      {stage === 'result' && renderResult()}
      {stage === 'live' && renderLiveDashboard()}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F4F8F4',
  },
  header: {
    backgroundColor: '#227A3B',
    paddingHorizontal: 20,
    paddingTop: 22,
    paddingBottom: 18,
  },
  headerTitle: {
    color: '#FFFFFF',
    fontSize: 28,
    fontWeight: '800',
  },
  headerSubtitle: {
    color: '#D8F5DF',
    marginTop: 6,
    fontSize: 14,
  },
  centerStage: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
  },
  readyBadge: {
    width: 84,
    height: 84,
    borderRadius: 999,
    backgroundColor: '#227A3B',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 18,
  },
  readyEyebrow: {
    color: '#227A3B',
    fontSize: 12,
    fontWeight: '800',
    letterSpacing: 1.2,
    marginBottom: 8,
  },
  readyTitle: {
    color: '#173250',
    fontSize: 28,
    fontWeight: '800',
    textAlign: 'center',
  },
  readyText: {
    marginTop: 10,
    color: '#607086',
    fontSize: 15,
    lineHeight: 22,
    textAlign: 'center',
    maxWidth: 320,
  },
  segmented: {
    width: '100%',
    maxWidth: 340,
    marginTop: 22,
  },
  logicCard: {
    marginTop: 18,
    width: '100%',
    maxWidth: 340,
    borderRadius: 20,
    backgroundColor: '#FFFFFF',
  },
  logicTitle: {
    color: '#173250',
    fontSize: 16,
    fontWeight: '800',
  },
  logicText: {
    marginTop: 8,
    color: '#607086',
    lineHeight: 20,
  },
  startButton: {
    marginTop: 24,
    borderRadius: 18,
    width: '100%',
    maxWidth: 340,
    paddingVertical: 8,
  },
  cameraStage: {
    flex: 1,
    padding: 20,
  },
  cameraTitle: {
    color: '#173250',
    fontSize: 22,
    fontWeight: '800',
    textAlign: 'center',
    marginTop: 18,
    marginBottom: 18,
  },
  cameraFrame: {
    flex: 1,
    backgroundColor: '#173250',
    borderRadius: 28,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 20,
  },
  dashedBox: {
    width: '100%',
    height: '74%',
    borderWidth: 2,
    borderColor: '#FFFFFF',
    borderStyle: 'dashed',
    borderRadius: 24,
    alignItems: 'center',
    justifyContent: 'center',
  },
  cameraHint: {
    color: '#EAF2FF',
    marginTop: 12,
    textAlign: 'center',
    maxWidth: 260,
  },
  captureButton: {
    marginTop: 18,
    borderRadius: 18,
    paddingVertical: 8,
  },
  retryButton: {
    marginTop: 18,
    borderRadius: 18,
    paddingVertical: 8,
    minWidth: 220,
  },
  resultHint: {
    marginTop: 12,
    color: '#607086',
    lineHeight: 20,
    textAlign: 'center',
    maxWidth: 320,
  },
  liveContent: {
    padding: 18,
    paddingBottom: 30,
  },
  statusCard: {
    borderRadius: 24,
    backgroundColor: '#FFFFFF',
  },
  statusHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  statusTitle: {
    fontSize: 20,
    fontWeight: '800',
    color: '#173250',
  },
  statusSubtext: {
    color: '#607086',
    marginTop: 4,
  },
  liveDotWrap: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  liveDot: {
    width: 12,
    height: 12,
    borderRadius: 999,
    backgroundColor: '#16A34A',
  },
  liveText: {
    color: '#16A34A',
    fontWeight: '700',
  },
  endShiftButton: {
    marginTop: 18,
    borderRadius: 16,
  },
  meritCard: {
    marginTop: 16,
    borderRadius: 24,
    backgroundColor: '#E3F6E8',
  },
  meritBadge: {
    color: '#227A3B',
    fontWeight: '800',
    textTransform: 'uppercase',
    letterSpacing: 1,
    marginBottom: 10,
  },
  meritScore: {
    color: '#173250',
    fontSize: 24,
    fontWeight: '800',
  },
  meritText: {
    marginTop: 10,
    color: '#31455E',
    lineHeight: 21,
  },
  queueCard: {
    marginTop: 16,
    borderRadius: 24,
    backgroundColor: '#FFFFFF',
  },
  queueTitle: {
    color: '#173250',
    fontSize: 18,
    fontWeight: '800',
    marginBottom: 12,
  },
  hailCard: {
    backgroundColor: '#E7F7EC',
    borderRadius: 18,
    padding: 14,
  },
  hailText: {
    color: '#173250',
    fontWeight: '700',
    fontSize: 15,
  },
  queueActions: {
    flexDirection: 'row',
    gap: 10,
    marginTop: 14,
  },
  orderRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 10,
    borderBottomWidth: 1,
    borderBottomColor: '#EEF2F7',
  },
  orderName: {
    color: '#173250',
    fontWeight: '700',
  },
  orderMeta: {
    color: '#607086',
  },
});
