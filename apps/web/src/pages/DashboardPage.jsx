import React from 'react';
import { Card, Button, PageHeader, StatusPill } from '../components/UI.jsx';
import Icon from '../components/Icon.jsx';
import { money, shortDate } from '../data/formatters.js';

const dateKey = (date) => [date.getFullYear(), String(date.getMonth() + 1).padStart(2, '0'), String(date.getDate()).padStart(2, '0')].join('-');

function greeting() {
  const hour = new Date().getHours();
  return hour < 12 ? 'Good morning' : hour < 18 ? 'Good afternoon' : 'Good evening';
}

function actionLabel(entry) {
  const action = String(entry.action || '').toLowerCase();
  const target = entry.targetName || (entry.details && (entry.details.productName || entry.details.customerName)) || '';
  const known = { new_sale: 'New sale completed', add_product: 'Added new product', edit_product: 'Edited product', delete_product: 'Deleted product', add_customer: 'Added customer', edit_customer: 'Updated customer', delete_customer: 'Deleted customer' };
  const label = known[action] || action.split('_').filter(Boolean).map((part) => part[0].toUpperCase() + part.slice(1)).join(' ') || 'Store activity';
  return target ? `${label}: ${target}` : label;
}

function Metric({ label, value, note, icon, tone }) {
  return <Card className="metric-card"><div className={`metric-icon metric-${tone}`}><Icon name={icon} size={21} /></div><div className="metric-copy"><span>{label}</span><strong>{value}</strong>{note && <small>{note}</small>}</div></Card>;
}

function OverviewMetric({ label, value, icon, tone, onClick }) {
  return <button className="dashboard-overview-item" onClick={onClick}><span className={`dashboard-overview-icon ${tone}`}><Icon name={icon} size={20} /></span><span className="dashboard-overview-copy"><strong>{value}</strong><small>{label}</small></span><Icon name="arrow" size={15} /></button>;
}

export default function DashboardPage({ store, onNavigate }) {
  const today = dateKey(new Date());
  const ownerName = store.activeEmployee?.name || store.profile?.ownerName || 'Owner';
  const firstName = ownerName.split(' ')[0];
  const completedSales = store.sales.filter((sale) => !['cancelled', 'refunded'].includes(String(sale.status || '').toLowerCase()));
  const todaySales = completedSales.filter((sale) => sale.date === today);
  const revenue = todaySales.reduce((sum, sale) => sum + sale.total, 0);
  const todayProfit = todaySales.reduce((sum, sale) => sum + sale.items.reduce((subtotal, item) => subtotal + (item.price - item.cost) * item.qty - item.discount, 0), 0);
  const productCount = new Set(store.products.map((product) => product.firestoreId || product.id)).size;
  const totalStock = store.products.reduce((sum, product) => sum + product.stock, 0);
  const lowStock = store.products.filter((product) => product.stock <= Math.max(0, Number(product.minStock) || 0)).sort((a, b) => a.stock - b.stock);
  const todayDate = new Date(`${today}T00:00:00`);
  const expiring = store.products.filter((product) => {
    if (!product.expiryDate) return false;
    const days = Math.floor((new Date(`${product.expiryDate}T00:00:00`) - todayDate) / 86_400_000);
    return days <= 30;
  }).sort((a, b) => a.expiryDate.localeCompare(b.expiryDate));
  const activity = store.activityLogs.slice(0, 5);
  const showAlerts = store.settings.notificationsEnabled !== false;
  const latest = activity[0];
  const totalRevenue = completedSales.reduce((sum, sale) => sum + sale.total, 0);
  const initials = ownerName.split(' ').filter(Boolean).map((part) => part[0]).slice(0, 2).join('').toUpperCase();
  const latestText = latest ? actionLabel(latest) : 'No activity yet';

  return <>
    <PageHeader title={`${greeting()}, ${firstName}`} description={store.settings.storeName} action={<Button icon="plus" onClick={() => onNavigate('sales')}>New sale</Button>} />

    <Card className="dashboard-store-summary">
      <div className="dashboard-summary-title"><span className="dashboard-summary-icon"><Icon name="box" size={19} /></span><strong>{store.settings.storeName || 'Store Overview'}</strong></div>
      <p>{productCount} products <span>•</span> {completedSales.length} sales <span>•</span> {money(totalRevenue)} lifetime revenue</p>
      <small>Latest: {latestText}</small>
    </Card>

    <section className="dashboard-today-grid" aria-label="Today’s results">
      <Metric label="Today’s revenue" value={money(revenue)} icon="wallet" tone="teal" />
      <Metric label="Today’s profit" value={money(todayProfit)} icon="reports" tone="mint" />
    </section>

    <section className="dashboard-overview-section">
      <h2>Overview</h2>
      <div className="dashboard-overview-grid">
        <OverviewMetric label="Total products" value={productCount} icon="products" tone="teal" onClick={() => onNavigate('products')} />
        <OverviewMetric label="Total stock" value={`${totalStock.toLocaleString()} units`} icon="inventory" tone="teal" onClick={() => onNavigate('inventory')} />
        <OverviewMetric label="Low stock" value={lowStock.length} icon="inventory" tone={lowStock.length ? 'gold' : 'mint'} onClick={() => onNavigate('inventory')} />
        <OverviewMetric label="Expiry alerts" value={expiring.length} icon="expiry" tone={expiring.length ? 'coral' : 'mint'} onClick={() => onNavigate('expiry')} />
      </div>
    </section>

    <section className="dashboard-quick-section">
      <h2>Quick actions</h2>
      <div className="dashboard-quick-grid">
        {[
          ['sales', 'New sale', 'sales'], ['plus', 'Add product', 'products'], ['inventory', 'Restock', 'inventory'],
          ['utang', 'Utang', 'utang'], ['reports', 'Reports', 'reports'], ['customers', 'Customers', 'customers'],
        ].map(([icon, label, page]) => <button key={page} className="dashboard-quick-action" onClick={() => onNavigate(page)}><span><Icon name={icon} size={21} /></span><strong>{label}</strong></button>)}
      </div>
    </section>

    {showAlerts && expiring.length > 0 && <section className="dashboard-alert-section">
      <div className="dashboard-section-heading"><h2>Expiry alerts</h2><button className="text-link" onClick={() => onNavigate('expiry')}>See all <Icon name="arrow" size={16} /></button></div>
      <Card className="dashboard-alert-list">{expiring.slice(0, 5).map((product) => {
        const days = Math.floor((new Date(`${product.expiryDate}T00:00:00`) - todayDate) / 86_400_000);
        return <button className="dashboard-alert-row" key={product.id} onClick={() => onNavigate('expiry')}><span className="dashboard-alert-dot danger" /><span className="dashboard-alert-copy"><strong>{product.name}</strong><small>{product.variantName || product.category} · {shortDate(product.expiryDate)}</small></span><StatusPill tone={days < 0 ? 'error' : 'warning'}>{days < 0 ? 'Expired' : days === 0 ? 'Today' : `${days} days`}</StatusPill></button>;
      })}</Card>
    </section>}

    {showAlerts && lowStock.length > 0 && <section className="dashboard-alert-section">
      <div className="dashboard-section-heading"><h2>Low inventory</h2><button className="text-link" onClick={() => onNavigate('inventory')}>See all <Icon name="arrow" size={16} /></button></div>
      <Card className="dashboard-alert-list">{lowStock.slice(0, 5).map((product) => <button className="dashboard-alert-row" key={product.id} onClick={() => onNavigate('inventory')}><span className="dashboard-alert-dot warning" /><span className="dashboard-alert-copy"><strong>{product.name}</strong><small>{product.category} · restock level {product.minStock}</small></span><StatusPill tone="warning">{product.stock} left</StatusPill></button>)}</Card>
    </section>}

    <section className="dashboard-activity-section">
      <div className="dashboard-section-heading"><h2>Recent activity</h2><button className="text-link" onClick={() => onNavigate('reports')}>See all <Icon name="arrow" size={16} /></button></div>
      <Card className="dashboard-activity-list">{activity.length ? activity.map((entry) => <div className="dashboard-activity-row" key={entry.id}><span className="dashboard-alert-dot activity" /><span className="dashboard-alert-copy"><strong>{actionLabel(entry)}</strong><small>{entry.timestamp ? shortDate(String(entry.timestamp).slice(0, 10)) : ''} · {entry.employeeName || 'Store owner'}</small></span></div>) : <p className="dashboard-no-activity">No recent activity yet.</p>}</Card>
    </section>
    <span className="sr-only">Signed in as {ownerName} ({initials})</span>
  </>;
}
