import React from 'react';
import { Alert, Text, View } from 'react-native';
import { AppButton, AppModal, Card, Chip, Screen, SectionTitle, SegmentedTabs, TextField } from '../components/Ui';
import MetricCard from '../components/MetricCard';
import ProductRow from '../components/ProductRow';
import SearchBox from '../components/SearchBox';
import { useStore } from '../store/StoreProvider';
import { colors, createThemeAwareStyles } from '../theme';

export default function InventoryScreen() {
  const store = useStore();
  const [section, setSection] = React.useState('overview');
  const [query, setQuery] = React.useState('');
  const [filter, setFilter] = React.useState('All');
  const [selected, setSelected] = React.useState(null);
  const [adjustmentMode, setAdjustmentMode] = React.useState('add');
  const [amount, setAmount] = React.useState('10');
  const [costPrice, setCostPrice] = React.useState('');
  const [expiryDate, setExpiryDate] = React.useState('');
  const [removeReason, setRemoveReason] = React.useState('adjustment');
  const [saving, setSaving] = React.useState(false);
  const lowStock = store.products.filter((product) => product.stock <= product.minStock);
  const totalUnits = store.products.reduce((sum, product) => sum + product.stock, 0);
  const replenishProducts = [...store.products].sort((a, b) => Number(b.stock <= b.minStock) - Number(a.stock <= a.minStock) || a.stock - b.stock);
  const products = store.products.filter((product) => product.name.toLowerCase().includes(query.toLowerCase()) && (filter === 'All' || (filter === 'Low stock' ? product.stock <= product.minStock : product.stock > product.minStock)));
  const saveRestock = async () => {
    const quantity = Math.max(1, Number(amount) || 1);
    setSaving(true);
    try {
      if (adjustmentMode === 'add') await store.restock(selected.id, quantity, { costPrice, expiryDate });
      else await store.removeStock(selected.id, quantity, removeReason);
      setSelected(null);
      Alert.alert('Stock updated', `${selected.name}: ${adjustmentMode === 'add' ? 'added' : 'removed'} ${quantity} ${selected.unit}.`);
    } catch (error) {
      Alert.alert('Could not update stock', error.message);
    } finally {
      setSaving(false);
    }
  };
  const openAdjustment = (product, mode) => {
    setSelected(product);
    setAdjustmentMode(mode);
    setAmount(mode === 'add' ? '10' : '1');
    setCostPrice('');
    setExpiryDate('');
    setRemoveReason('adjustment');
  };

  return <>
    <Screen title="Inventory" subtitle="Check stock, restock items, and review changes." action={<AppButton compact title="Summary" icon="cube-outline" variant="outline" onPress={() => Alert.alert('Stock summary', `${totalUnits} units across ${store.products.length} products.`)} />}>
      <SegmentedTabs value={section} onChange={setSection} tabs={[{ key: 'overview', label: 'Overview' }, { key: 'replenish', label: 'Replenish' }, { key: 'logs', label: 'Logs' }]} />
      {section === 'overview' && <>
      <View style={styles.metrics}><MetricCard label="Units on hand" value={totalUnits.toLocaleString()} note="Across all products" icon="cube-outline" tone="teal" /><MetricCard label="Low stock" value={String(lowStock.length)} note="Review these items" icon="alert-circle-outline" tone="gold" /></View>
      {lowStock.length > 0 && <View style={styles.notice}><View style={styles.noticeIcon}><Text style={styles.noticeIconText}>!</Text></View><View style={styles.noticeCopy}><Text style={styles.noticeTitle}>{lowStock.length} items need attention</Text><Text style={styles.noticeText}>Restock to keep your shelves ready.</Text></View></View>}
      <SearchBox value={query} onChangeText={setQuery} placeholder="Search inventory" />
      <View style={styles.filterRow}>{['All', 'Low stock', 'Healthy'].map((item) => <AppButton key={item} title={item} compact variant={filter === item ? 'soft' : 'outline'} onPress={() => setFilter(item)} />)}</View>
      <SectionTitle title={`${products.length} items`} />
      <Card style={styles.list}>{products.map((product) => <ProductRow key={product.id} product={product} compact trailing={<View style={styles.rowRight}><Text style={[styles.quantity, product.stock <= product.minStock && styles.lowQuantity]}>{product.stock} {product.unit}</Text><AppButton title="Restock" compact variant="outline" onPress={() => openAdjustment(product, 'add')} /></View>} />)}{!products.length && <Text style={styles.empty}>Nothing matches this filter.</Text>}</Card>
      </>}
      {section === 'replenish' && <>
        <SectionTitle title="Replenish or adjust stock" action={<Text style={styles.logMeta}>{lowStock.length} low stock</Text>} />
        <Card style={styles.list}>{replenishProducts.map((product) => <ProductRow key={product.id} product={product} compact trailing={<View style={styles.adjustActions}><Text style={[styles.lowQuantity, product.stock > product.minStock && styles.quantity]}>{product.stock} / {product.minStock} {product.unit}</Text><View style={styles.adjustButtons}><AppButton title="Add" compact variant="outline" onPress={() => openAdjustment(product, 'add')} /><AppButton title="Remove" compact variant="soft" disabled={!product.stock} onPress={() => openAdjustment(product, 'remove')} /></View></View>} />)}{!replenishProducts.length && <Text style={styles.empty}>Add products before adjusting stock.</Text>}</Card>
      </>}
      {section === 'logs' && <>
        <SectionTitle title="Stock movement" action={<Text style={styles.logMeta}>{store.inventoryLogs.length} records</Text>} />
        <Card style={styles.list}>{store.inventoryLogs.map((log) => <View key={log.id} style={styles.logRow}><View style={styles.logCopy}><Text style={styles.logName}>{log.productName}{log.variantName ? ` · ${log.variantName}` : ''}</Text><Text style={styles.logMeta}>{formatLogDate(log.date)} · {log.reason || log.type} · {log.employeeName || 'Store owner'}</Text></View><Text style={[styles.logQuantity, log.qty >= 0 ? styles.logAdd : styles.logRemove]}>{log.qty > 0 ? '+' : ''}{log.qty}</Text></View>)}{!store.inventoryLogs.length && <Text style={styles.empty}>Restocks and completed sales will appear here.</Text>}</Card>
      </>}
    </Screen>
    <AppModal visible={!!selected} title={`${adjustmentMode === 'add' ? 'Add' : 'Remove'} stock`} subtitle={selected ? `${selected.name} · current stock ${selected.stock} ${selected.unit}` : ''} onClose={() => setSelected(null)} actions={<><AppButton title="Cancel" variant="outline" style={styles.action} onPress={() => setSelected(null)} /><AppButton title={saving ? 'Saving…' : adjustmentMode === 'add' ? 'Add stock' : 'Remove stock'} icon="checkmark" disabled={saving} style={styles.action} onPress={saveRestock} /></>}>
      <TextField label={`Quantity${selected ? ` (${selected.unit})` : ''}`} keyboardType="number-pad" value={amount} onChangeText={setAmount} placeholder="10" autoFocus />
      {adjustmentMode === 'add' ? <><TextField label="Cost per unit (optional)" keyboardType="decimal-pad" value={costPrice} onChangeText={setCostPrice} placeholder={selected ? String(selected.cost) : '0'} /><TextField label="Expiry date (optional)" value={expiryDate} onChangeText={setExpiryDate} placeholder="YYYY-MM-DD" autoCapitalize="none" /></> : <View style={styles.reasonBlock}><Text style={styles.reasonLabel}>Reason for removal</Text><View style={styles.reasonChips}>{[['adjustment', 'Adjustment'], ['personal_use', 'Personal use'], ['waste_damage', 'Waste or damage'], ['stock_loss', 'Stock loss']].map(([key, label]) => <Chip key={key} label={label} selected={removeReason === key} onPress={() => setRemoveReason(key)} />)}</View></View>}
    </AppModal>
  </>;
}

function formatLogDate(value) {
  if (!value) return '—';
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? value : new Intl.DateTimeFormat('en-PH', { dateStyle: 'medium' }).format(date);
}

const styles = createThemeAwareStyles({
  metrics: { flexDirection: 'row', gap: 9 },
  notice: { flexDirection: 'row', alignItems: 'center', gap: 11, padding: 13, borderWidth: 1, borderColor: '#F0DFAF', borderRadius: 13, backgroundColor: '#FFF9E9' },
  noticeIcon: { width: 34, height: 34, borderRadius: 11, alignItems: 'center', justifyContent: 'center', backgroundColor: colors.warningSoft },
  noticeIconText: { color: colors.warning, fontSize: 18, fontWeight: '900' },
  noticeCopy: { flex: 1, gap: 3 },
  noticeTitle: { color: '#604908', fontSize: 14, fontWeight: '800' },
  noticeText: { color: '#7C6B40', fontSize: 13 },
  filterRow: { flexDirection: 'row', gap: 8 },
  list: { paddingHorizontal: 12, paddingVertical: 2 },
  rowRight: { alignItems: 'flex-end', gap: 5 },
  adjustActions: { alignItems: 'flex-end', gap: 5, maxWidth: 185 },
  adjustButtons: { flexDirection: 'row', gap: 6 },
  reasonBlock: { gap: 8, marginBottom: 14 },
  reasonLabel: { color: colors.text, fontSize: 14, fontWeight: '700' },
  reasonChips: { flexDirection: 'row', flexWrap: 'wrap', gap: 7 },
  quantity: { color: colors.text, fontSize: 14, fontWeight: '800' },
  lowQuantity: { color: colors.warning },
  empty: { textAlign: 'center', color: colors.muted, padding: 24 },
  logRow: { minHeight: 66, flexDirection: 'row', alignItems: 'center', gap: 12, paddingVertical: 10, borderBottomWidth: 1, borderBottomColor: '#E4ECE8' },
  logCopy: { flex: 1, gap: 4 },
  logName: { color: colors.text, fontSize: 15, fontWeight: '700' },
  logMeta: { color: colors.muted, fontSize: 13 },
  logQuantity: { fontSize: 16, fontWeight: '800' },
  logAdd: { color: colors.success },
  logRemove: { color: colors.error },
  action: { flex: 1 },
});
