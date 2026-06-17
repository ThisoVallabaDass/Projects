import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { Provider } from 'react-redux';
import { Provider as PaperProvider } from 'react-native-paper';
import { store } from './src/store';
import RootNavigator from './src/navigation/RootNavigator';
import './src/i18n/setup';
import { theme } from './src/theme';

export default function App() {
  return (
    <Provider store={store}>
      <PaperProvider theme={theme}>
        <NavigationContainer>
          <RootNavigator />
        </NavigationContainer>
      </PaperProvider>
    </Provider>
  );
}
