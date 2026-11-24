import React from 'react';
import { Button, Card, Modal, PageHeader, SelectField, StatusPill, TextField } from '../components/UI.jsx';
import Icon from '../components/Icon.jsx';
import { money, shortDate } from '../data/formatters.js';

function daysUntil(value) {
  if (!value) return null;
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const date = new Date(value + 'T00:00:00');
  return Math.floor((date - today) / 86_400_000);
}

function expiryStatus(product) {
  const days = daysUntil(product.expiryDate);
  if (days === null) return 'no-date';
  if (days < 0) return 'expired';
  if (days <= 30) return 'urgent';
  if (days <= 90) return 'soon';
  return 'healthy';
}

const expiryLabels = {
  'no-date': 'No expiry date',
  expired: 'Expired',
  urgent: 'Expires soon',
  soon: 'Coming up',
  healthy: 'In date',
};
const expiryTones = {
  'no-date': 'neutral',
  expired: 'error',
  urgent: 'warning',
  soon: 'gold',
  healthy: 'success',
};

export function ExpiryPage({ store, notify }) {
  const [query, setQuery] = React.useState('');
  const [filter, setFilter] = React.useState('all');
  const [category, setCategory] = React.useState('All');
  const [selected, setSelected] = React.useState(null);
  const [expiryDate, setExpiryDate] = React.useState('');
  const products = store.products || [];
  const categories = ['All', ...new Set(products.map((product) => product.category).filter(Boolean))];
  const filtered = products
    .filter((product) => (category === 'All' || product.category === category))
    .filter((product) => (product.name + ' ' + product.sku + ' ' + product.category).toLowerCase().includes(query.toLowerCase()))
    .filter((product) => filter === 'all' || expiryStatus(product) === filter)
    .sort((a, b) => {
      const left = daysUntil(a.expiryDate);
      const right = daysUntil(b.expiryDate);
      return (left === null ? Number.MAX_SAFE_INTEGER : left) - (right === null ? Number.MAX_SAFE_INTEGER : right);
    });
  const expiredCount = products.filter((product) => expiryStatus(product) === 'expired').length;
  const urgentCount = products.filter((product) => expiryStatus(product) === 'urgent').length;
  const upcomingCount = products.filter((product) => expiryStatus(product) === 'soon').length;

  const saveExpiry = async (event) => {
    event.preventDefault();
    if (!selected) return;
    try {
      await store.setProductExpiryDate(selected.id, expiryDate);
      notify(expiryDate ? 'Expiry date saved.' : 'Expiry date cleared.');
      setSelected(null);
    } catch (error) {
      notify(error.message);
    }
  };

  return (
    <>
      <PageHeader title="Expiry" description="Check product dates and handle items that need attention." />
      <section className="inventory-metrics">
        <div className="inventory-mini"><span className="mini-icon mini-coral"><Icon name="expiry" /></span><span><small>Expired</small><strong>{expiredCount}</strong></span></div>
        <div className="inventory-mini"><span className="mini-icon mini-amber"><Icon name="clock" /></span><span><small>Within 30 days</small><strong>{urgentCount}</strong></span></div>
        <div className="inventory-mini"><span className="mini-icon mini-mint"><Icon name="calendar" /></span><span><small>Within 90 days</small><strong>{upcomingCount}</strong></span></div>
      </section>
      <Card className="catalog-card">
        <div className="catalog-toolbar expiry-toolbar">
          <label className="search-field"><Icon name="search" /><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search products" aria-label="Search products" /></label>
          <label className="field category-filter"><span>Category</span><select value={category} onChange={(event) => setCategory(event.target.value)}>{categories.map((item) => <option key={item}>{item}</option>)}</select></label>
        </div>
        <div className="filter-chips" role="group" aria-label="Filter expiry status">
          {[['all', 'All products'], ['expired', 'Expired'], ['urgent', 'Within 30 days'], ['soon', 'Within 90 days'], ['healthy', 'In date'], ['no-date', 'No date']].map(([key, label]) => <button key={key} className={'filter-chip ' + (filter === key ? 'filter-chip-active' : '')} onClick={() => setFilter(key)}>{label}</button>)}
        </div>
        <div className="table-wrap"><table className="data-table"><thead><tr><th>Product</th><th>Category</th><th>Stock</th><th>Expiry date</th><th>Status</th><th>Action</th></tr></thead>
          <tbody>{filtered.map((product) => {
            const status = expiryStatus(product);
            return <tr key={product.id}>
              <td><div className="product-cell"><span className="product-initial">{product.name.charAt(0)}</span><span><strong>{product.name}</strong><small>{product.sku}</small></span></div></td>
              <td>{product.category}</td><td><strong>{product.stock}</strong> {product.unit}</td>
              <td>{product.expiryDate ? shortDate(product.expiryDate) : 'Not set'}</td>
              <td><StatusPill tone={expiryTones[status]}>{expiryLabels[status]}</StatusPill></td>
              <td><Button size="sm" variant="outline" onClick={() => { setSelected(product); setExpiryDate(product.expiryDate || ''); }}>Set date</Button></td>
            </tr>;
          })}</tbody></table>
          {!filtered.length && <div className="empty-state"><strong>No products match</strong><p>Try another search or status filter.</p></div>}
        </div>
      </Card>
      {selected && <Modal title="Update expiry date" description={selected.name} onClose={() => setSelected(null)} footer={<><Button variant="outline" onClick={() => setSelected(null)}>Cancel</Button><Button icon="check" type="submit" form="expiry-form">Save date</Button></>}>
        <form id="expiry-form" onSubmit={saveExpiry}><TextField label="Expiry date" type="date" value={expiryDate} onChange={(event) => setExpiryDate(event.target.value)} /></form>
      </Modal>}
    </>
  );
}

export function UtangPage({ store, notify }) {
  const [filter, setFilter] = React.useState('unpaid');
  const [adding, setAdding] = React.useState(false);
  const [paymentFor, setPaymentFor] = React.useState(null);
  const [paymentAmount, setPaymentAmount] = React.useState('');
  const utangs = store.utangs || [];
  const outstanding = utangs.filter((item) => item.balance > 0);
  const totalBalance = outstanding.reduce((sum, item) => sum + Number(item.balance || 0), 0);
  const visible = utangs.filter((item) => filter === 'all' || (filter === 'unpaid' ? item.balance > 0 : item.balance <= 0));
  const customers = store.customers || [];

  const addDebt = async (event) => {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    const amount = Number(form.get('amount'));
    if (amount <= 0) return;
    try {
      await store.addUtang({
        customer: String(form.get('customer') || 'Walk-in customer'),
        amount,
        dueDate: String(form.get('dueDate') || ''),
        note: String(form.get('note') || '').trim(),
      });
      notify('Balance added.');
      setAdding(false);
    } catch (error) {
      notify(error.message);
    }
  };

  const payDebt = async (event) => {
    event.preventDefault();
    if (!paymentFor) return;
    const payment = Math.min(Number(paymentAmount) || 0, paymentFor.balance);
    if (payment <= 0) return;
    try {
      await store.recordUtangPayment(paymentFor.id, payment);
      notify('Payment recorded.');
      setPaymentFor(null);
    } catch (error) {
      notify(error.message);
    }
  };

  return (
    <>
      <PageHeader title="Utang" description="Keep track of customer balances and payments." action={<Button icon="plus" onClick={() => setAdding(true)}>Add debt</Button>} />
      <section className="inventory-metrics">
        <div className="inventory-mini"><span className="mini-icon mini-teal"><Icon name="wallet" /></span><span><small>Total unpaid</small><strong>{money(totalBalance)}</strong></span></div>
        <div className="inventory-mini"><span className="mini-icon mini-amber"><Icon name="customers" /></span><span><small>Active balances</small><strong>{outstanding.length}</strong></span></div>
        <div className="inventory-mini"><span className="mini-icon mini-mint"><Icon name="check" /></span><span><small>Paid records</small><strong>{utangs.filter((item) => item.balance <= 0).length}</strong></span></div>
      </section>
      <Card className="catalog-card">
        <div className="catalog-toolbar"><div><h2>Customer balances</h2><p>Record partial payments until a balance is settled.</p></div><span className="result-count">{visible.length} records</span></div>
        <div className="filter-chips" role="group" aria-label="Filter debt records">{[['unpaid', 'Unpaid'], ['paid', 'Paid'], ['all', 'All']].map(([key, label]) => <button key={key} className={'filter-chip ' + (filter === key ? 'filter-chip-active' : '')} onClick={() => setFilter(key)}>{label}</button>)}</div>
        <div className="table-wrap"><table className="data-table"><thead><tr><th>Customer</th><th>Original amount</th><th>Balance</th><th>Due date</th><th>Status</th><th>Action</th></tr></thead><tbody>
          {visible.map((utang) => {
            const overdue = utang.balance > 0 && utang.dueDate && daysUntil(utang.dueDate) < 0;
            return <tr key={utang.id}><td><strong>{utang.customer}</strong>{utang.note && <small className="cell-subtext">{utang.note}</small>}</td><td>{money(utang.amount)}</td><td><strong>{money(utang.balance)}</strong></td><td>{utang.dueDate ? shortDate(utang.dueDate) : '—'}</td><td><StatusPill tone={utang.balance <= 0 ? 'success' : overdue ? 'error' : 'warning'}>{utang.balance <= 0 ? 'Paid' : overdue ? 'Overdue' : 'Unpaid'}</StatusPill></td><td>{utang.balance > 0 ? <Button size="sm" variant="outline" onClick={() => { setPaymentFor(utang); setPaymentAmount(String(utang.balance)); }}>Record payment</Button> : <span className="muted-cell">Complete</span>}</td></tr>;
          })}
        </tbody></table>{!visible.length && <div className="empty-state"><strong>No debt records</strong><p>New balances will appear here.</p></div>}</div>
      </Card>
      {adding && <Modal title="Add debt record" description="Record a customer balance to pay later." onClose={() => setAdding(false)} footer={<><Button variant="outline" onClick={() => setAdding(false)}>Cancel</Button><Button icon="check" type="submit" form="utang-form">Save debt</Button></>}>
        <form id="utang-form" className="form-grid" onSubmit={addDebt}>
          <SelectField label="Customer" name="customer" defaultValue="Walk-in customer"><option>Walk-in customer</option>{customers.filter((customer) => customer.name !== 'Walk-in customer').map((customer) => <option key={customer.id}>{customer.name}</option>)}</SelectField>
          <TextField label="Amount" name="amount" type="number" min="1" step="0.01" required />
          <TextField label="Due date" name="dueDate" type="date" />
          <TextField label="Note (optional)" name="note" placeholder="Short description" />
        </form>
      </Modal>}
      {paymentFor && <Modal title="Record payment" description={paymentFor.customer + ' · balance ' + money(paymentFor.balance)} onClose={() => setPaymentFor(null)} footer={<><Button variant="outline" onClick={() => setPaymentFor(null)}>Cancel</Button><Button icon="check" type="submit" form="payment-form">Save payment</Button></>}>
        <form id="payment-form" onSubmit={payDebt}><TextField label="Payment amount" type="number" min="0.01" max={paymentFor.balance} step="0.01" value={paymentAmount} onChange={(event) => setPaymentAmount(event.target.value)} required /></form>
      </Modal>}
    </>
  );
}

export function NotesPage({ store, notify }) {
  const [query, setQuery] = React.useState('');
  const [filter, setFilter] = React.useState('all');
  const [adding, setAdding] = React.useState(false);
  const notes = store.notes || [];
  const visible = notes
    .filter((note) => (note.title + ' ' + note.content).toLowerCase().includes(query.toLowerCase()))
    .filter((note) => {
      if (filter === 'note') return note.type === 'note';
      if (filter === 'task') return note.type === 'task';
      if (filter === 'pending') return note.type === 'task' && !note.done;
      if (filter === 'done') return note.type === 'task' && note.done;
      return true;
    })
    .sort((a, b) => String(b.createdAt || '').localeCompare(String(a.createdAt || '')));

  const addNote = async (event) => {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    const title = String(form.get('title') || '').trim();
    if (!title) return;
    try {
      await store.addNote({
        type: String(form.get('type') || 'note'),
        title,
        content: String(form.get('content') || '').trim(),
        dueDate: String(form.get('dueDate') || ''),
      });
      notify('Note saved.');
      setAdding(false);
    } catch (error) {
      notify(error.message);
    }
  };

  return (
    <>
      <PageHeader title="Notes & Tasks" description="Keep reminders and store tasks in one clear list." action={<Button icon="plus" onClick={() => setAdding(true)}>Add note or task</Button>} />
      <Card className="catalog-card notes-list-card">
        <div className="catalog-toolbar notes-toolbar"><label className="search-field"><Icon name="search" /><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search notes and tasks" aria-label="Search notes and tasks" /></label><span className="result-count">{visible.length} items</span></div>
        <div className="filter-chips" role="group" aria-label="Filter notes and tasks">{[['all', 'All'], ['note', 'Notes'], ['task', 'Tasks'], ['pending', 'Pending'], ['done', 'Done']].map(([key, label]) => <button key={key} className={'filter-chip ' + (filter === key ? 'filter-chip-active' : '')} onClick={() => setFilter(key)}>{label}</button>)}</div>
        <div className="notes-grid">
          {visible.map((note) => <article className={'card note-card ' + (note.done ? 'note-complete' : '')} key={note.id}>
            <div className="note-card-top"><StatusPill tone={note.type === 'task' ? (note.done ? 'success' : 'gold') : 'neutral'}>{note.type === 'task' ? (note.done ? 'Completed task' : 'Task') : 'Note'}</StatusPill>{note.dueDate && <span className="note-date"><Icon name="calendar" size={15} />{shortDate(note.dueDate)}</span>}</div>
            <h2>{note.title}</h2><p>{note.content || 'No extra details.'}</p>
            <div className="note-actions">{note.type === 'task' && <Button size="sm" variant={note.done ? 'outline' : 'secondary'} icon={note.done ? 'refresh' : 'check'} onClick={async () => { try { await store.toggleNote(note.id); notify(note.done ? 'Task reopened.' : 'Task completed.'); } catch (error) { notify(error.message); } }}>{note.done ? 'Reopen' : 'Mark done'}</Button>}<button className="text-link note-delete" onClick={async () => { if (window.confirm('Delete this note or task?')) { try { await store.deleteNote(note.id); notify('Item deleted.'); } catch (error) { notify(error.message); } } }}>Delete</button></div>
          </article>)}
        </div>
        {!visible.length && <div className="empty-state"><strong>No notes or tasks found</strong><p>Add a reminder or change the current filter.</p><Button icon="plus" onClick={() => setAdding(true)}>Add item</Button></div>}
      </Card>
      {adding && <Modal title="Add note or task" description="Write a short reminder for the store." onClose={() => setAdding(false)} footer={<><Button variant="outline" onClick={() => setAdding(false)}>Cancel</Button><Button icon="check" type="submit" form="note-form">Save</Button></>}>
        <form id="note-form" className="form-grid" onSubmit={addNote}>
          <SelectField label="Type" name="type" defaultValue="note"><option value="note">Note</option><option value="task">Task</option></SelectField>
          <TextField label="Title" name="title" placeholder="What should you remember?" required autoFocus />
          <TextField label="Details" name="content" placeholder="Add useful details" />
          <TextField label="Due date (optional)" name="dueDate" type="date" />
        </form>
      </Modal>}
    </>
  );
}


