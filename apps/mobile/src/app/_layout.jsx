import React from 'react';
import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { StoreProvider } from '../store/StoreProvider';
import AppErrorBoundary from '../components/AppErrorBoundary';
import { colors, ThemeProvider, useAppTheme } from '../theme';

export default function RootLayout() {
  return (
    <SafeAreaProvider>
      <ThemeProvider>
        <ThemedApp />
      </ThemeProvider>
    </SafeAreaProvider>
  );
}

function ThemedApp() {
  const { isDark } = useAppTheme();
  return <>
    <StatusBar style={isDark ? 'light' : 'dark'} backgroundColor={colors.background} />
    <AppErrorBoundary>
      <StoreProvider>
        <Stack screenOptions={{ headerShown: false, contentStyle: { backgroundColor: colors.background }, animation: 'slide_from_right' }}>
          <Stack.Screen name="(tabs)" />
          <Stack.Screen name="inventory" />
          <Stack.Screen name="expiry" />
          <Stack.Screen name="utang" />
          <Stack.Screen name="notes" />
          <Stack.Screen name="reports" />
          <Stack.Screen name="categories" />
          <Stack.Screen name="customers" />
          <Stack.Screen name="team" />
          <Stack.Screen name="settings" />
        </Stack>
      </StoreProvider>
    </AppErrorBoundary>
  </>;
}
