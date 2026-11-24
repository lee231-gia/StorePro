import React from 'react';
import { Alert, Pressable, Switch, Text, View } from 'react-native';
import { EmailAuthProvider, reauthenticateWithCredential, updatePassword } from 'firebase/auth';
import { AppButton, AppModal, AppIcon, Card, Screen, SectionTitle, StatusPill, TextField } from '../components/Ui';
import SearchBox from '../components/SearchBox';
import { formatMoney } from '../data/formatters';
import { useStore } from '../store/StoreProvider';
import { colors, createThemeAwareStyles, useAppTheme } from '../theme';
import { auth } from '../firebaseClient';

export function CategoriesScreen() {
  const store = useStore();
  const [open, setOpen] = React.useState(false);
  const [name, setName] = React.useState('');
  const save = async () => {
    if (!name.trim()) return Alert.alert('Enter a category name', 'Category name cannot be empty.');
    if (store.categories.includes(name.trim())) return Alert.alert('Already exists', 'Choose a different category name.');
    try {
      await store.addCategory(name.trim());
      setName(''); setOpen(false);
      Alert.alert('Category added', name.trim());
    } catch (error) {
      Alert.alert('Could not add category', error.message);
    }
  };
  return <>
    <Screen title="Categories" subtitle="Organize your product catalog." action={<AppButton title="Add" compact icon="add" onPress={() => setOpen(true)} />}>
      <SectionTitle title={`${store.categories.length} categories`} />
      <View style={styles.directoryList}>{store.categories.map((category, index) => {
        const items = store.products.filter((product) => product.category === category);
        const units = items.reduce((sum, product) => sum + product.stock, 0);
        return <Card key={category} style={styles.categoryCard}><View style={[styles.directoryIcon, styles[`tone${index % 4}`]]}><AppIcon name="pricetags-outline" size={21} color={colors.primary} /></View><View style={styles.directoryCopy}><Text style={styles.directoryName}>{category}</Text><Text style={styles.directorySubtitle}>{items.length} products · {units} units</Text></View><AppIcon name="chevron-forward" size={19} color="#718078" /></Card>;
      })}</View>
    </Screen>
    <AppModal visible={open} title="Add category" subtitle="Create a category for your products." onClose={() => setOpen(false)} actions={<><AppButton title="Cancel" variant="outline" style={styles.action} onPress={() => setOpen(false)} /><AppButton title="Save category" icon="checkmark" style={styles.action} onPress={save} /></>}><TextField label="Category name" placeholder="e.g. Snacks" value={name} onChangeText={setName} autoFocus /></AppModal>
  </>;
}

export function CustomersScreen() {
  const store = useStore();
  const [query, setQuery] = React.useState('');
  const customers = store.customers.filter((customer) => `${customer.name} ${customer.phone}`.toLowerCase().includes(query.toLowerCase()));
  return <Screen title="Customers" subtitle="Your customer directory.">
    <SearchBox value={query} onChangeText={setQuery} placeholder="Search customers" />
    <SectionTitle title={`${customers.length} profiles`} />
    <Card style={styles.list}>{customers.map((customer, index) => <View key={customer.id} style={styles.customerRow}><View style={[styles.avatar, styles[`tone${index % 4}`]]}><Text style={styles.avatarText}>{customer.name.split(' ').map((word) => word[0]).slice(0, 2).join('')}</Text></View><View style={styles.directoryCopy}><Text style={styles.directoryName}>{customer.name}</Text><Text style={styles.directorySubtitle}>{customer.phone} · {customer.visits} visits</Text></View><Text style={styles.customerSpent}>{formatMoney(customer.spent)}</Text></View>)}</Card>
  </Screen>;
}

export function TeamScreen() {
  const store = useStore();
  const [open, setOpen] = React.useState(false);
  const [name, setName] = React.useState('');
  const [saving, setSaving] = React.useState(false);
  const [editing, setEditing] = React.useState(null);
  const [editName, setEditName] = React.useState('');
  const [savingEdit, setSavingEdit] = React.useState(false);
  const [removingId, setRemovingId] = React.useState('');
  const save = async () => {
    if (!name.trim()) return Alert.alert('Enter a name', 'The staff member’s name is required.');
    setSaving(true);
    try {
      await store.addEmployee({ name: name.trim() });
      setOpen(false); setName('');
      Alert.alert('Team member added', `${name.trim()} can now be selected at the register.`);
    } catch (error) {
      Alert.alert('Could not add team member', error.message);
    } finally {
      setSaving(false);
    }
  };
  const confirmRemove = (employee) => {
    const wasActive = store.activeEmployee?.id === employee.id;
    Alert.alert('Remove employee?', `${employee.name} will be removed from the employee list. Past sales and stock activity will remain.`, [
      { text: 'Keep employee', style: 'cancel' },
      { text: 'Remove', style: 'destructive', onPress: async () => {
        setRemovingId(employee.id);
        try {
          await store.removeEmployee(employee.id);
          Alert.alert('Employee removed', wasActive ? 'StorePro switched back to you.' : `${employee.name} was removed.`);
        } catch (error) {
          Alert.alert('Could not remove employee', error.message);
        } finally {
          setRemovingId('');
        }
      } },
    ]);
  };
  const beginEdit = (employee) => {
    setEditing(employee);
    setEditName(employee.name);
  };
  const saveEdit = async () => {
    if (!editing) return;
    if (!editName.trim()) return Alert.alert('Enter a name', 'The staff member’s name is required.');
    setSavingEdit(true);
    try {
      await store.updateEmployee(editing.id, { name: editName.trim() });
      setEditing(null);
      Alert.alert('Team member updated', `${editName.trim()}’s details were saved.`);
    } catch (error) {
      Alert.alert('Could not update team member', error.message);
    } finally {
      setSavingEdit(false);
    }
  };
  return <>
    <Screen title="Team" subtitle="Staff members at your store." action={<AppButton title="Add" compact icon="add" onPress={() => setOpen(true)} />}>
      <View style={styles.directoryList}>{store.employees.length ? store.employees.map((employee, index) => <Card key={employee.id} style={styles.employeeCard}><View style={[styles.avatar, styles[`tone${index % 4}`]]}><Text style={styles.avatarText}>{employee.name.split(' ').map((word) => word[0]).slice(0, 2).join('')}</Text></View><View style={styles.directoryCopy}><Text style={styles.directoryName}>{employee.name}</Text><Text style={styles.directorySubtitle}>Store employee</Text></View><View style={styles.employeeCardActions}><StatusPill label="Active" tone="success" /><View style={styles.employeeCardButtons}><AppButton title="Edit" variant="outline" compact disabled={Boolean(removingId) || savingEdit} style={styles.employeeActionButton} onPress={() => beginEdit(employee)} /><AppButton title={removingId === employee.id ? 'Removing…' : 'Remove'} variant="danger" compact disabled={Boolean(removingId) || savingEdit} style={styles.employeeActionButton} onPress={() => confirmRemove(employee)} /></View></View></Card>) : <Card><Text style={styles.directoryName}>No employees yet</Text><Text style={styles.directorySubtitle}>You can use StorePro yourself or add a staff member.</Text></Card>}</View>
    </Screen>
    <AppModal visible={open} title="Add team member" subtitle="Add a staff member who can be selected for sales and stock logs." onClose={() => setOpen(false)} actions={<><AppButton title="Cancel" variant="outline" style={styles.action} onPress={() => setOpen(false)} /><AppButton title={saving ? 'Saving…' : 'Add member'} icon="checkmark" disabled={saving} style={styles.action} onPress={save} /></>}>
      <TextField label="Full name" placeholder="Staff member name" value={name} onChangeText={setName} autoFocus />
    </AppModal>
    <AppModal visible={Boolean(editing)} title="Edit team member" subtitle={editing ? `Update details for ${editing.name}.` : ''} onClose={() => { if (!savingEdit) setEditing(null); }} actions={<><AppButton title="Cancel" variant="outline" disabled={savingEdit} style={styles.action} onPress={() => setEditing(null)} /><AppButton title={savingEdit ? 'Saving…' : 'Save changes'} icon="checkmark" disabled={savingEdit} style={styles.action} onPress={saveEdit} /></>}>
      <TextField label="Full name" value={editName} onChangeText={setEditName} autoFocus />
    </AppModal>
  </>;
}

export function SettingsScreen() {
  const store = useStore();
  const theme = useAppTheme();
  const [firstName, setFirstName] = React.useState(store.profile?.firstName || store.profile?.ownerName?.split(' ')[0] || '');
  const [lastName, setLastName] = React.useState(store.profile?.lastName || store.profile?.ownerName?.split(' ').slice(1).join(' ') || '');
  const [username, setUsername] = React.useState(store.profile?.username || '');
  const [storeNameDraft, setStoreNameDraft] = React.useState(null);
  const [thresholdDraft, setThresholdDraft] = React.useState(null);
  const [passwordOpen, setPasswordOpen] = React.useState(false);
  const [currentPassword, setCurrentPassword] = React.useState('');
  const [newPassword, setNewPassword] = React.useState('');
  const [confirmPassword, setConfirmPassword] = React.useState('');
  const [saving, setSaving] = React.useState(false);
  const storeName = storeNameDraft ?? store.settings.storeName;
  const threshold = thresholdDraft ?? String(store.settings.lowStockThreshold);
  const save = async () => {
    if (!firstName.trim()) return Alert.alert('Enter your first name', 'Your first name is required.');
    setSaving(true);
    try {
      await store.updateSettings({ firstName: firstName.trim(), lastName: lastName.trim(), username: username.trim(), storeName: storeName.trim() || 'My Store', lowStockThreshold: Math.max(0, Number(threshold) || 0) });
      setStoreNameDraft(null);
      setThresholdDraft(null);
      Alert.alert('Saved', 'Your profile and store settings are updated.');
    } catch (error) {
      Alert.alert('Could not save settings', error.message);
    } finally {
      setSaving(false);
    }
  };
  const togglePreference = async (key, value, title) => {
    try {
      await store.updateSettings({ [key]: value });
      Alert.alert('Preference saved', `${title} is now ${value ? 'on' : 'off'}.`);
    } catch (error) { Alert.alert('Could not save preference', error.message); }
  };
  const submitPassword = async () => {
    if (newPassword.length < 6) return Alert.alert('Password is too short', 'Use at least 6 characters.');
    if (newPassword !== confirmPassword) return Alert.alert('Passwords do not match', 'Enter the same new password twice.');
    setSaving(true);
    try {
      const user = auth.currentUser;
      if (!user?.email) throw new Error('Sign in again before changing your password.');
      await reauthenticateWithCredential(user, EmailAuthProvider.credential(user.email, currentPassword));
      await updatePassword(user, newPassword);
      setPasswordOpen(false); setCurrentPassword(''); setNewPassword(''); setConfirmPassword('');
      Alert.alert('Password updated', 'Your sign-in password has been changed.');
    } catch (error) { Alert.alert('Could not change password', error.message); }
    finally { setSaving(false); }
  };
  return <>
  <Screen title="Settings" subtitle="Profile, store, and account preferences.">
    <Card style={styles.settingsCard}><View style={styles.settingsHeader}><View style={styles.directoryIcon}><AppIcon name="person-outline" size={22} color={colors.primary} /></View><View style={styles.directoryCopy}><Text style={styles.directoryName}>Profile and store</Text><Text style={styles.directorySubtitle}>Update the details shown in StorePro.</Text></View></View>
      <View style={styles.settingsForm}><View style={styles.formRow}><View style={styles.formCell}><TextField label="First name" value={firstName} onChangeText={setFirstName} /></View><View style={styles.formCell}><TextField label="Last name" value={lastName} onChangeText={setLastName} /></View></View><TextField label="Username" value={username} onChangeText={setUsername} /><TextField label="Email address" value={store.user?.email || ''} editable={false} autoCapitalize="none" /><TextField label="Store name" value={storeName} onChangeText={setStoreNameDraft} /><TextField label="Default low-stock alert" keyboardType="number-pad" value={threshold} onChangeText={setThresholdDraft} hint="Products can have their own alert level." /><AppButton title={saving ? 'Saving…' : 'Save changes'} icon="checkmark" disabled={saving} onPress={save} /></View>
    </Card>
    <Card style={styles.settingsCard}><View style={styles.settingsHeader}><View style={styles.directoryIcon}><AppIcon name="contrast-outline" size={22} color={colors.primary} /></View><View style={styles.directoryCopy}><Text style={styles.directoryName}>Appearance</Text><Text style={styles.directorySubtitle}>Choose how StorePro looks on this device.</Text></View></View><View style={styles.appearanceOptions}>{[['system', 'System'], ['light', 'Light'], ['dark', 'Dark']].map(([mode, label]) => <Pressable key={mode} accessibilityRole="button" accessibilityState={{ selected: theme.themePreference === mode }} onPress={() => theme.setThemePreference(mode)} style={[styles.appearanceOption, theme.themePreference === mode && styles.appearanceOptionSelected]}><Text style={[styles.appearanceLabel, theme.themePreference === mode && styles.appearanceLabelSelected]}>{label}</Text></Pressable>)}</View></Card>
    <Card style={styles.settingsCard}><Text style={styles.directoryName}>Preferences</Text><Text style={styles.directorySubtitle}>Choose what StorePro records and shows.</Text>
      <View style={styles.preferenceRow}><View style={styles.preferenceCopy}><Text style={styles.settingTitle}>Activity tracking</Text><Text style={styles.directorySubtitle}>Record product, sale, and refund activity.</Text></View><Switch value={store.settings.trackActivity !== false} onValueChange={(value) => togglePreference('trackActivity', value, 'Activity tracking')} trackColor={{ false: '#B9C7C1', true: colors.primary }} /></View>
      <View style={styles.preferenceRow}><View style={styles.preferenceCopy}><Text style={styles.settingTitle}>Stock and expiry alerts</Text><Text style={styles.directorySubtitle}>Show alerts on the dashboard.</Text></View><Switch value={store.settings.notificationsEnabled !== false} onValueChange={(value) => togglePreference('notificationsEnabled', value, 'Stock and expiry alerts')} trackColor={{ false: '#B9C7C1', true: colors.primary }} /></View>
    </Card>
    <Card style={styles.settingsCard}><Text style={styles.directoryName}>Account</Text><Text style={styles.directorySubtitle}>Keep your sign-in secure.</Text><View style={styles.accountActions}><AppButton title="Change password" icon="lock-closed-outline" variant="outline" onPress={() => setPasswordOpen(true)} /><AppButton title="Sign out" icon="log-out-outline" variant="outline" onPress={() => store.signOut().catch((error) => Alert.alert('Could not sign out', error.message))} /></View></Card>
  </Screen>
  <AppModal visible={passwordOpen} title="Change password" subtitle="Enter your current password to confirm this change." onClose={() => setPasswordOpen(false)} actions={<><AppButton title="Cancel" variant="outline" style={styles.action} onPress={() => setPasswordOpen(false)} /><AppButton title={saving ? 'Saving…' : 'Update password'} disabled={saving} style={styles.action} onPress={submitPassword} /></>}>
    <TextField label="Current password" value={currentPassword} onChangeText={setCurrentPassword} secureTextEntry autoCapitalize="none" autoFocus />
    <TextField label="New password" value={newPassword} onChangeText={setNewPassword} secureTextEntry autoCapitalize="none" />
    <TextField label="Confirm new password" value={confirmPassword} onChangeText={setConfirmPassword} secureTextEntry autoCapitalize="none" />
  </AppModal>
  </>;
}

const styles = createThemeAwareStyles({
  directoryList: { gap: 9 },
  categoryCard: { flexDirection: 'row', alignItems: 'center', gap: 12, minHeight: 78 },
  directoryIcon: { width: 44, height: 44, borderRadius: 13, alignItems: 'center', justifyContent: 'center', backgroundColor: colors.primarySoft },
  directoryCopy: { flex: 1, minWidth: 0, gap: 4 },
  directoryName: { color: colors.text, fontSize: 15, fontWeight: '800' },
  directorySubtitle: { color: colors.muted, fontSize: 14 },
  tone0: { backgroundColor: '#E5EFEB' }, tone1: { backgroundColor: '#F8F0D9' }, tone2: { backgroundColor: '#E7EEF2' }, tone3: { backgroundColor: '#F4E9E3' },
  list: { paddingHorizontal: 13, paddingVertical: 3 },
  customerRow: { minHeight: 70, flexDirection: 'row', alignItems: 'center', gap: 10, borderBottomWidth: 1, borderBottomColor: '#EDF1EF' },
  avatar: { width: 42, height: 42, borderRadius: 14, alignItems: 'center', justifyContent: 'center' },
  avatarText: { color: colors.primary, fontSize: 13, fontWeight: '800' },
  customerSpent: { color: colors.primary, fontSize: 14, fontWeight: '800' },
  employeeCard: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  employeeCardActions: { alignItems: 'flex-end', gap: 6 },
  employeeCardButtons: { flexDirection: 'row', gap: 6 },
  employeeActionButton: { minHeight: 36, paddingHorizontal: 9 },
  email: { color: colors.muted, fontSize: 12 },
  action: { flex: 1 },
  formLabel: { color: colors.text, fontSize: 14, fontWeight: '700', marginBottom: 8 },
  roleRow: { gap: 7, paddingBottom: 8 },
  roleChip: { minHeight: 40, justifyContent: 'center', paddingHorizontal: 12, borderWidth: 1, borderColor: colors.border, borderRadius: 20, backgroundColor: '#fff' },
  roleChipActive: { backgroundColor: colors.primary, borderColor: colors.primary },
  roleText: { color: colors.muted, fontSize: 13, fontWeight: '700' },
  roleTextActive: { color: '#fff' },
  settingsCard: { padding: 16 },
  settingsHeader: { flexDirection: 'row', alignItems: 'center', gap: 11, borderBottomWidth: 1, borderBottomColor: colors.border, paddingBottom: 15 },
  settingsForm: { paddingTop: 17 },
  appearanceOptions: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginTop: 15 },
  appearanceOption: { minWidth: 82, minHeight: 44, flex: 1, alignItems: 'center', justifyContent: 'center', paddingHorizontal: 12, borderWidth: 1, borderColor: colors.border, borderRadius: 11, backgroundColor: colors.surface },
  appearanceOptionSelected: { borderColor: colors.primary, backgroundColor: colors.primarySoft },
  appearanceLabel: { color: colors.text, fontSize: 14, fontWeight: '700' },
  appearanceLabelSelected: { color: colors.primary, fontWeight: '800' },
  formRow: { flexDirection: 'row', gap: 10 },
  formCell: { flex: 1 },
  preferenceRow: { minHeight: 66, flexDirection: 'row', alignItems: 'center', gap: 10, borderTopWidth: 1, borderTopColor: colors.border, paddingVertical: 8 },
  preferenceCopy: { flex: 1, gap: 3 },
  accountActions: { gap: 9, marginTop: 14 },
  settingLine: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingVertical: 8 },
  settingTitle: { color: colors.text, fontSize: 14, fontWeight: '800', marginBottom: 3 },
  note: { color: colors.muted, textAlign: 'center', fontSize: 12, lineHeight: 17, paddingHorizontal: 12 },
});
