import React from 'react';
import { Alert, Text, View } from 'react-native';
import { AppButton, AppIcon, Card, TextField } from '../components/Ui';
import { colors, createThemeAwareStyles } from '../theme';

export default function EmployeeSessionScreen({ store }) {
  const [adding, setAdding] = React.useState(false);
  const [name, setName] = React.useState('');
  const [saving, setSaving] = React.useState(false);

  const choose = (employee) => {
    store.selectEmployee(employee);
  };

  const owner = { id: 'owner', name: store.profile?.ownerName || store.user?.email || 'Store owner' };

  const addEmployee = async () => {
    if (!name.trim()) return Alert.alert('Enter a name', 'The employee name is required.');
    setSaving(true);
    try {
      const employee = await store.addEmployee({ name: name.trim() });
      Alert.alert('Employee added', `${employee.name} is ready to use StorePro.`, [{ text: 'Continue', onPress: () => store.selectEmployee(employee) }], { cancelable: false });
    } catch (error) {
      Alert.alert('Could not add employee', error.message);
    } finally {
      setSaving(false);
    }
  };

  return <View style={styles.root}>
    <View style={styles.content}>
      <View style={styles.brand}><View style={styles.brandIcon}><AppIcon name="cube-outline" size={24} color="#fff" /></View><Text style={styles.brandName}>StorePro</Text></View>
      <Text style={styles.title}>Who is using the register?</Text>
      <Text style={styles.subtitle}>Choose your name so sales and stock changes are recorded correctly.</Text>
      <Card style={styles.card}>
        <AppButton title="Just me" icon="person-outline" onPress={() => choose(owner)} />
        {store.employees.map((employee) => <AppButton key={employee.id} title={employee.name} icon="person" variant="outline" style={styles.employeeButton} onPress={() => choose(employee)} />)}
        {!store.employees.length && <Text style={styles.empty}>No employees yet. You can use StorePro yourself or add one below.</Text>}
        {adding ? <View style={styles.addBox}>
          <TextField label="Employee name" placeholder="Full name" value={name} onChangeText={setName} autoFocus />
          <View style={styles.row}><AppButton title="Cancel" variant="outline" style={styles.flex} onPress={() => setAdding(false)} /><AppButton title={saving ? 'Saving…' : 'Add and continue'} disabled={saving} style={styles.flex} onPress={addEmployee} /></View>
        </View> : <AppButton title="Add employee" icon="add" variant="soft" style={styles.addButton} onPress={() => setAdding(true)} />}
      </Card>
      <Text style={styles.note}>This choice labels activity. Your store owner account stays signed in.</Text>
    </View>
  </View>;
}

const styles = createThemeAwareStyles({
  root: { flex: 1, justifyContent: 'center', backgroundColor: colors.background, padding: 20 },
  content: { width: '100%', maxWidth: 480, alignSelf: 'center' },
  brand: { alignItems: 'center', gap: 9, marginBottom: 27 },
  brandIcon: { width: 48, height: 48, borderRadius: 15, alignItems: 'center', justifyContent: 'center', backgroundColor: colors.primary },
  brandName: { color: colors.text, fontSize: 21, fontWeight: '800' },
  title: { textAlign: 'center', color: colors.text, fontSize: 24, fontWeight: '800' },
  subtitle: { marginTop: 7, marginBottom: 18, textAlign: 'center', color: colors.muted, fontSize: 15, lineHeight: 21 },
  card: { gap: 10 }, employeeButton: { marginTop: 2 }, empty: { paddingVertical: 5, color: colors.muted, textAlign: 'center', fontSize: 14, lineHeight: 20 },
  addBox: { marginTop: 8, paddingTop: 12, borderTopWidth: 1, borderTopColor: colors.border },
  row: { flexDirection: 'row', gap: 9 }, flex: { flex: 1 }, addButton: { marginTop: 4 },
  note: { color: colors.muted, fontSize: 13, lineHeight: 19, textAlign: 'center', marginTop: 16 },
});
