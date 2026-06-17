import React, { useEffect, useState } from 'react';
import { Client, IMessage } from '@stomp/stompjs';
import { connectWebSocket } from '../../lib/stompClient';

type CartItem = { id?: number; productId: number; quantity: number; addedBy?: number };

export const CollaborativeCart: React.FC = () => {
  const [code, setCode] = useState('');
  const [cart, setCart] = useState<any>(null);
  const [client, setClient] = useState<Client | null>(null);

  useEffect(() => {
    const c = connectWebSocket(() => console.log('ws connected'));
    setClient(c as Client);
    return () => { c && c.deactivate(); };
  }, []);

  const create = async () => {
    const res = await fetch('/api/carts/create', { method: 'POST' });
    const data = await res.json();
    setCode(data.code);
    subscribeToCode(data.code);
  };

  const join = async () => {
    if (!code) return;
    const res = await fetch('/api/carts/join', { method: 'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify({ code }) });
    if (res.ok) {
      const data = await res.json();
      setCart(data);
      subscribeToCode(code);
    } else {
      alert('Cart not found');
    }
  };

  const subscribeToCode = (c: string) => {
    if (!client) return;
    client.subscribe('/topic/cart/' + c, (msg: IMessage) => {
      try {
        const body = JSON.parse(msg.body);
        setCart(body);
      } catch (e) {
        console.error('invalid cart body', msg.body);
      }
    });
  };

  const addItem = async () => {
    if (!code) return alert('Join or create a cart first');
    await fetch(`/api/carts/${code}/add`, { method: 'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify({ productId: 101, quantity: 1, userId: 1 }) });
  };

  return (
    <div className="p-4 bg-white rounded shadow">
      <div className="flex space-x-2 mb-3">
        <button onClick={create} className="px-3 py-2 bg-indigo-600 text-white rounded">Create Shared Cart</button>
        <input value={code} onChange={e=>setCode(e.target.value)} placeholder="Enter code" className="border rounded px-2" />
        <button onClick={join} className="px-3 py-2 bg-gray-100 rounded">Join</button>
      </div>
      <div className="mb-3">
        <button onClick={addItem} className="px-3 py-2 bg-green-600 text-white rounded">Add sample item</button>
      </div>
      <div>
        <div className="font-semibold">Cart</div>
        {cart ? (
          <div className="mt-2">
            <div>Code: {cart.cartCode}</div>
            <div>Items:</div>
            <ul>
              {cart.items && cart.items.map((it:any, idx:number) => <li key={idx}>{it.productId} × {it.quantity} (by {it.addedBy})</li>)}
            </ul>
          </div>
        ) : <div className="text-sm text-gray-400">No cart joined</div>}
      </div>
    </div>
  );
};

export default CollaborativeCart;
