import React from 'react';
import { EmailAuthProvider, reauthenticateWithCredential, updatePassword } from 'firebase/auth';
import { auth } from '../firebaseClient.js';
import { Button, Card, Modal, PageHeader, StatusPill, SelectField, TextField } from '../components/UI.jsx';
import Icon from '../components/Icon.jsx';
import { money } from '../data/formatters.js';

export function CategoriesPage({ store, notify }) {
  const [open, setOpen] = React.useState(false);
  const [name, setName] = React.useState('');
  const [query, setQuery] = React.useState('');
  const categoryRows = store.categories
    .map((category) => ({
      name: category,
      count: store.products.filter((product) => product.category === category).length,
      units: store.products.filter((product) => product.category === category).reduce((sum, product) => sum + product.stock, 0),
    }))
    .filter((item) => item.name.toLowerCase().includes(query.toLowerCase()));

  const submit = async (event) => {
    event.preventDefault();
    if (!name.trim()) return;
    try {
      await store.addCategory(name.trim());
      notify('Category added.');
      setName('');
      setOpen(false);
    } catch (error) {
      notify(error.message);
    }
  };

  return (
    <>
      <PageHeader title="Categories" description="Keep your product catalog organized." action={<Button icon="plus" onClick={() => setOpen(true)}>Add category</Button>} />
      <Card className="catalog-card">
        <div className="catalog-toolbar"><label className="search-field"><Icon name="search" /><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search categories" aria-label="Search categories" /></label><span className="result-count">{categoryRows.length} categories</span></div>
        <div className="category-grid">{categoryRows.map((item, index) => <article className="category-card" key={item.name}><span className={'category-icon category-tone-' + (index % 4)}><Icon name="categories" /></span><div className="category-copy"><h2>{item.name}</h2><p>{item.count} {item.count === 1 ? 'product variant' : 'product variants'} · {item.units} units</p></div><span className="result-count">{item.count}</span></article>)}</div>
        {!categoryRows.length && <div className="empty-state"><strong>No categories found</strong></div>}
      </Card>
      {open && <Modal title="Add category" description="Create a category for your shared catalog." onClose={() => setOpen(false)} footer={<><Button variant="outline" onClick={() => setOpen(false)}>Cancel</Button><Button icon="check" type="submit" form="add-category-form">Save category</Button></>}><form id="add-category-form" onSubmit={submit}><TextField label="Category name" placeholder="e.g. Snacks" value={name} onChange={(event) => setName(event.target.value)} required autoFocus /></form></Modal>}
    </>
  );
}

export function CustomersPage({ store }) {
  const [query, setQuery] = React.useState('');
  const customers = store.customers.filter((customer) => (customer.name + ' ' + customer.phone).toLowerCase().includes(query.toLowerCase()));
  return (
    <>
      <PageHeader title="Customers" description="See the people who shop at your store." action={<StatusPill tone="neutral">{store.customers.length} profiles</StatusPill>} />
      <Card className="catalog-card">
        <div className="catalog-toolbar"><label className="search-field"><Icon name="search" /><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search customers" aria-label="Search customers" /></label><span className="result-count">{customers.length} customers</span></div>
        <div className="table-wrap"><table className="data-table"><thead><tr><th>Customer</th><th>Phone</th><th>Visits</th><th>Total spent</th></tr></thead><tbody>{customers.map((customer) => <tr key={customer.id}><td><div className="product-cell"><span className="profile-avatar customer-avatar">{customer.name.split(' ').map((part) => part[0]).slice(0, 2).join('').toUpperCase()}</span><strong>{customer.name}</strong></div></td><td>{customer.phone || '—'}</td><td>{customer.visits || 0}</td><td><strong>{money(customer.spent)}</strong></td></tr>)}</tbody></table></div>
        {!customers.length && <div className="empty-state"><strong>No customers found</strong></div>}
      </Card>
    </>
  );
}

export function EmployeesPage({ store, notify }) {
  const [open, setOpen] = React.useState(false);
  const [name, setName] = React.useState('');
  const [editTarget, setEditTarget] = React.useState(null);
  const [editName, setEditName] = React.useState('');
  const [savingEdit, setSavingEdit] = React.useState(false);
  const [removeTarget, setRemoveTarget] = React.useState(null);
  const [removing, setRemoving] = React.useState(false);
  const submit = async (event) => {
    event.preventDefault();
    if (!name.trim()) return;
    try {
      await store.addEmployee({ name: name.trim() });
      notify('Employee added.');
      setName('');
      setOpen(false);
    } catch (error) {
      notify(error.message);
    }
  };
  const confirmRemove = async () => {
    if (!removeTarget) return;
    const wasActive = store.activeEmployee?.id === removeTarget.id;
    setRemoving(true);
    try {
      await store.removeEmployee(removeTarget.id);
      notify(wasActive ? `${removeTarget.name} removed. StorePro switched back to you.` : `${removeTarget.name} removed.`);
      setRemoveTarget(null);
    } catch (error) {
      notify(error.message);
    } finally {
      setRemoving(false);
    }
  };
  const beginEdit = (employee) => {
    setEditTarget(employee);
    setEditName(employee.name);
  };
  const saveEdit = async (event) => {
    event.preventDefault();
    if (!editTarget) return;
    if (!editName.trim()) return notify('Enter the employee name.');
    setSavingEdit(true);
    try {
      await store.updateEmployee(editTarget.id, { name: editName.trim() });
      notify('Employee details updated.');
      setEditTarget(null);
    } catch (error) {
      notify(error.message);
    } finally {
      setSavingEdit(false);
    }
  };
  return (
    <>
      <div className="employee-page-heading"><PageHeader title="Employees" description="Choose who is using the register and record their activity." action={<Button className="employee-page-add-button" icon="plus" onClick={() => setOpen(true)}>Add employee</Button>} /></div>
      <div className="team-grid">{store.employees.map((employee, index) => <Card className="team-card" key={employee.id}><div className="team-card-identity"><div className={'team-avatar team-avatar-' + (index % 4)}>{employee.name.split(' ').map((part) => part[0]).slice(0, 2).join('').toUpperCase()}</div><div className="team-card-copy"><h2>{employee.name}</h2><p>Store employee</p></div></div><div className="team-card-actions"><StatusPill tone="success">Active</StatusPill><Button variant="outline" size="sm" icon="edit" disabled={savingEdit || removing} onClick={() => beginEdit(employee)}>Edit</Button><Button variant="danger" size="sm" disabled={savingEdit || removing} onClick={() => setRemoveTarget(employee)}>Remove</Button></div></Card>)}</div>
      {!store.employees.length && <div className="empty-state"><strong>No employees added yet</strong><p>You can use StorePro yourself or add a staff member.</p></div>}
      {open && <Modal title="Add employee" description="Add a name for the register." onClose={() => setOpen(false)} footer={<><Button variant="outline" onClick={() => setOpen(false)}>Cancel</Button><Button icon="check" type="submit" form="team-form">Add employee</Button></>}><form id="team-form" className="form-grid" onSubmit={submit}><TextField label="Full name" placeholder="Staff member name" value={name} onChange={(event) => setName(event.target.value)} required autoFocus /></form></Modal>}
      {editTarget && <Modal title="Edit employee" description={`Update details for ${editTarget.name}.`} onClose={() => { if (!savingEdit) setEditTarget(null); }} footer={<><Button variant="outline" disabled={savingEdit} onClick={() => setEditTarget(null)}>Cancel</Button><Button icon="check" disabled={savingEdit} type="submit" form="edit-team-form">{savingEdit ? 'Saving…' : 'Save changes'}</Button></>}><form id="edit-team-form" className="form-grid" onSubmit={saveEdit}><TextField label="Full name" value={editName} onChange={(event) => setEditName(event.target.value)} required autoFocus /></form></Modal>}
      {removeTarget && <Modal title="Remove employee?" description={`Remove ${removeTarget.name} from the employee sign-in list?`} onClose={() => { if (!removing) setRemoveTarget(null); }} footer={<><Button variant="outline" disabled={removing} onClick={() => setRemoveTarget(null)}>Keep employee</Button><Button variant="danger" disabled={removing} onClick={confirmRemove}>{removing ? 'Removing…' : 'Remove employee'}</Button></>}><p className="employee-remove-note">Their past sales and stock activity will remain in your records.</p></Modal>}
    </>
  );
}

export function SettingsPage({ store, notify, theme = 'system', onThemeChange = () => {} }) {
  const savedFirstName = store.profile?.firstName || store.profile?.ownerName?.split(' ')[0] || '';
  const savedLastName = store.profile?.lastName || store.profile?.ownerName?.split(' ').slice(1).join(' ') || '';
  const savedUsername = store.profile?.username || '';
  const savedStoreName = store.settings.storeName || 'My Store';
  const [firstName, setFirstName] = React.useState(store.profile?.firstName || store.profile?.ownerName?.split(' ')[0] || '');
  const [lastName, setLastName] = React.useState(store.profile?.lastName || store.profile?.ownerName?.split(' ').slice(1).join(' ') || '');
  const [username, setUsername] = React.useState(store.profile?.username || '');
  const [storeName, setStoreName] = React.useState(store.settings.storeName);
  const [threshold, setThreshold] = React.useState(String(store.settings.lowStockThreshold));
  const [passwordOpen, setPasswordOpen] = React.useState(false);
  const [profileEditOpen, setProfileEditOpen] = React.useState(false);
  const [saving, setSaving] = React.useState(false);
  const beginProfileEdit = () => {
    setFirstName(store.profile?.firstName || store.profile?.ownerName?.split(' ')[0] || '');
    setLastName(store.profile?.lastName || store.profile?.ownerName?.split(' ').slice(1).join(' ') || '');
    setUsername(store.profile?.username || '');
    setStoreName(store.settings.storeName || 'My Store');
    setThreshold(String(store.settings.lowStockThreshold ?? 12));
    setProfileEditOpen(true);
  };
  const save = async (event) => {
    event.preventDefault();
    setSaving(true);
    try {
      await store.updateSettings({ firstName: firstName.trim(), lastName: lastName.trim(), username: username.trim(), storeName: storeName.trim() || 'My Store', lowStockThreshold: Number(threshold) || 0 });
      notify('Profile and store settings saved.');
      setProfileEditOpen(false);
    } catch (error) {
      notify(error.message);
    } finally {
      setSaving(false);
    }
  };
  const savePreference = async (key, value) => {
    try {
      await store.updateSettings({ [key]: value });
      notify('Preference saved.');
    } catch (error) {
      notify(error.message);
    }
  };
  const changePassword = async (current, next) => {
    const signedIn = auth.currentUser;
    if (!signedIn?.email) throw new Error('Sign in again before changing your password.');
    await reauthenticateWithCredential(signedIn, EmailAuthProvider.credential(signedIn.email, current));
    await updatePassword(signedIn, next);
    setPasswordOpen(false);
    notify('Password updated.');
  };
  return (
    <>
      <div className="settings-page">
        <PageHeader title="Settings" description="Profile, store, and account preferences." />
        <div className="settings-layout settings-sections">
        <Card className="settings-card settings-profile-card">
          <div className="settings-profile-heading">
            <div className="settings-title"><span className="settings-icon"><Icon name="employees" /></span><div><h2>Profile</h2><p>Your name and store details.</p></div></div>
            <Button icon="edit" variant="outline" onClick={beginProfileEdit}>Edit</Button>
          </div>
          <div className="settings-profile-identity"><span className="settings-profile-avatar">{[savedFirstName, savedLastName].filter(Boolean).map((part) => part[0]).join('').slice(0, 2).toUpperCase() || 'S'}</span><div><strong>{[savedFirstName, savedLastName].filter(Boolean).join(' ') || 'Store owner'}</strong><span>{savedUsername ? `@${savedUsername}` : 'Store owner'}</span></div></div>
          <div className="settings-profile-details">
            <ProfileDetail icon="employees" label="Name" value={[savedFirstName, savedLastName].filter(Boolean).join(' ') || 'Not set'} />
            <ProfileDetail icon="customers" label="Username" value={savedUsername ? `@${savedUsername}` : 'Not set'} />
            <ProfileDetail icon="inventory" label="Store name" value={savedStoreName} />
            <ProfileDetail icon="notes" label="Email" value={auth.currentUser?.email || store.profile?.email || 'Not available'} />
            <ProfileDetail icon="warning" label="Low stock alert" value={`${store.settings.lowStockThreshold ?? 12} units`} />
          </div>
        </Card>
        <Card className="settings-card settings-appearance-card">
          <div className="settings-title"><span className="settings-icon"><Icon name="sun" /></span><div><h2>Appearance</h2><p>Choose a comfortable display theme.</p></div></div>
          <div className="appearance-options" role="group" aria-label="Appearance theme">
            {[
              ['system', 'System', 'settings'],
              ['light', 'Light', 'sun'],
              ['dark', 'Dark', 'moon'],
            ].map(([value, label, icon]) => <button key={value} type="button" className={`appearance-option${theme === value ? ' appearance-option-active' : ''}`} aria-pressed={theme === value} onClick={() => onThemeChange(value)}><Icon name={icon} size={19} /><span>{label}</span></button>)}
          </div>
        </Card>
        <Card className="settings-card">
          <div className="settings-title"><span className="settings-icon"><Icon name="settings" /></span><div><h2>Preferences</h2><p>Choose what StorePro records and shows.</p></div></div>
          <div className="settings-form">
            <label className="settings-row"><span><strong>Activity tracking</strong><small>Record product, sale, and refund activity.</small></span><input type="checkbox" checked={store.settings.trackActivity !== false} onChange={(event) => savePreference('trackActivity', event.target.checked)} /></label>
            <label className="settings-row"><span><strong>Stock and expiry alerts</strong><small>Show alerts on the dashboard.</small></span><input type="checkbox" checked={store.settings.notificationsEnabled !== false} onChange={(event) => savePreference('notificationsEnabled', event.target.checked)} /></label>
          </div>
        </Card>
        <Card className="settings-card">
          <div className="settings-title"><span className="settings-icon"><Icon name="settings" /></span><div><h2>Account</h2><p>Keep your sign-in secure.</p></div></div>
          <div className="settings-account-actions"><Button variant="outline" onClick={() => setPasswordOpen(true)}>Change password</Button><Button variant="outline" onClick={() => store.signOut().catch((error) => notify(error.message))}>Sign out</Button></div>
        </Card>
        </div>
      </div>
      {profileEditOpen && <Modal title="Edit profile and store" description="Changes are saved only when you select Save changes." onClose={() => setProfileEditOpen(false)} footer={<><Button variant="outline" onClick={() => setProfileEditOpen(false)}>Cancel</Button><Button icon="check" type="submit" form="settings-profile-form" disabled={saving}>{saving ? 'Saving…' : 'Save changes'}</Button></>}>
        <form id="settings-profile-form" className="form-grid settings-edit-form" onSubmit={save}>
          <TextField label="First name" value={firstName} onChange={(event) => setFirstName(event.target.value)} required autoFocus />
          <TextField label="Last name" value={lastName} onChange={(event) => setLastName(event.target.value)} />
          <TextField label="Username" value={username} onChange={(event) => setUsername(event.target.value)} />
          <TextField label="Email address" type="email" value={auth.currentUser?.email || store.profile?.email || ''} readOnly />
          <TextField label="Store name" value={storeName} onChange={(event) => setStoreName(event.target.value)} required />
          <TextField label="Low stock alert threshold" type="number" min="0" value={threshold} onChange={(event) => setThreshold(event.target.value)} hint="Each product can also have its own threshold." />
        </form>
      </Modal>}
      {passwordOpen && <ChangePasswordModal onClose={() => setPasswordOpen(false)} onSave={changePassword} />}
    </>
  );
}

function ProfileDetail({ icon, label, value }) {
  return <div className="settings-profile-row"><span className="settings-profile-row-icon"><Icon name={icon} size={19} /></span><span className="settings-profile-label">{label}</span><strong className="settings-profile-value">{value}</strong></div>;
}

function ChangePasswordModal({ onClose, onSave }) {
  const [current, setCurrent] = React.useState('');
  const [next, setNext] = React.useState('');
  const [confirm, setConfirm] = React.useState('');
  const [error, setError] = React.useState('');
  const [saving, setSaving] = React.useState(false);
  const submit = async (event) => {
    event.preventDefault();
    setError('');
    if (next.length < 6) return setError('Use at least 6 characters for the new password.');
    if (next !== confirm) return setError('The new passwords do not match.');
    setSaving(true);
    try { await onSave(current, next); } catch (reason) { setError(reason.message || 'Could not update the password.'); } finally { setSaving(false); }
  };
  return <Modal title="Change password" description="Enter your current password to confirm this change." onClose={onClose} footer={<><Button variant="outline" onClick={onClose}>Cancel</Button><Button type="submit" form="password-form" disabled={saving}>{saving ? 'Saving…' : 'Update password'}</Button></>}>
    <form id="password-form" className="form-grid" onSubmit={submit}><TextField label="Current password" type="password" value={current} onChange={(event) => setCurrent(event.target.value)} required autoFocus /><TextField label="New password" type="password" value={next} onChange={(event) => setNext(event.target.value)} required /><TextField label="Confirm new password" type="password" value={confirm} onChange={(event) => setConfirm(event.target.value)} required />{error && <p className="auth-message auth-error" role="alert">{error}</p>}</form>
  </Modal>;
}

