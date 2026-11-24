import React from 'react';
import { Pressable, Text, View } from 'react-native';
import { router } from 'expo-router';
import { AppButton, AppIcon, Card, Screen } from '../components/Ui';
import { useStore } from '../store/StoreProvider';
import { colors, createThemeAwareStyles } from '../theme';

const links = [
  { title: 'Inventory', subtitle: 'Stock levels and restocking', icon: 'cube-outline', route: '/inventory' },
  { title: 'Expiry', subtitle: 'Check product dates and alerts', icon: 'hourglass-outline', route: '/expiry' },
  { title: 'Reports', subtitle: 'Sales and product performance', icon: 'bar-chart-outline', route: '/reports' },
  { title: 'Utang', subtitle: 'Customer balances and payments', icon: 'wallet-outline', route: '/utang' },
  { title: 'Notes & tasks', subtitle: 'Store reminders and to-dos', icon: 'create-outline', route: '/notes' },
  { title: 'Categories', subtitle: 'Organize the product catalog', icon: 'pricetags-outline', route: '/categories' },
  { title: 'Customers', subtitle: 'Customer details and purchase history', icon: 'people-outline', route: '/customers' },
  { title: 'Team', subtitle: 'Store staff profiles', icon: 'person-outline', route: '/team' },
  { title: 'Settings', subtitle: 'Store preferences and alerts', icon: 'settings-outline', route: '/settings' },
];

export default function MoreScreen() {
  const store = useStore();
  return <Screen title="More" subtitle={store.settings.storeName}>
    <Card style={styles.activeEmployee}><View style={styles.linkIcon}><AppIcon name="person-outline" size={21} color={colors.primary} /></View><View style={styles.linkCopy}><Text style={styles.linkTitle}>Using StorePro as</Text><Text style={styles.linkSubtitle}>{store.activeEmployee?.name || 'Store owner'}</Text></View><AppButton title="Switch" compact variant="outline" onPress={store.switchEmployee} /></Card>
    <View style={styles.linkList}>{links.map((item) => <Pressable key={item.route} onPress={() => router.push(item.route)} style={({ pressed }) => [styles.linkCard, pressed && styles.pressed]} accessibilityRole="button"><View style={styles.linkIcon}><AppIcon name={item.icon} size={21} color={colors.primary} /></View><View style={styles.linkCopy}><Text style={styles.linkTitle}>{item.title}</Text><Text style={styles.linkSubtitle}>{item.subtitle}</Text></View><AppIcon name="chevron-forward" size={19} color="#74847C" /></Pressable>)}</View>
  </Screen>;
}

const styles = createThemeAwareStyles({
  activeEmployee: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  linkList: { gap: 9 },
  linkCard: { minHeight: 72, flexDirection: 'row', alignItems: 'center', gap: 12, paddingHorizontal: 13, paddingVertical: 10, borderWidth: 1, borderColor: colors.border, borderRadius: 14, backgroundColor: colors.surface },
  pressed: { opacity: .75 },
  linkIcon: { width: 43, height: 43, borderRadius: 13, backgroundColor: '#E9F0EC', alignItems: 'center', justifyContent: 'center' },
  linkCopy: { flex: 1, gap: 4 },
  linkTitle: { color: colors.text, fontSize: 15, fontWeight: '800' },
  linkSubtitle: { color: colors.muted, fontSize: 13 },
});
