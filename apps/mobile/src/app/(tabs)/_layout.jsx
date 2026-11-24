import React from 'react';
import { Tabs } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { Platform } from 'react-native';
import { colors, useAppTheme } from '../../theme';

const icons = {
  index: ['grid-outline', 'grid'],
  products: ['pricetags-outline', 'pricetags'],
  sales: ['cart-outline', 'cart'],
  more: ['apps-outline', 'apps'],
};

export default function TabLayout() {
  useAppTheme();
  return (
    <Tabs screenOptions={({ route }) => ({
      headerShown: false,
      tabBarActiveTintColor: colors.primary,
      tabBarInactiveTintColor: colors.muted,
      tabBarLabelStyle: { fontSize: 12, fontWeight: '700', marginTop: 2 },
      tabBarStyle: {
        height: Platform.OS === 'ios' ? 82 : 68,
        paddingTop: 8,
        paddingBottom: Platform.OS === 'ios' ? 20 : 8,
        borderTopColor: colors.border,
        backgroundColor: colors.surface,
        elevation: 10,
      },
      tabBarIcon: ({ color, size, focused }) => {
        const pair = icons[route.name] || icons.index;
        return <Ionicons name={pair[focused ? 1 : 0]} size={size} color={color} />;
      },
    })}>
      <Tabs.Screen name="index" options={{ title: 'Home', tabBarAccessibilityLabel: 'Dashboard' }} />
      <Tabs.Screen name="products" options={{ title: 'Products' }} />
      <Tabs.Screen name="sales" options={{ title: 'Sales' }} />
      <Tabs.Screen name="more" options={{ title: 'More' }} />
    </Tabs>
  );
}
