import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';

export async function initI18n() {
  await i18n
    .use(initReactI18next)
    .init({
      lng: 'en',
      fallbackLng: 'en',
      interpolation: { escapeValue: false },
      resources: {
        en: { translation: await (await fetch('/locales/en/translation.json')).json() },
        ta: { translation: await (await fetch('/locales/ta/translation.json')).json() },
      }
    });
}

export default i18n;

// TODO: Call initI18n early in app entry (e.g., src/main.tsx) and wire user locale persistence.
