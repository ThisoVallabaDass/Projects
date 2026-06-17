import React, { useState } from 'react';

export const AIConcierge: React.FC = () => {
  const [transcript, setTranscript] = useState('');
  const [response, setResponse] = useState<any>(null);

  const send = async () => {
    const res = await fetch('/api/ai/query', { method: 'POST', headers: { 'Content-Type':'application/json' }, body: JSON.stringify({ text: transcript, locale: 'en' }) });
    const data = await res.json();
    setResponse(data);
  };

  return (
    <div className="p-4 bg-white rounded shadow">
      <textarea value={transcript} onChange={e => setTranscript(e.target.value)} className="w-full p-2 border rounded" placeholder="Talk or type..." />
      <div className="flex space-x-2 mt-2">
        <button onClick={send} className="px-4 py-2 bg-indigo-600 text-white rounded">Send</button>
      </div>
      {response && (
        <div className="mt-4 bg-gray-50 p-3 rounded">
          <div className="font-semibold">AI:</div>
          <div className="text-sm">{response.text}</div>
        </div>
      )}
    </div>
  );
};

export default AIConcierge;
