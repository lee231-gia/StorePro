import React from 'react';
import { ScrollView, Text, View } from 'react-native';
import { Card, Chip, Screen, SectionTitle, SegmentedTabs, StatusPill, TextField } from '../components/Ui';
import MetricCard from '../components/MetricCard';
import { formatDate, formatMoney } from '../data/formatters';
import { useStore } from '../store/StoreProvider';
import { colors, createThemeAwareStyles } from '../theme';

const periods = [{ key: 'hour', label: 'Hour' }, { key: 'today', label: 'Today' }, { key: 'yesterday', label: 'Yesterday' }, { key: 'week', label: 'Week' }, { key: 'month', label: 'Month' }, { key: 'year', label: 'Year' }, { key: 'total', label: 'All time' }, { key: 'custom', label: 'Custom' }];

export default function ReportsScreen() {
  const store = useStore();
  const [tab, setTab] = React.useState('Sales');
  const [period, setPeriod] = React.useState('today');
  const [customFrom, setCustomFrom] = React.useState(() => localDateKey(new Date()));
  const [customTo, setCustomTo] = React.useState(() => localDateKey(new Date()));
  const [hourStart, setHourStart] = React.useState('');
  React.useEffect(() => {
    if (period !== 'hour') return undefined;
    const updateHourStart = () => setHourStart(new Date(Date.now() - 60 * 60 * 1000).toISOString());
    updateHourStart();
    const interval = setInterval(updateHourStart, 60_000);
    return () => clearInterval(interval);
  }, [period]);
  const today = localDateKey(new Date());
  const range = getPeriodRange(period, today, customFrom, customTo);
  const sales = store.sales.filter((sale) => sale.status !== 'refunded'
    && (!range.start || sale.date >= range.start)
    && (!range.end || sale.date <= range.end)
    && (period !== 'hour' || (sale.timestamp && Date.parse(sale.timestamp) >= Date.parse(hourStart))));
  const inventoryLogs = store.inventoryLogs.filter((entry) => {
    const date = String(entry.date || '').slice(0, 10);
    return (!range.start || date >= range.start) && (!range.end || date <= range.end);
  });
  const activityLogs = store.activityLogs.filter((entry) => {
    const date = String(entry.timestamp || '').slice(0, 10);
    return (!range.start || date >= range.start) && (!range.end || date <= range.end);
  });
  const revenue = sales.reduce((sum, sale) => sum + sale.total, 0);
  const units = sales.reduce((sum, sale) => sum + sale.items.reduce((total, item) => total + item.qty, 0), 0);
  const profit = sales.reduce((sum, sale) => sum + sale.items.reduce((total, item) => {
    const product = store.products.find((entry) => entry.id === item.productId || entry.name === item.name);
    return total + ((item.price ?? product?.price ?? 0) - (item.cost ?? product?.cost ?? 0)) * item.qty - (Number(item.discount) || 0);
  }, 0), 0);
  const days = Array.from({ length: 7 }, (_, index) => {
    const date = new Date(); date.setDate(date.getDate() - (6 - index));
    const key = localDateKey(date);
    return { key, label: new Intl.DateTimeFormat('en', { weekday: 'short' }).format(date), amount: sales.filter((sale) => sale.date === key).reduce((sum, sale) => sum + sale.total, 0) };
  });
  const max = Math.max(...days.map((day) => day.amount), 1);
  const topProducts = Object.entries(sales.flatMap((sale) => sale.items).reduce((result, item) => { result[item.name] = (result[item.name] || 0) + item.qty; return result; }, {})).sort((a, b) => b[1] - a[1]).slice(0, 4);
  const inventoryValue = store.products.reduce((sum, product) => sum + product.stock * product.cost, 0);
  const lowStockProducts = store.products.filter((product) => product.stock <= product.minStock).sort((a, b) => a.stock - b.stock);
  const profitRows = Object.values(sales.flatMap((sale) => sale.items).reduce((result, item) => {
    const key = `${item.name}-${item.variantId}`;
    const row = result[key] || { name: item.name, qty: 0, profit: 0 };
    row.qty += item.qty;
    row.profit += ((item.price || 0) - (item.cost || 0)) * item.qty - (Number(item.discount) || 0);
    result[key] = row;
    return result;
  }, {})).sort((a, b) => b.profit - a.profit).slice(0, 12);
  const salesWithoutActivityLog = sales.filter((sale) => !activityLogs.some((entry) => entry.targetId === sale.id));
  const activityRows = [
    ...activityLogs.map((item) => ({ id: `activity-${item.id}`, title: item.action || 'Store updated', detail: [item.targetName, item.employeeName].filter(Boolean).join(' · '), date: item.timestamp, amount: null, amountLabel: '' })),
    ...inventoryLogs.map((item) => ({ id: `stock-${item.id}`, title: `${item.qty >= 0 ? 'Stock added' : 'Stock removed'} · ${item.productName}`, detail: `${item.reason || item.type} · ${item.employeeName || 'Store owner'}`, date: item.date, amount: item.qty, amountLabel: `${item.qty > 0 ? '+' : ''}${item.qty} units`, isStock: true })),
    ...salesWithoutActivityLog.map((item) => ({ id: `sale-${item.id}`, title: 'Sale recorded', detail: `${item.customer} · ${item.payment}`, date: item.timestamp || item.date, amount: item.total, amountLabel: formatMoney(item.total) })),
  ].sort((a, b) => new Date(b.date || 0).getTime() - new Date(a.date || 0).getTime()).slice(0, 40);

  return <Screen title="Reports" subtitle="Review your store performance.">
    <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.reportTabs}><SegmentedTabs value={tab} onChange={setTab} tabs={['Sales', 'Inventory', 'Profit', 'Activity'].map((label) => ({ key: label, label }))} /></ScrollView>
    <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.periods}>{periods.map((item) => <Chip key={item.key} label={item.label} selected={period === item.key} onPress={() => setPeriod(item.key)} />)}</ScrollView>
    {period === 'custom' && <View style={styles.customRange}><View style={styles.customDateField}><TextField label="From (YYYY-MM-DD)" value={customFrom} onChangeText={setCustomFrom} placeholder="2026-01-01" autoCapitalize="none" autoCorrect={false} /></View><View style={styles.customDateField}><TextField label="To (YYYY-MM-DD)" value={customTo} onChangeText={setCustomTo} placeholder={today} autoCapitalize="none" autoCorrect={false} /></View></View>}
    <Text style={styles.dateCaption}>{period === 'hour' ? 'Sales in the last hour' : range.start ? `${formatDate(range.start)} — ${formatDate(range.end)}` : 'Since your first sale'}</Text>
    {tab === 'Sales' && <>
    <View style={styles.metrics}><MetricCard label="Revenue" value={formatMoney(revenue)} note={`${sales.length} sales`} icon="wallet-outline" tone="teal" /><MetricCard label="Estimated profit" value={formatMoney(profit)} note="Based on product costs" icon="trending-up-outline" tone="mint" /><MetricCard label="Items sold" value={String(units)} note="All transactions" icon="pricetags-outline" tone="gold" /><MetricCard label="Average sale" value={formatMoney(sales.length ? revenue / sales.length : 0)} note="Per transaction" icon="receipt-outline" tone="coral" /></View>
    <SectionTitle title="Daily sales" />
    <Card style={styles.chartCard}><Text style={styles.chartTotal}>{formatMoney(days.reduce((sum, day) => sum + day.amount, 0))}</Text><Text style={styles.chartSub}>Revenue in the last 7 days</Text><View style={styles.chart}>{days.map((day) => <View style={styles.chartCol} key={day.key}><View style={styles.track}><View style={[styles.bar, { height: `${Math.max(8, day.amount / max * 100)}%` }]} /></View><Text style={styles.dayLabel}>{day.label}</Text></View>)}</View></Card>
    <SectionTitle title="Top products" />
    <Card style={styles.list}>{topProducts.map(([name, quantity], index) => <View key={name} style={styles.topRow}><View style={styles.rank}><Text style={styles.rankText}>{String(index + 1).padStart(2, '0')}</Text></View><Text style={styles.topName}>{name}</Text><Text style={styles.topQty}>{quantity} pcs</Text></View>)}{!topProducts.length && <Text style={styles.empty}>Sales will appear here when recorded.</Text>}</Card>
    <SectionTitle title="Recent sales" />
    <Card style={styles.list}>{sales.slice(0, 8).map((sale) => <View key={sale.id} style={styles.saleRow}><View style={styles.saleCopy}><Text style={styles.saleId}>{sale.id}</Text><Text style={styles.saleDate}>{sale.customer} · {formatDate(sale.date)}</Text></View><View style={styles.saleRight}><Text style={styles.saleAmount}>{formatMoney(sale.total)}</Text><StatusPill label={sale.payment} tone={sale.payment === 'Cash' ? 'success' : 'neutral'} /></View></View>)}</Card>
    </>}
    {tab === 'Inventory' && <>
      <View style={styles.metrics}><MetricCard label="Units on hand" value={store.products.reduce((sum, product) => sum + product.stock, 0).toLocaleString()} note="Across all products" icon="cube-outline" tone="teal" /><MetricCard label="Inventory value" value={formatMoney(inventoryValue)} note="At estimated cost" icon="wallet-outline" tone="mint" /><MetricCard label="Low stock" value={String(lowStockProducts.length)} note="Items to replenish" icon="alert-circle-outline" tone="gold" /></View>
      <SectionTitle title="Items to replenish" />
      <Card style={styles.list}>{lowStockProducts.map((product) => <View key={product.id} style={styles.topRow}><View style={styles.rank}><Text style={styles.rankText}>!</Text></View><Text style={styles.topName}>{product.name}</Text><Text style={styles.lowQty}>{product.stock} / {product.minStock}</Text></View>)}{!lowStockProducts.length && <Text style={styles.empty}>All products are above their restock levels.</Text>}</Card>
      <SectionTitle title="Recent stock movement" />
      <Card style={styles.list}>{inventoryLogs.slice(0, 10).map((entry) => <View key={entry.id} style={styles.saleRow}><View style={styles.saleCopy}><Text style={styles.saleId}>{entry.productName}</Text><Text style={styles.saleDate}>{formatDate(String(entry.date || '').slice(0, 10))} · {entry.reason || entry.type}</Text></View><Text style={[styles.saleAmount, entry.qty >= 0 ? styles.stockAdded : styles.stockRemoved]}>{entry.qty > 0 ? '+' : ''}{entry.qty}</Text></View>)}{!inventoryLogs.length && <Text style={styles.empty}>Restocks and sales will appear here.</Text>}</Card>
    </>}
    {tab === 'Profit' && <>
      <View style={styles.metrics}><MetricCard label="Estimated profit" value={formatMoney(profit)} note="For selected period" icon="trending-up-outline" tone="mint" /><MetricCard label="Profit margin" value={`${revenue ? (profit / revenue * 100).toFixed(1) : '0.0'}%`} note="Profit as share of sales" icon="stats-chart-outline" tone="gold" /></View>
      <SectionTitle title="Profit by product" />
      <Card style={styles.list}>{profitRows.map((row) => <View key={row.name} style={styles.saleRow}><View style={styles.saleCopy}><Text style={styles.saleId}>{row.name}</Text><Text style={styles.saleDate}>{row.qty} units sold</Text></View><Text style={styles.saleAmount}>{formatMoney(row.profit)}</Text></View>)}{!profitRows.length && <Text style={styles.empty}>Product profit will appear when sales are recorded.</Text>}</Card>
    </>}
    {tab === 'Activity' && <>
      <SectionTitle title="Store activity" action={<Text style={styles.dateCaption}>{activityRows.length} records</Text>} />
      <Card style={styles.list}>{activityRows.map((item) => <View key={item.id} style={styles.saleRow}><View style={styles.saleCopy}><Text style={styles.saleId}>{item.title}</Text><Text style={styles.saleDate}>{formatDate(String(item.date || '').slice(0, 10))} · {item.detail}</Text></View>{item.amount !== null && <Text style={[styles.saleAmount, item.isStock ? (item.amount >= 0 ? styles.stockAdded : styles.stockRemoved) : null]}>{item.amountLabel}</Text>}</View>)}{!activityRows.length && <Text style={styles.empty}>Store actions will appear after records are updated.</Text>}</Card>
    </>}
  </Screen>;
}

function localDateKey(date) {
  return [date.getFullYear(), String(date.getMonth() + 1).padStart(2, '0'), String(date.getDate()).padStart(2, '0')].join('-');
}

function getPeriodRange(period, today, customFrom, customTo) {
  if (period === 'total') return { start: '2020-01-01', end: today };
  if (period === 'custom') return { start: customFrom || today, end: customTo || today };
  if (period === 'hour') return { start: today, end: today };
  const endDate = new Date(`${today}T00:00:00`);
  if (period === 'yesterday') endDate.setDate(endDate.getDate() - 1);
  const startDate = new Date(endDate);
  if (period === 'week') startDate.setDate(startDate.getDate() - 7);
  else if (period === 'month') startDate.setDate(1);
  else if (period === 'year') { startDate.setMonth(0); startDate.setDate(1); }
  return { start: localDateKey(startDate), end: localDateKey(endDate) };
}

const styles = createThemeAwareStyles({
  reportTabs: { maxWidth: '100%' },
  periods: { gap: 8 },
  customRange: { flexDirection: 'row', gap: 10 },
  customDateField: { flex: 1, minWidth: 0 },
  dateCaption: { color: colors.muted, fontSize: 13, marginTop: -3 },
  metrics: { flexDirection: 'row', flexWrap: 'wrap', gap: 9 },
  chartCard: { padding: 16 },
  chartTotal: { color: colors.text, fontSize: 23, fontWeight: '800' },
  chartSub: { color: colors.muted, fontSize: 13, marginTop: 3 },
  chart: { height: 130, flexDirection: 'row', gap: 10, marginTop: 16 },
  chartCol: { flex: 1, alignItems: 'center', gap: 7 },
  track: { width: 26, flex: 1, justifyContent: 'flex-end', overflow: 'hidden', borderRadius: 8, backgroundColor: '#EFF4F1' },
  bar: { width: '100%', borderTopLeftRadius: 7, borderTopRightRadius: 7, backgroundColor: colors.primary },
  dayLabel: { color: colors.muted, fontSize: 12 },
  list: { paddingHorizontal: 13, paddingVertical: 3 },
  topRow: { minHeight: 55, flexDirection: 'row', alignItems: 'center', gap: 10, borderBottomWidth: 1, borderBottomColor: '#EDF1EF' },
  rank: { width: 31, height: 31, borderRadius: 10, alignItems: 'center', justifyContent: 'center', backgroundColor: colors.primarySoft },
  rankText: { color: colors.primary, fontSize: 12, fontWeight: '800' },
  topName: { flex: 1, color: colors.text, fontSize: 14, fontWeight: '700' },
  topQty: { color: colors.primary, fontSize: 14, fontWeight: '800' },
  empty: { textAlign: 'center', color: colors.muted, padding: 20, fontSize: 14 },
  saleRow: { minHeight: 65, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 10, borderBottomWidth: 1, borderBottomColor: '#EDF1EF' },
  saleCopy: { flex: 1, gap: 4 },
  saleId: { color: colors.text, fontSize: 14, fontWeight: '800' },
  saleDate: { color: colors.muted, fontSize: 12 },
  saleRight: { alignItems: 'flex-end', gap: 3 },
  saleAmount: { color: colors.text, fontSize: 14, fontWeight: '800' },
  lowQty: { color: colors.warning, fontSize: 14, fontWeight: '800' },
  stockAdded: { color: colors.success },
  stockRemoved: { color: colors.error },
});
