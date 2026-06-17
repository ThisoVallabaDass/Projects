declare module '@stomp/stompjs' {
  export class Client {
    constructor(config?: Record<string, unknown>);
    onConnect?: (frame: unknown) => void;
    onStompError?: (frame: unknown) => void;
    activate(): void;
    deactivate(): void;
    subscribe(destination: string, callback: (message: { body: string }) => void): void;
  }
}

declare module 'sockjs-client' {
  const content: any;
  export default content;
}
