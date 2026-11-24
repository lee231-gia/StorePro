import React from 'react';
import { Alert, Text, View } from 'react-native';
import { AppButton, AppModal, Card, Chip, IconButton, Screen, SectionTitle, StatusPill, TextField } from '../components/Ui';
import { formatDate, formatMoney } from '../data/formatters';
import { useStore } from '../store/StoreProvider';
import { colors, createThemeAwareStyles } from '../theme';

function daysUntil(date) {
  if (!date) return null;
  const due = new Date(`${date}T00:00:00`);
  if (Number.isNaN(due.getTime())) return null;
  return Math.ceil((due - new Date(new Date().getFullYear(), new Date().getMonth(), new Date().getDate())) / 86400000);
}

export function ExpiryScreen() {
  const store = useStore();
  const [selected, setSelected] = React.useState(null);
  const [expiryDate, setExpiryDate] = React.useState('');
  const [saving, setSaving] = React.useState(false);
  const products = store.products.slice().sort((a, b) => (a.expiryDate || '9999-12-31').localeCompare(b.expiryDate || '9999-12-31'));
  const save = async () => {
    if (expiryDate && !/^\d{4}-\d{2}-\d{2}$/.test(expiryDate)) return Alert.alert('Check the date', 'Use YYYY-MM-DD format.');
    setSaving(true);
    try {
      await store.setProductExpiryDate(selected.id, expiryDate);
      setSelected(null);
      Alert.alert('Expiry date saved', selected.name);
    } catch (error) {
      Alert.alert('Could not save expiry date', error.message);
    } finally {
      setSaving(false);
    }
  };
  return <>
    <Screen title="Expiry" subtitle="Check dates and act before products expire.">
      <SectionTitle title={`${products.length} product variants`} />
      <View style={styles.list}>{products.map((product) => {
        const days = daysUntil(product.expiryDate);
        const label = !product.expiryDate ? 'No date' : days < 0 ? 'Expired' : days === 0 ? 'Today' : `${days} days`;
        const tone = !product.expiryDate ? 'neutral' : days < 0 || days <= 30 ? 'warning' : 'success';
        return <Card key={product.id} style={styles.row}>
          <View style={styles.copy}><Text style={styles.title}>{product.name}</Text><Text style={styles.caption}>{product.category} · {product.stock} {product.unit}</Text><Text style={styles.caption}>{product.expiryDate ? formatDate(product.expiryDate) : 'Set an expiry date to track this item.'}</Text></View>
          <View style={styles.rowActions}><StatusPill label={label} tone={tone} /><AppButton title="Set date" compact variant="outline" onPress={() => { setSelected(product); setExpiryDate(product.expiryDate || ''); }} /></View>
        </Card>;
      })}{!products.length && <Text style={styles.empty}>Products with expiry dates will appear here.</Text>}</View>
    </Screen>
    <AppModal visible={!!selected} title="Update expiry date" subtitle={selected?.name || ''} onClose={() => setSelected(null)} actions={<><AppButton title="Cancel" variant="outline" style={styles.action} onPress={() => setSelected(null)} /><AppButton title={saving ? 'Saving…' : 'Save date'} icon="checkmark" disabled={saving} style={styles.action} onPress={save} /></>}>
      <TextField label="Expiry date" placeholder="YYYY-MM-DD" value={expiryDate} onChangeText={setExpiryDate} autoCapitalize="none" hint="Leave blank to clear the current date." />
    </AppModal>
  </>;
}

export function UtangScreen() {
  const store = useStore();
  const [filter, setFilter] = React.useState('unpaid');
  const [adding, setAdding] = React.useState(false);
  const [paymentFor, setPaymentFor] = React.useState(null);
  const [customer, setCustomer] = React.useState('');
  const [amount, setAmount] = React.useState('');
  const [dueDate, setDueDate] = React.useState('');
  const [note, setNote] = React.useState('');
  const [paymentAmount, setPaymentAmount] = React.useState('');
  const [saving, setSaving] = React.useState(false);
  const rows = store.utangs.filter((item) => filter === 'all' || (filter === 'paid' ? item.balance <= 0 : item.balance > 0));
  const saveDebt = async () => {
    if (!customer.trim() || Number(amount) <= 0) return Alert.alert('Check debt details', 'Enter a customer and an amount greater than zero.');
    setSaving(true);
    try {
      await store.addUtang({ customer: customer.trim(), amount: Number(amount), dueDate, note });
      setAdding(false); setCustomer(''); setAmount(''); setDueDate(''); setNote('');
      Alert.alert('Balance added', customer.trim());
    } catch (error) {
      Alert.alert('Could not add balance', error.message);
    } finally {
      setSaving(false);
    }
  };
  const savePayment = async () => {
    const value = Number(paymentAmount);
    if (!paymentFor || value <= 0 || value > paymentFor.balance) return Alert.alert('Check payment', 'Enter an amount up to the remaining balance.');
    setSaving(true);
    try {
      await store.recordUtangPayment(paymentFor.id, value);
      setPaymentFor(null); setPaymentAmount('');
      Alert.alert('Payment recorded', `${formatMoney(value)} received from ${paymentFor.customer}.`);
    } catch (error) {
      Alert.alert('Could not record payment', error.message);
    } finally {
      setSaving(false);
    }
  };
  return <>
    <Screen title="Utang" subtitle="Track balances and payments." action={<AppButton title="Add debt" compact icon="add" onPress={() => setAdding(true)} />}>
      <View style={styles.filters}>{[['unpaid', 'Unpaid'], ['paid', 'Paid'], ['all', 'All']].map(([key, label]) => <Chip key={key} label={label} selected={filter === key} onPress={() => setFilter(key)} />)}</View>
      <SectionTitle title={`${rows.length} balances`} />
      <View style={styles.list}>{rows.map((item) => <Card key={item.id} style={styles.debtCard}>
        <View style={styles.debtTop}><View style={styles.copy}><Text style={styles.title}>{item.customer}</Text><Text style={styles.caption}>{item.dueDate ? `Due ${formatDate(item.dueDate)}` : 'No due date'}{item.note ? ` · ${item.note}` : ''}</Text></View><StatusPill label={item.balance <= 0 ? 'Paid' : item.amountPaid > 0 ? 'Partial' : 'Unpaid'} tone={item.balance <= 0 ? 'success' : 'warning'} /></View>
        <View style={styles.balanceRow}><Text style={styles.caption}>Balance</Text><Text style={styles.balance}>{formatMoney(item.balance)}</Text></View>
        {item.balance > 0 && <AppButton title="Record payment" compact variant="outline" onPress={() => { setPaymentFor(item); setPaymentAmount(String(item.balance)); }} />}
      </Card>)}{!rows.length && <Text style={styles.empty}>No balances in this list.</Text>}</View>
    </Screen>
    <AppModal visible={adding} title="Add debt" subtitle="Create a customer balance." onClose={() => setAdding(false)} actions={<><AppButton title="Cancel" variant="outline" style={styles.action} onPress={() => setAdding(false)} /><AppButton title={saving ? 'Saving…' : 'Save debt'} icon="checkmark" disabled={saving} style={styles.action} onPress={saveDebt} /></>}>
      <TextField label="Customer name" value={customer} onChangeText={setCustomer} autoFocus />
      <TextField label="Amount" keyboardType="decimal-pad" value={amount} onChangeText={setAmount} />
      <TextField label="Due date (optional)" placeholder="YYYY-MM-DD" value={dueDate} onChangeText={setDueDate} autoCapitalize="none" />
      <TextField label="Note (optional)" value={note} onChangeText={setNote} />
    </AppModal>
    <AppModal visible={!!paymentFor} title="Record payment" subtitle={paymentFor ? `${paymentFor.customer} · remaining ${formatMoney(paymentFor.balance)}` : ''} onClose={() => setPaymentFor(null)} actions={<><AppButton title="Cancel" variant="outline" style={styles.action} onPress={() => setPaymentFor(null)} /><AppButton title={saving ? 'Saving…' : 'Save payment'} icon="checkmark" disabled={saving} style={styles.action} onPress={savePayment} /></>}>
      <TextField label="Payment amount" keyboardType="decimal-pad" value={paymentAmount} onChangeText={setPaymentAmount} autoFocus />
    </AppModal>
  </>;
}

export function NotesScreen() {
  const store = useStore();
  const [filter, setFilter] = React.useState('all');
  const [adding, setAdding] = React.useState(false);
  const [type, setType] = React.useState('note');
  const [title, setTitle] = React.useState('');
  const [content, setContent] = React.useState('');
  const [dueDate, setDueDate] = React.useState('');
  const [saving, setSaving] = React.useState(false);
  const rows = store.notes.filter((item) => filter === 'all' || (filter === 'pending' ? !item.done : filter === 'done' ? item.done : item.type === filter));
  const save = async () => {
    if (!title.trim()) return Alert.alert('Add a title', 'Enter a short title for this note or task.');
    setSaving(true);
    try {
      await store.addNote({ type, title: title.trim(), content, dueDate });
      setAdding(false); setTitle(''); setContent(''); setDueDate('');
      Alert.alert(type === 'task' ? 'Task added' : 'Note saved', title.trim());
    } catch (error) {
      Alert.alert('Could not save note', error.message);
    } finally {
      setSaving(false);
    }
  };
  return <>
    <Screen title="Notes & tasks" subtitle="Keep reminders and store tasks in one place." action={<AppButton title="Add" compact icon="add" onPress={() => setAdding(true)} />}>
      <View style={styles.filters}>{[['all', 'All'], ['note', 'Notes'], ['task', 'Tasks'], ['pending', 'Pending'], ['done', 'Done']].map(([key, label]) => <Chip key={key} label={label} selected={filter === key} onPress={() => setFilter(key)} />)}</View>
      <SectionTitle title={`${rows.length} items`} />
      <View style={styles.list}>{rows.map((item) => <Card key={item.id} style={styles.noteCard}>
        <View style={styles.noteTop}><View style={styles.copy}><View style={styles.noteMeta}><StatusPill label={item.type === 'task' ? 'Task' : 'Note'} tone="neutral" />{item.dueDate ? <Text style={styles.caption}>{formatDate(item.dueDate)}</Text> : null}</View><Text style={[styles.title, item.done && styles.done]}>{item.title}</Text>{item.content ? <Text style={styles.caption}>{item.content}</Text> : null}</View><IconButton name="trash-outline" label="Delete note" onPress={() => Alert.alert('Delete this item?', item.title, [{ text: 'Cancel', style: 'cancel' }, { text: 'Delete', style: 'destructive', onPress: async () => { try { await store.deleteNote(item.id); Alert.alert('Item deleted', item.title); } catch (error) { Alert.alert('Could not delete note', error.message); } } }])} /></View>
        <AppButton title={item.done ? 'Mark pending' : 'Mark complete'} compact variant={item.done ? 'outline' : 'soft'} onPress={async () => { try { await store.toggleNote(item.id); Alert.alert(item.done ? 'Task reopened' : 'Task completed', item.title); } catch (error) { Alert.alert('Could not update note', error.message); } }} />
      </Card>)}{!rows.length && <Text style={styles.empty}>No notes or tasks in this list.</Text>}</View>
    </Screen>
    <AppModal visible={adding} title={type === 'task' ? 'Add task' : 'Add note'} subtitle="Add a reminder for your store." onClose={() => setAdding(false)} actions={<><AppButton title="Cancel" variant="outline" style={styles.action} onPress={() => setAdding(false)} /><AppButton title={saving ? 'Saving…' : 'Save'} icon="checkmark" disabled={saving} style={styles.action} onPress={save} /></>}>
      <View style={styles.filters}><Chip label="Note" selected={type === 'note'} onPress={() => setType('note')} /><Chip label="Task" selected={type === 'task'} onPress={() => setType('task')} /></View>
      <TextField label="Title" value={title} onChangeText={setTitle} autoFocus />
      <TextField label="Details (optional)" value={content} onChangeText={setContent} multiline />
      <TextField label="Due date (optional)" placeholder="YYYY-MM-DD" value={dueDate} onChangeText={setDueDate} autoCapitalize="none" />
    </AppModal>
  </>;
}

const styles = createThemeAwareStyles({
  list: { gap: 10 },
  row: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  copy: { flex: 1, minWidth: 0, gap: 5 },
  title: { color: colors.text, fontSize: 15, lineHeight: 21, fontWeight: '800' },
  caption: { color: colors.muted, fontSize: 13, lineHeight: 18 },
  rowActions: { alignItems: 'flex-end', gap: 8 },
  filters: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  debtCard: { gap: 12 },
  debtTop: { flexDirection: 'row', alignItems: 'flex-start', gap: 10 },
  balanceRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingTop: 10, borderTopWidth: 1, borderTopColor: colors.border },
  balance: { color: colors.text, fontSize: 20, fontWeight: '800' },
  noteCard: { gap: 12 },
  noteTop: { flexDirection: 'row', alignItems: 'flex-start', gap: 8 },
  noteMeta: { flexDirection: 'row', alignItems: 'center', gap: 9, marginBottom: 5 },
  done: { color: colors.muted, textDecorationLine: 'line-through' },
  empty: { color: colors.muted, textAlign: 'center', padding: 24, fontSize: 14 },
  action: { flex: 1 },
});
