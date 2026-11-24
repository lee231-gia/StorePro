import React from 'react';
import { Button, Card, TextField } from '../components/UI.jsx';
import Icon from '../components/Icon.jsx';

export default function EmployeeSessionPage({ store, notify }) {
  const [adding, setAdding] = React.useState(false);
  const [name, setName] = React.useState('');
  const [error, setError] = React.useState('');
  const [saving, setSaving] = React.useState(false);
  const owner = { id: 'owner', name: store.profile?.ownerName || store.user?.email || 'Store owner' };

  const choose = (employee) => {
    setError('');
    store.selectEmployee(employee);
  };
  const chooseOwner = () => {
    setError('');
    store.selectEmployee(owner);
  };
  const addEmployee = async (event) => {
    event.preventDefault();
    setError('');
    setSaving(true);
    try {
      const employee = await store.addEmployee({ name: name.trim() });
      notify('Employee added.');
      store.selectEmployee(employee);
    } catch (reason) {
      setError(reason.message || 'Could not add employee. Try again.');
    } finally {
      setSaving(false);
    }
  };
  const backToSignIn = async () => {
    setError('');
    try {
      await store.signOut();
    } catch (reason) {
      setError(reason.message || 'Could not return to sign in. Try again.');
    }
  };

  return <main className="employee-session-page">
    <Button className="employee-back-button" variant="ghost" icon="arrow-left" onClick={backToSignIn}>Back to sign in</Button>
    <Card className="employee-session-card">
      <div className="employee-session-brand"><span className="employee-session-mark"><Icon name="box" size={24} /></span><strong>StorePro</strong></div>
      <h1>Who is using the register?</h1>
      <p>Choose a name so sales and stock changes are recorded correctly.</p>
      <div className="employee-choice-list">
        <Button icon="employees" onClick={chooseOwner}>Just me · {owner.name}</Button>
        {store.employees.map((employee) => <Button key={employee.id} icon="employees" variant="outline" onClick={() => choose(employee)}>{employee.name}</Button>)}
      </div>
      {!store.employees.length && <p className="employee-empty">No employees yet. You can use StorePro yourself or add one below.</p>}
      {adding ? <form className="employee-inline-form" onSubmit={addEmployee}>
        <TextField label="Employee name" value={name} onChange={(event) => setName(event.target.value)} autoFocus required />
        <div className="employee-inline-actions"><Button type="button" variant="outline" onClick={() => setAdding(false)}>Cancel</Button><Button type="submit" disabled={saving}>{saving ? 'Saving…' : 'Add and continue'}</Button></div>
      </form> : <div className="employee-add-action"><Button className="employee-add-button" variant="secondary" icon="plus" onClick={() => setAdding(true)}>Add employee</Button></div>}
      {error && <p className="employee-session-error" role="alert">{error}</p>}
      <p className="employee-session-note">This choice labels activity. Your store owner account stays signed in.</p>
    </Card>
  </main>;
}
