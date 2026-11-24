import React from 'react';
import { Alert, Image, Pressable, ScrollView, Text, View } from 'react-native';
import { AppButton, AppModal, Card, Chip, Screen, SectionTitle, SegmentedTabs, StatusPill, TextField } from '../components/Ui';
import SearchBox from '../components/SearchBox';
import { formatMoney } from '../data/formatters';
import { useStore } from '../store/StoreProvider';
import { colors, createThemeAwareStyles } from '../theme';

export default function SalesScreen() {
  const store = useStore();
  const [section, setSection] = React.useState('new');
  const [historyRange, setHistoryRange] = React.useState('all');
  const [customFrom, setCustomFrom] = React.useState(() => localDateKey(new Date()));
  const [customTo, setCustomTo] = React.useState(() => localDateKey(new Date()));
  const [receiptSale, setReceiptSale] = React.useState(null);
  const [workingSaleId, setWorkingSaleId] = React.useState('');
  const [query, setQuery] = React.useState('');
  const [category, setCategory] = React.useState('All');
  const [payment, setPayment] = React.useState('Cash');
  const [customerName, setCustomerName] = React.useState('');
  const [customerPhone, setCustomerPhone] = React.useState('');
  const [customerAddress, setCustomerAddress] = React.useState('');
  const [amountReceived, setAmountReceived] = React.useState('');
  const [cart, setCart] = React.useState([]);
  const [saving, setSaving] = React.useState(false);
  const products = store.products.filter((product) => product.stock > 0 && (`${product.name} ${product.sku}`).toLowerCase().includes(query.toLowerCase()) && (category === 'All' || product.category === category));
  const subtotal = cart.reduce((sum, line) => sum + line.product.price * line.qty, 0);
  const totalDiscount = cart.reduce((sum, line) => sum + (Number(line.discount) || 0), 0);
  const total = Math.max(0, subtotal - totalDiscount);
  const count = cart.reduce((sum, line) => sum + line.qty, 0);
  const today = localDateKey(new Date());
  const historySales = store.sales.filter((sale) => {
    if (historyRange === 'all') return true;
    if (historyRange === 'today') return sale.date === today;
    if (historyRange === 'custom') return sale.date >= customFrom && sale.date <= customTo;
    if (historyRange === 'year') return sale.date >= `${new Date().getFullYear()}-01-01` && sale.date <= today;
    const days = historyRange === 'week' ? 7 : 30;
    const cutoff = new Date(); cutoff.setHours(0, 0, 0, 0); cutoff.setDate(cutoff.getDate() - (days - 1));
    return sale.date >= localDateKey(cutoff);
  });
  const add = (product) => setCart((current) => {
    const line = current.find((item) => item.product.id === product.id);
    if (!line) return [...current, { product, qty: 1, discount: 0 }];
    return current.map((item) => item.product.id === product.id ? { ...item, qty: Math.min(product.stock, item.qty + 1) } : item);
  });
  const change = (id, delta) => setCart((current) => current.map((line) => {
    if (line.product.id !== id) return line;
    const qty = Math.min(line.product.stock, line.qty + delta);
    return { ...line, qty, discount: Math.min(line.discount || 0, line.product.price * qty) };
  }).filter((line) => line.qty > 0));
  const changeDiscount = (id, value) => setCart((current) => current.map((line) => line.product.id === id ? { ...line, discount: Math.min(line.product.price * line.qty, Math.max(0, Number(value) || 0)) } : line));
  const checkout = async () => {
    if (!cart.length) return;
    const received = payment === 'Utang' ? 0 : amountReceived === '' ? total : Number(amountReceived) || 0;
    if ((payment === 'Utang' || (payment === 'Multi' && received < total)) && !customerName.trim()) return Alert.alert('Customer required', 'Enter the customer name for an Utang or unpaid balance.');
    if (payment !== 'Utang' && payment !== 'Multi' && received < total) return Alert.alert('Payment is short', 'Cash payment must cover the sale total. Choose Multi to record a balance.');
    setSaving(true);
    try {
      const sale = await store.completeSale(cart, payment, { customerName, customerPhone, customerAddress, amountPaid: received });
      setCart([]);
      setCustomerName('');
      setCustomerPhone('');
      setCustomerAddress('');
      setAmountReceived('');
      Alert.alert(sale.offlinePending ? 'Sale saved offline' : 'Sale complete', `${sale.id} · ${formatMoney(sale.total)}${sale.offlinePending ? ' · will sync when connected' : ''}`);
    } catch (error) {
      Alert.alert('Could not complete sale', error.message);
    } finally {
      setSaving(false);
    }
  };

  const refund = (sale) => Alert.alert('Refund this sale?', 'The items will be returned to inventory.', [
    { text: 'Cancel', style: 'cancel' },
    { text: 'Refund', style: 'destructive', onPress: async () => {
      setWorkingSaleId(sale.id);
      try { await store.refundSale(sale.id, 'Customer refund'); Alert.alert('Sale refunded', 'The stock has been restored.'); }
      catch (error) { Alert.alert('Could not refund sale', error.message); }
      finally { setWorkingSaleId(''); }
    } },
  ]);

  const remove = (sale) => Alert.alert('Delete this sale?', 'If it has not been refunded, its items will be returned to inventory.', [
    { text: 'Cancel', style: 'cancel' },
    { text: 'Delete', style: 'destructive', onPress: async () => {
      setWorkingSaleId(sale.id);
      try { await store.deleteSale(sale.id); Alert.alert('Sale deleted', 'The transaction has been removed.'); }
      catch (error) { Alert.alert('Could not delete sale', error.message); }
      finally { setWorkingSaleId(''); }
    } },
  ]);

  if (section === 'history') return <Screen title="Sales" subtitle="Review completed transactions on this account.">
    <SegmentedTabs value={section} onChange={setSection} tabs={[{ key: 'new', label: 'New sale' }, { key: 'history', label: 'History' }]} />
    <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.historyFilters}>{[['all', 'All'], ['today', 'Today'], ['week', 'Week'], ['month', 'Month'], ['year', 'Year'], ['custom', 'Custom']].map(([key, label]) => <Chip key={key} label={label} selected={historyRange === key} onPress={() => setHistoryRange(key)} />)}</ScrollView>
    {historyRange === 'custom' && <View style={styles.customRange}><View style={styles.customDate}><TextField label="From (YYYY-MM-DD)" value={customFrom} onChangeText={setCustomFrom} placeholder="2026-01-01" autoCapitalize="none" autoCorrect={false} /></View><View style={styles.customDate}><TextField label="To (YYYY-MM-DD)" value={customTo} onChangeText={setCustomTo} placeholder={today} autoCapitalize="none" autoCorrect={false} /></View></View>}
    <SectionTitle title={`${historySales.length} transactions`} />
    <View style={styles.historyList}>{historySales.map((sale) => <Card key={sale.id} style={styles.historyCard}>
      <View style={styles.historyHead}><View style={styles.historyCopy}><Text style={styles.historyCustomer}>{sale.customer || 'Walk-in customer'}</Text><Text style={styles.historyMeta}>{formatSalesDate(sale.date)} · {sale.payment || 'Cash'} · {sale.items.length} {sale.items.length === 1 ? 'item' : 'items'}</Text></View><View style={styles.historyTotal}><Text style={styles.historyAmount}>{formatMoney(sale.total)}</Text><StatusPill label={sale.offlinePending ? 'Pending sync' : sale.status || 'completed'} tone={sale.offlinePending || sale.status === 'refunded' || sale.status === 'partial' ? 'warning' : 'success'} /></View></View>
      {sale.items.map((item, index) => <View key={`${sale.id}-${item.productId}-${item.variantId}-${index}`} style={styles.historyLine}><Text style={styles.historyItem}>{item.name}{item.variantName ? ` · ${item.variantName}` : ''} × {item.qty}</Text><Text style={styles.historyLineTotal}>{formatMoney(item.total)}</Text></View>)}
      <View style={styles.historyActions}><AppButton title="Receipt" compact variant="outline" onPress={() => setReceiptSale(sale)} /><View style={styles.historyActionSpacer} />{sale.status !== 'refunded' && <AppButton title={workingSaleId === sale.id ? 'Saving…' : 'Refund'} compact variant="outline" disabled={sale.offlinePending || workingSaleId === sale.id} onPress={() => refund(sale)} />}<AppButton title="Delete" compact variant="soft" disabled={sale.offlinePending || workingSaleId === sale.id} onPress={() => remove(sale)} /></View>
    </Card>)}{!historySales.length && <Card><Text style={styles.emptyCart}>Completed sales will appear here.</Text></Card>}</View>
    <AppModal visible={!!receiptSale} title="Sales receipt" subtitle={receiptSale ? `Transaction ${receiptSale.id} · ${formatSalesDate(receiptSale.date)}` : ''} onClose={() => setReceiptSale(null)} actions={<AppButton title="Close" variant="outline" style={styles.receiptClose} onPress={() => setReceiptSale(null)} />}>
      {receiptSale && <><View style={styles.receiptRow}><Text style={styles.receiptLabel}>Customer</Text><Text style={styles.receiptValue}>{receiptSale.customer || 'Walk-in customer'}</Text></View><View style={styles.receiptRow}><Text style={styles.receiptLabel}>Payment</Text><Text style={styles.receiptValue}>{receiptSale.payment}</Text></View>{receiptSale.items.map((item, index) => <View key={`${item.productId}-${item.variantId}-${index}`} style={styles.receiptRow}><Text style={styles.receiptLabel}>{item.name}{item.variantName ? ` · ${item.variantName}` : ''} × {item.qty}{item.discount > 0 ? ` · discount ${formatMoney(item.discount)}` : ''}</Text><Text style={styles.receiptValue}>{formatMoney(item.total)}</Text></View>)}{receiptSale.totalDiscount > 0 && <><View style={styles.receiptRow}><Text style={styles.receiptLabel}>Subtotal</Text><Text style={styles.receiptValue}>{formatMoney(receiptSale.subtotal)}</Text></View><View style={styles.receiptRow}><Text style={styles.receiptLabel}>Discount</Text><Text style={styles.receiptValue}>− {formatMoney(receiptSale.totalDiscount)}</Text></View></>}<View style={[styles.receiptRow, styles.receiptTotal]}><Text style={styles.receiptLabel}>Total</Text><Text style={styles.receiptValue}>{formatMoney(receiptSale.total)}</Text></View>{receiptSale.amountPaid < receiptSale.total && <View style={styles.receiptRow}><Text style={styles.receiptLabel}>Balance</Text><Text style={styles.receiptValue}>{formatMoney(receiptSale.total - receiptSale.amountPaid)}</Text></View>}{receiptSale.change > 0 && <View style={styles.receiptRow}><Text style={styles.receiptLabel}>Change</Text><Text style={styles.receiptValue}>{formatMoney(receiptSale.change)}</Text></View>}</>}
    </AppModal>
  </Screen>;

  return <Screen title="Sales" subtitle="Create a sale or review previous transactions.">
    <SegmentedTabs value={section} onChange={setSection} tabs={[{ key: 'new', label: 'New sale' }, { key: 'history', label: 'History' }]} />
    <SearchBox value={query} onChangeText={setQuery} placeholder="Find a product" />
    <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.filters}>{['All', ...store.categories].map((item) => <Chip key={item} label={item} selected={category === item} onPress={() => setCategory(item)} />)}</ScrollView>
    <SectionTitle title="Available products" />
    <View style={styles.productGrid}>{products.map((product) => <Pressable key={product.id} onPress={() => add(product)} style={({ pressed }) => [styles.productTile, pressed && styles.pressed]} accessibilityRole="button" accessibilityLabel={`Add ${product.name}, ${formatMoney(product.price)}`}><View style={styles.productIcon}>{product.imageUrl ? <Image source={{ uri: product.imageUrl }} style={styles.productIconImage} resizeMode="cover" /> : <Text style={styles.productInitial}>{product.name.slice(0, 1)}</Text>}</View><Text style={styles.productName} numberOfLines={2}>{product.name}</Text><Text style={styles.productPrice}>{formatMoney(product.price)}</Text><Text style={styles.productStock}>{product.stock} {product.unit} left</Text></Pressable>)}</View>
    <SectionTitle title={`Current sale · ${count} items`} action={cart.length > 0 ? <Pressable onPress={() => setCart([])} style={styles.clear}><Text style={styles.clearText}>Clear</Text></Pressable> : null} />
    <Card style={styles.cartCard}>{cart.length ? cart.map((line) => <View key={line.product.id} style={styles.cartLineBlock}><View style={styles.cartRow}><View style={styles.cartCopy}><Text style={styles.cartName} numberOfLines={1}>{line.product.name}</Text><Text style={styles.cartUnit}>{formatMoney(line.product.price)} each</Text></View><View style={styles.stepper}><Pressable onPress={() => change(line.product.id, -1)} accessibilityLabel={`Remove one ${line.product.name}`}><Text style={styles.stepperText}>−</Text></Pressable><Text style={styles.stepperCount}>{line.qty}</Text><Pressable onPress={() => change(line.product.id, 1)} accessibilityLabel={`Add one ${line.product.name}`}><Text style={styles.stepperText}>+</Text></Pressable></View><Text style={styles.lineTotal}>{formatMoney(line.product.price * line.qty - line.discount)}</Text></View><TextField label={`Discount for ${line.product.name} (optional)`} keyboardType="decimal-pad" value={line.discount ? String(line.discount) : ''} onChangeText={(value) => changeDiscount(line.product.id, value)} placeholder="0" /></View>) : <Text style={styles.emptyCart}>Add a product above to start this sale.</Text>}
      <TextField label={`Customer name${payment === 'Utang' || payment === 'Multi' ? ' (required for balance)' : ' (optional)'}`} value={customerName} onChangeText={setCustomerName} placeholder="Walk-in customer" />
      <Text style={styles.paymentTitle}>Payment method</Text><View style={styles.paymentChoices}>{['Cash', 'Utang', 'Multi'].map((item) => <Chip key={item} label={item} selected={payment === item} onPress={() => setPayment(item)} />)}</View>
      {(payment === 'Utang' || payment === 'Multi') && <><TextField label="Phone (optional)" keyboardType="phone-pad" value={customerPhone} onChangeText={setCustomerPhone} placeholder="Customer phone" /><TextField label="Address (optional)" value={customerAddress} onChangeText={setCustomerAddress} placeholder="Customer address" /></>}
      {payment !== 'Utang' && <TextField label="Amount received" keyboardType="decimal-pad" value={amountReceived} onChangeText={setAmountReceived} placeholder={formatMoney(total)} />}
      {totalDiscount > 0 && <View style={styles.discountSummary}><Text style={styles.discountLabel}>Subtotal</Text><Text style={styles.discountValue}>{formatMoney(subtotal)}</Text><Text style={styles.discountLabel}>Discount</Text><Text style={styles.discountValue}>− {formatMoney(totalDiscount)}</Text></View>}
      <View style={styles.totalRow}><Text style={styles.totalLabel}>Total</Text><Text style={styles.totalValue}>{formatMoney(total)}</Text></View>
      <AppButton title={saving ? 'Saving sale…' : 'Complete sale'} icon="checkmark" disabled={!cart.length || saving} onPress={checkout} />
    </Card>
  </Screen>;
}

function localDateKey(date) {
  return [date.getFullYear(), String(date.getMonth() + 1).padStart(2, '0'), String(date.getDate()).padStart(2, '0')].join('-');
}

function formatSalesDate(value) {
  if (!value) return '—';
  const date = new Date(`${value}T00:00:00`);
  return Number.isNaN(date.getTime()) ? value : new Intl.DateTimeFormat('en-PH', { dateStyle: 'medium' }).format(date);
}

const styles = createThemeAwareStyles({
  filters: { gap: 8 },
  productGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 9 },
  productTile: { width: '48.5%', minHeight: 144, padding: 12, borderWidth: 1, borderColor: colors.border, borderRadius: 14, backgroundColor: colors.surface },
  pressed: { opacity: .76 },
  productIcon: { width: 39, height: 39, borderRadius: 12, alignItems: 'center', justifyContent: 'center', backgroundColor: colors.primarySoft, marginBottom: 8 },
  productIconImage: { width: '100%', height: '100%', borderRadius: 12 },
  productInitial: { color: colors.primary, fontWeight: '800', fontSize: 16 },
  productName: { color: colors.text, fontSize: 14, fontWeight: '700', minHeight: 36 },
  productPrice: { color: colors.primary, fontSize: 15, fontWeight: '800', marginTop: 4 },
  productStock: { color: colors.muted, fontSize: 12, marginTop: 2 },
  cartCard: { padding: 13 },
  cartRow: { minHeight: 66, flexDirection: 'row', alignItems: 'center', gap: 8, paddingVertical: 8, borderBottomWidth: 1, borderBottomColor: '#EDF1EF' },
  cartLineBlock: { paddingTop: 4 },
  cartCopy: { flex: 1, minWidth: 0, gap: 3 },
  cartName: { color: colors.text, fontSize: 14, fontWeight: '700' },
  cartUnit: { color: colors.muted, fontSize: 12 },
  stepper: { flexDirection: 'row', alignItems: 'center', gap: 9, paddingHorizontal: 7, minHeight: 38, borderWidth: 1, borderColor: colors.border, borderRadius: 10 },
  stepperText: { color: colors.primary, fontSize: 21, fontWeight: '700' },
  stepperCount: { color: colors.text, minWidth: 15, textAlign: 'center', fontWeight: '800' },
  lineTotal: { width: 68, textAlign: 'right', color: colors.text, fontSize: 13, fontWeight: '800' },
  emptyCart: { color: colors.muted, fontSize: 14, textAlign: 'center', paddingVertical: 15 },
  paymentTitle: { color: colors.text, fontSize: 14, fontWeight: '700', marginTop: 15, marginBottom: 9 },
  paymentChoices: { flexDirection: 'row', gap: 8 },
  totalRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginTop: 14, marginBottom: 13, paddingTop: 13, borderTopWidth: 1, borderTopColor: colors.border },
  totalLabel: { color: colors.text, fontSize: 16, fontWeight: '700' },
  totalValue: { color: colors.text, fontSize: 24, fontWeight: '800' },
  discountSummary: { flexDirection: 'row', flexWrap: 'wrap', justifyContent: 'space-between', gap: 6, paddingVertical: 8, borderTopWidth: 1, borderTopColor: colors.border },
  discountLabel: { color: colors.muted, fontSize: 14 },
  discountValue: { color: colors.text, fontSize: 14, fontWeight: '700' },
  clear: { padding: 8 },
  clearText: { color: colors.primary, fontSize: 14, fontWeight: '800' },
  historyFilters: { gap: 8 },
  historyList: { gap: 10 },
  historyCard: { padding: 13 },
  historyHead: { flexDirection: 'row', alignItems: 'flex-start', justifyContent: 'space-between', gap: 10, marginBottom: 9 },
  historyCopy: { flex: 1, gap: 5 },
  historyCustomer: { color: colors.text, fontSize: 16, fontWeight: '800' },
  historyMeta: { color: colors.muted, fontSize: 13, lineHeight: 18 },
  historyTotal: { alignItems: 'flex-end', gap: 5 },
  historyAmount: { color: colors.primary, fontSize: 17, fontWeight: '800' },
  historyLine: { minHeight: 34, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 8, borderTopWidth: 1, borderTopColor: colors.border },
  historyItem: { flex: 1, color: colors.text, fontSize: 14 },
  historyLineTotal: { color: colors.text, fontSize: 14, fontWeight: '700' },
  historyActions: { flexDirection: 'row', alignItems: 'center', gap: 6, paddingTop: 11, borderTopWidth: 1, borderTopColor: colors.border },
  historyActionSpacer: { flex: 1 },
  customRange: { flexDirection: 'row', gap: 9 },
  customDate: { flex: 1, minWidth: 0 },
  receiptRow: { minHeight: 43, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 10, borderBottomWidth: 1, borderBottomColor: colors.border },
  receiptLabel: { flex: 1, color: colors.text, fontSize: 14 },
  receiptValue: { color: colors.text, fontSize: 14, fontWeight: '700' },
  receiptTotal: { borderBottomWidth: 0 },
  receiptClose: { flex: 1 },
});
