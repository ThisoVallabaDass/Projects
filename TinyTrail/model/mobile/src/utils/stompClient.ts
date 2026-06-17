// Lightweight wrapper to create a STOMP client using @stomp/stompjs + sockjs-client
// This module uses dynamic import to avoid breaking environments where the packages are not installed.
// TODO: Replace with explicit typed client after installing @stomp/stompjs and sockjs-client

export async function createStompClient(wsUrl: string) {
  try {
    const [{ Client }, SockJSModule] = await Promise.all([
      // @ts-ignore
      import('@stomp/stompjs'),
      // @ts-ignore
      import('sockjs-client'),
    ]);

    const SockJS = SockJSModule.default || SockJSModule;

    const client = new Client({
      webSocketFactory: () => new SockJS(wsUrl),
      reconnectDelay: 5000,
    });

    return client;
  } catch (err) {
    console.warn('STOMP or SockJS not installed. Install with `npm install @stomp/stompjs sockjs-client` to enable realtime features.');
    return null;
  }
}

export function disconnectClient(client: any) {
  try {
    client?.deactivate?.();
  } catch (e) {
    // ignore
  }
}
