import React from 'react';
import { Pressable, Text, View } from 'react-native';
import { router } from 'expo-router';
import { AppIcon, Card, Screen, SectionTitle, StatusPill } from '../components/Ui';
import MetricCard from '../components/MetricCard';
import { formatDate, formatMoney } from '../data/formatters';
import { useStore } from '../store/StoreProvider';
import { colors, createThemeAwareStyles } from '../theme';

const dateKey = (date) => [date.getFullYear(), String(date.getMonth() + 1).padStart(2, '0'), String(date.getDate()).padStart(2, '0')].join('-');

function activityTitle(entry) {
  const action = String(entry.action || '').toLowerCase();
  const target = entry.targetName || entry.details?.productName || entry.details?.customerName || '';
  const known = { new_sale: 'New sale completed', add_product: 'Added new product', edit_product: 'Edited product', delete_product: 'Deleted product', add_customer: 'Added customer', edit_customer: 'Updated customer', delete_customer: 'Deleted customer' };
  const label = known[action] || action.split('_').filter(Boolean).map((word) => word[0].toUpperCase() + word.slice(1)).join(' ') || 'Store activity';
  return target ? `${label}: ${target}` : label;
}

export default function DashboardScreen() {
  const store = useStore();
  const today = dateKey(new Date());
  const ownerName = store.activeEmployee?.name || store.profile?.ownerName || 'Owner';
  const firstName = ownerName.split(' ')[0];
  const allSales = store.sales.filter((sale) => sale.status !== 'refunded');
  const todaySales = allSales.filter((sale) => sale.date === today);
  const revenue = todaySales.reduce((sum, sale) => sum + sale.total, 0);
  const profit = todaySales.reduce((sum, sale) => sum + sale.items.reduce((subtotal, item) => subtotal + (item.price - item.cost) * item.qty - item.discount, 0), 0);
  const productCount = new Set(store.products.map((product) => product.firestoreId || product.id)).size;
  const totalStock = store.products.reduce((sum, product) => sum + product.stock, 0);
  const lowStock = store.products.filter((product) => product.stock > 0 && product.stock <= 10).sort((a, b) => a.stock - b.stock);
  const todayDate = new Date(`${today}T00:00:00`);
  const expiring = store.products.map((product) => {
    const days = product.expiryDate ? Math.floor((new Date(`${product.expiryDate}T00:00:00`) - todayDate) / 86_400_000) : Infinity;
    return { ...product, daysToExpiry: days };
  }).filter((product) => product.daysToExpiry <= 30).sort((a, b) => a.daysToExpiry - b.daysToExpiry);
  const activity = store.activityLogs.slice(0, 5);
  const showAlerts = store.settings.notificationsEnabled !== false;
  const totalRevenue = allSales.reduce((sum, sale) => sum + sale.total, 0);

  const overview = [
    { label: 'Total products', value: String(productCount), icon: 'pricetags-outline', page: '/(tabs)/products', tone: 'teal' },
    { label: 'Total stock', value: `${totalStock.toLocaleString()} pcs`, icon: 'cube-outline', page: '/inventory', tone: 'teal' },
    { label: 'Low stock', value: String(lowStock.length), icon: 'alert-circle-outline', page: '/inventory', tone: lowStock.length ? 'gold' : 'mint' },
    { label: 'Expiry alerts', value: String(expiring.length), icon: 'calendar-outline', page: '/expiry', tone: expiring.length ? 'coral' : 'mint' },
  ];
  const actions = [
    { label: 'New sale', icon: 'cart-outline', page: '/(tabs)/sales' },
    { label: 'Add product', icon: 'add-circle-outline', page: '/(tabs)/products' },
    { label: 'Restock', icon: 'cube-outline', page: '/inventory' },
    { label: 'Utang', icon: 'wallet-outline', page: '/utang' },
    { label: 'Reports', icon: 'bar-chart-outline', page: '/reports' },
    { label: 'Customers', icon: 'people-outline', page: '/customers' },
  ];

  return <Screen title="Dashboard" showHeader={false}>
    <View style={styles.welcome}><Text style={styles.welcomeTitle}>Hello, {firstName}</Text><Text style={styles.welcomeStore}>{store.settings.storeName}</Text></View>

    <Card style={styles.storeCard}>
      <View style={styles.storeTitle}><View style={styles.storeIcon}><AppIcon name="storefront-outline" size={19} color={colors.primary} /></View><Text style={styles.storeName} numberOfLines={1}>{store.settings.storeName || 'Store Overview'}</Text></View>
      <Text style={styles.storeSummary}>{productCount} products  •  {allSales.length} sales  •  {formatMoney(totalRevenue)} lifetime revenue</Text>
      <Text style={styles.storeLatest}>Latest: {store.activityLogs[0] ? activityTitle(store.activityLogs[0]) : 'No activity yet'}</Text>
    </Card>

    <View style={styles.todayGrid}><MetricCard label="Today’s revenue" value={formatMoney(revenue)} note={`${todaySales.length} sales`} icon="wallet-outline" tone="teal" /><MetricCard label="Today’s profit" value={formatMoney(profit)} note="After product costs" icon="trending-up-outline" tone="mint" /></View>

    <SectionTitle title="Overview" />
    <View style={styles.overviewGrid}>{overview.map((item) => <Pressable key={item.label} accessibilityRole="button" onPress={() => router.push(item.page)} style={({ pressed }) => [styles.overviewTile, pressed && styles.pressed]}><View style={[styles.overviewIcon, styles[`tone_${item.tone}`]]}><AppIcon name={item.icon} size={20} color={item.tone === 'gold' ? colors.warning : item.tone === 'coral' ? colors.error : item.tone === 'mint' ? colors.success : colors.primary} /></View><Text style={styles.overviewValue}>{item.value}</Text><Text style={styles.overviewLabel}>{item.label}</Text></Pressable>)}</View>

    <SectionTitle title="Quick actions" />
    <View style={styles.actionGrid}>{actions.map((item) => <Pressable key={item.label} accessibilityRole="button" onPress={() => router.push(item.page)} style={({ pressed }) => [styles.actionTile, pressed && styles.pressed]}><AppIcon name={item.icon} size={22} color={colors.accent} /><Text style={styles.actionLabel}>{item.label}</Text></Pressable>)}</View>

    {showAlerts && expiring.length > 0 && <>
      <SectionTitle title="Expiry alerts" action={<Pressable onPress={() => router.push('/expiry')} style={styles.link}><Text style={styles.linkText}>See all</Text><AppIcon name="arrow-forward" size={15} color={colors.primary} /></Pressable>} />
      <Card style={styles.rows}>{expiring.slice(0, 5).map((product) => <Pressable key={product.id} onPress={() => router.push('/expiry')} style={styles.alertRow}><View style={[styles.alertDot, styles.dotError]} /><View style={styles.rowCopy}><Text style={styles.rowTitle} numberOfLines={1}>{product.name}</Text><Text style={styles.rowDetail}>{product.variantName || product.category} · {formatDate(product.expiryDate)}</Text></View><StatusPill label={product.daysToExpiry < 0 ? 'Expired' : product.daysToExpiry === 0 ? 'Today' : `${product.daysToExpiry} days`} tone={product.daysToExpiry < 0 ? 'warning' : 'neutral'} /></Pressable>)}</Card>
    </>}

    {showAlerts && lowStock.length > 0 && <>
      <SectionTitle title="Low inventory" action={<Pressable onPress={() => router.push('/inventory')} style={styles.link}><Text style={styles.linkText}>See all</Text><AppIcon name="arrow-forward" size={15} color={colors.primary} /></Pressable>} />
      <Card style={styles.rows}>{lowStock.slice(0, 5).map((product) => <Pressable key={product.id} onPress={() => router.push('/inventory')} style={styles.alertRow}><View style={[styles.alertDot, styles.dotWarning]} /><View style={styles.rowCopy}><Text style={styles.rowTitle} numberOfLines={1}>{product.name}</Text><Text style={styles.rowDetail}>{product.category} · restock level {product.minStock}</Text></View><StatusPill label={`${product.stock} left`} tone="warning" /></Pressable>)}</Card>
    </>}

    <SectionTitle title="Recent activity" action={<Pressable onPress={() => router.push('/reports')} style={styles.link}><Text style={styles.linkText}>See all</Text><AppIcon name="arrow-forward" size={15} color={colors.primary} /></Pressable>} />
    <Card style={styles.rows}>{activity.map((entry) => <View key={entry.id} style={styles.alertRow}><View style={[styles.alertDot, styles.dotPrimary]} /><View style={styles.rowCopy}><Text style={styles.rowTitle} numberOfLines={2}>{activityTitle(entry)}</Text><Text style={styles.rowDetail}>{entry.timestamp ? formatDate(String(entry.timestamp).slice(0, 10)) : ''} · {entry.employeeName || 'Store owner'}</Text></View></View>)}{!activity.length && <Text style={styles.empty}>No recent activity yet.</Text>}</Card>
  </Screen>;
}

const styles = createThemeAwareStyles({
  welcome: { alignItems: 'center', paddingHorizontal: 20, paddingVertical: 18, borderRadius: 15, backgroundColor: colors.primary },
  welcomeTitle: { color: '#FFFFFF', fontSize: 20, fontWeight: '700' },
  welcomeStore: { color: '#E5EEEA', fontSize: 14, marginTop: 3 },
  storeCard: { padding: 14 },
  storeTitle: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  storeIcon: { width: 34, height: 34, alignItems: 'center', justifyContent: 'center', borderRadius: 10, backgroundColor: colors.primarySoft },
  storeName: { flex: 1, color: colors.text, fontSize: 15, fontWeight: '800' },
  storeSummary: { color: colors.muted, fontSize: 14, lineHeight: 21, marginTop: 8 },
  storeLatest: { color: colors.text, fontSize: 14, lineHeight: 20, marginTop: 5 },
  todayGrid: { flexDirection: 'row', gap: 9 },
  overviewGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 9 },
  overviewTile: { width: '48.5%', minHeight: 79, flexDirection: 'row', alignItems: 'center', gap: 9, padding: 11, borderWidth: 1, borderColor: colors.border, borderRadius: 14, backgroundColor: colors.surface },
  overviewIcon: { width: 36, height: 36, alignItems: 'center', justifyContent: 'center', borderRadius: 11 },
  tone_teal: { backgroundColor: colors.primarySoft }, tone_gold: { backgroundColor: colors.warningSoft }, tone_mint: { backgroundColor: colors.successSoft }, tone_coral: { backgroundColor: '#FBE9E6' },
  overviewValue: { color: colors.text, fontSize: 16, fontWeight: '800' },
  overviewLabel: { color: colors.muted, fontSize: 12, marginTop: 2 },
  actionGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  actionTile: { width: '31.5%', minHeight: 76, alignItems: 'center', justifyContent: 'center', gap: 5, paddingHorizontal: 5, borderWidth: 1, borderColor: colors.border, borderRadius: 13, backgroundColor: colors.surface },
  actionLabel: { color: colors.text, fontSize: 13, fontWeight: '600', textAlign: 'center' },
  pressed: { opacity: .76 },
  link: { minHeight: 38, flexDirection: 'row', alignItems: 'center', gap: 4, paddingHorizontal: 4 },
  linkText: { color: colors.primary, fontSize: 14, fontWeight: '700' },
  rows: { paddingHorizontal: 13, paddingVertical: 3 },
  alertRow: { minHeight: 62, flexDirection: 'row', alignItems: 'center', gap: 10, paddingVertical: 8, borderBottomWidth: 1, borderBottomColor: '#EDF1EF' },
  alertDot: { width: 10, height: 10, borderRadius: 5 }, dotError: { backgroundColor: colors.error }, dotWarning: { backgroundColor: '#B17D12' }, dotPrimary: { backgroundColor: colors.primary },
  rowCopy: { flex: 1, minWidth: 0, gap: 3 },
  rowTitle: { color: colors.text, fontSize: 14, fontWeight: '700' },
  rowDetail: { color: colors.muted, fontSize: 12 },
  empty: { color: colors.muted, textAlign: 'center', fontSize: 14, padding: 18 },
});
