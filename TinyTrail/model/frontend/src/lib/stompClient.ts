import { Client } from '@stomp/stompjs';
import SockJS from 'sockjs-client';

let client: Client | null = null;

export function connectWebSocket(onConnect: () => void) {
  if (client) return client;
  client = new Client({
    webSocketFactory: () => new SockJS('/ws'),
    reconnectDelay: 5000,
    onConnect: () => { onConnect(); }
  });
  client.activate();
  return client;
}

export function disconnectWebSocket() {
  if (client) {
    client.deactivate();
    client = null;
  }
}

export default { connectWebSocket, disconnectWebSocket };
