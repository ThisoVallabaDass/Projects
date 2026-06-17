import React from 'react';
import i18n from '../i18n';

type Props = { userId?: number };

export const LanguageSwitcher: React.FC<Props> = ({ userId }) => {
  const change = async (lng: string) => {
    await i18n.changeLanguage(lng);
    // TODO: Persist preferredLocale for user via PUT /api/users/{id}/locale
    if (userId) {
      fetch(`/api/users/${userId}/locale`, { method: 'PUT', headers: { 'Content-Type':'application/json' }, body: JSON.stringify({ locale: lng }) });
    }
  };

  return (
    <div className="flex items-center space-x-2">
      <button onClick={() => change('en')} className="px-3 py-1 rounded bg-gray-100">EN</button>
      <button onClick={() => change('ta')} className="px-3 py-1 rounded bg-gray-100">TA</button>
    </div>
  );
};

export default LanguageSwitcher;
