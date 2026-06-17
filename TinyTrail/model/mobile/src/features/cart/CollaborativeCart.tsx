// TODO: Install runtime dependencies:
// npm install @stomp/stompjs sockjs-client
// TODO: Add auth headers when integrating with real auth

import React, { useEffect, useState, useRef } from 'react';
import { View, Text, TextInput, TouchableOpacity, FlatList, StyleSheet, Alert } from 'react-native';
import { useTranslation } from 'react-i18next';

// STOMP client imports (ensure packages installed)
import { Client } from '@stomp/stompjs';
import SockJS from 'sockjs-client';

interface CartItem {
  id?: number;
  productId: number;
  quantity: number;
  addedByUserId?: number | null;
}

export const CollaborativeCart: React.FC = () => {
  const { t } = useTranslation();
  const [code, setCode] = useState('');
  const [joinedCode, setJoinedCode] = useState<string | null>(null);
  const [items, setItems] = useState<CartItem[]>([]);
  const [wsConnected, setWsConnected] = useState(false);
  const stompRef = useRef<Client | null>(null);
  const [newProductId, setNewProductId] = useState('');
  const [newQuantity, setNewQuantity] = useState('1');

  const API = (path: string) => `${process.env.REACT_APP_API_URL || 'http://localhost:8080'}${path}`;
  const WS_URL = process.env.REACT_APP_WS_URL || 'http://localhost:8080/ws-cart';

  useEffect(() => {
    // Clean up on unmount
    return () => {
      disconnectStomp();
    };
  }, []);

  const connectStomp = (cartCode: string) => {
    if (stompRef.current) {
      stompRef.current.deactivate();
      stompRef.current = null;
    }

    const socketFactory = () => new SockJS(WS_URL);
    const client = new Client({
      webSocketFactory: socketFactory,
      debug: (_str: string) => {
        // console.log(str);
      },
      reconnectDelay: 5000,
    });

    client.onConnect = (_frame: unknown) => {
      setWsConnected(true);
      // Subscribe to topic for this code
      client.subscribe(`/topic/cart/${cartCode}`, (message: { body: string }) => {
        try {
          const payload = JSON.parse(message.body);
          // payload is the CollaborativeCart object; update items
          if (payload && payload.items) {
            setItems(payload.items || []);
          }
        } catch (err) {
          console.error('Failed parsing cart message', err);
        }
      });
    };

    client.onStompError = (frame: unknown) => {
      console.error('STOMP error', frame);
    };

    client.activate();
    stompRef.current = client;
  };

  const disconnectStomp = () => {
    try {
      stompRef.current?.deactivate();
    } catch (e) {
      // ignore
    }
    stompRef.current = null;
    setWsConnected(false);
  };

  const createSharedCart = async () => {
    try {
      const res = await fetch(API('/api/carts/create'), { method: 'POST' });
      if (!res.ok) throw new Error('Failed to create');
      const data = await res.json();
      const c = data.code;
      setJoinedCode(c);
      connectStomp(c);
      Alert.alert('Shared cart created', `Code: ${c}`);
    } catch (err) {
      console.error(err);
      Alert.alert('Error', 'Could not create cart');
    }
  };

  const joinSharedCart = async () => {
    if (!code || code.length < 1) return;
    try {
      const res = await fetch(API('/api/carts/join'), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ code }),
      });
      if (!res.ok) throw new Error('Invalid code');
      const data = await res.json();
      // data is the collaborative cart including items
      setItems(data.items || []);
      setJoinedCode(code);
      connectStomp(code);
    } catch (err) {
      console.error(err);
      Alert.alert('Error', 'Could not join cart');
    }
  };

  const addItem = async () => {
    if (!joinedCode) return Alert.alert('Join a cart first');
    try {
      const body = { productId: Number(newProductId), quantity: Number(newQuantity), userId: null };
      const res = await fetch(API(`/api/cart/${joinedCode}/add`), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });
      if (!res.ok) throw new Error('Add failed');
      // optimistic update
      setItems((prev) => [...prev, { productId: Number(newProductId), quantity: Number(newQuantity) }]);
      setNewProductId('');
      setNewQuantity('1');
    } catch (err) {
      console.error(err);
      Alert.alert('Error', 'Could not add item');
    }
  };

  const removeItem = async (itemId?: number) => {
    if (!joinedCode || itemId == null) return;
    try {
      const res = await fetch(API(`/api/cart/${joinedCode}/remove`), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ itemId }),
      });
      if (!res.ok) throw new Error('Remove failed');
      setItems((prev) => prev.filter((it) => it.id !== itemId));
    } catch (err) {
      console.error(err);
      Alert.alert('Error', 'Could not remove item');
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>{t('sharedCart.createCart')}</Text>

      <View style={styles.row}>
        <TouchableOpacity style={styles.primaryBtn} onPress={createSharedCart}>
          <Text style={styles.primaryBtnText}>{t('sharedCart.createCart')}</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>{t('sharedCart.joinCart')}</Text>
        <View style={styles.row}>
          <TextInput style={styles.input} placeholder={t('sharedCart.enterCode')} value={code} onChangeText={setCode} />
          <TouchableOpacity style={styles.btn} onPress={joinSharedCart}>
            <Text style={styles.btnText}>{t('sharedCart.joinCart')}</Text>
          </TouchableOpacity>
        </View>
      </View>

      {joinedCode && (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Code: {joinedCode} {wsConnected ? '(live)' : '(connecting...)'}</Text>

          <View style={styles.addRow}>
            <TextInput style={styles.inputSmall} placeholder="ProductId" value={newProductId} onChangeText={setNewProductId} keyboardType="numeric" />
            <TextInput style={styles.inputSmall} placeholder="Qty" value={newQuantity} onChangeText={setNewQuantity} keyboardType="numeric" />
            <TouchableOpacity style={styles.btn} onPress={addItem}><Text style={styles.btnText}>Add</Text></TouchableOpacity>
          </View>

          <FlatList
            data={items}
            keyExtractor={(item, idx) => `${item.id ?? idx}-${item.productId}`}
            renderItem={({ item }) => (
              <View style={styles.itemRow}>
                <Text style={styles.itemText}>Product {item.productId} x {item.quantity} {item.addedByUserId ? `(by ${item.addedByUserId})` : ''}</Text>
                <TouchableOpacity onPress={() => removeItem(item.id)}>
                  <Text style={styles.removeText}>Remove</Text>
                </TouchableOpacity>
              </View>
            )}
          />
        </View>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, padding: 16, backgroundColor: '#fff' },
  title: { fontSize: 20, fontWeight: '700', marginBottom: 12 },
  row: { flexDirection: 'row', gap: 8, alignItems: 'center', marginBottom: 12 },
  section: { marginTop: 12, padding: 12, backgroundColor: '#f9f9f9', borderRadius: 8 },
  sectionTitle: { fontSize: 14, fontWeight: '600', marginBottom: 8 },
  input: { flex: 1, borderWidth: 1, borderColor: '#ddd', borderRadius: 6, paddingHorizontal: 8, height: 40 },
  inputSmall: { width: 80, borderWidth: 1, borderColor: '#ddd', borderRadius: 6, paddingHorizontal: 8, height: 40 },
  btn: { backgroundColor: '#2E7D32', paddingHorizontal: 12, paddingVertical: 8, borderRadius: 6 },
  btnText: { color: '#fff', fontWeight: '600' },
  primaryBtn: { backgroundColor: '#2E7D32', padding: 12, borderRadius: 8, alignItems: 'center' },
  primaryBtnText: { color: '#fff', fontWeight: '700' },
  addRow: { flexDirection: 'row', gap: 8, alignItems: 'center', marginBottom: 12 },
  itemRow: { flexDirection: 'row', justifyContent: 'space-between', paddingVertical: 8, borderBottomWidth: 1, borderBottomColor: '#eee' },
  itemText: { color: '#333' },
  removeText: { color: '#D32F2F' }
});
