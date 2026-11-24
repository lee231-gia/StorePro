import React from 'react';
import { Button, Card, PageHeader, StatusPill } from '../components/UI.jsx';
import Icon from '../components/Icon.jsx';
import { money, shortDate } from '../data/formatters.js';

const periods = [
  { key: 'hour', label: 'Hour' },
  { key: 'today', label: 'Today' },
  { key: 'yesterday', label: 'Yesterday' },
  { key: 'week', label: 'Week' },
  { key: 'month', label: 'Month' },
  { key: 'year', label: 'Year' },
  { key: 'total', label: 'All time' },
  { key: 'custom', label: 'Custom' },
];
const tabs = ['Sales', 'Inventory', 'Profit', 'Activity'];

const dayKey = (date) => [date.getFullYear(), String(date.getMonth() + 1).padStart(2, '0'), String(date.getDate()).padStart(2, '0')].join('-');

function startForPeriod(period, today) {
  const now = new Date();
  if (period === 'total') return '2020-01-01';
  if (period === 'custom') return today;
  if (period === 'hour' || period === 'today') return today;
  if (period === 'yesterday') {
    now.setDate(now.getDate() - 1);
    return dayKey(now);
  }
  if (period === 'week') now.setDate(now.getDate() - 7);
  if (period === 'month') now.setDate(1);
  if (period === 'year') {
    now.setMonth(0);
    now.setDate(1);
  }
  return dayKey(now);
}

function saleProfit(sale, products) {
  return (sale.items || []).reduce((sum, item) => {
    const product = products.find((entry) => entry.id === item.productId || entry.name === item.name);
    const price = item.price ?? product?.price ?? 0;
    const cost = item.cost ?? product?.cost ?? 0;
    return sum + (price - cost) * item.qty - (Number(item.discount) || 0);
  }, 0);
}

function exportSales(sales) {
  const rows = [['Sale ID', 'Date', 'Customer', 'Payment', 'Total'], ...sales.map((sale) => [sale.id, sale.date, sale.customer, sale.payment, sale.total])];
  const csv = rows.map((row) => row.map((cell) => '"' + String(cell).replaceAll('"', '""') + '"').join(',')).join('\n');
  const link = document.createElement('a');
  link.href = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' }));
  link.download = 'storepro-sales-report.csv';
  link.click();
  URL.revokeObjectURL(link.href);
}

export default function ReportsPage({ store }) {
  const [tab, setTab] = React.useState('Sales');
  const [period, setPeriod] = React.useState('today');
  const [customFrom, setCustomFrom] = React.useState(dayKey(new Date()));
  const [customTo, setCustomTo] = React.useState(dayKey(new Date()));
  const [hourStart, setHourStart] = React.useState('');
  React.useEffect(() => {
    if (period !== 'hour') return undefined;
    const updateHourStart = () => setHourStart(new Date(Date.now() - 60 * 60 * 1000).toISOString());
    updateHourStart();
    const interval = window.setInterval(updateHourStart, 60_000);
    return () => window.clearInterval(interval);
  }, [period]);
  const today = dayKey(new Date());
  const cutoff = period === 'custom' ? customFrom : startForPeriod(period, today);
  const through = period === 'custom' ? (customTo || today) : today;
  const sales = store.sales.filter((sale) => sale.status !== 'refunded'
    && (!cutoff || sale.date >= cutoff)
    && sale.date <= through
    && (period !== 'hour' || (sale.timestamp && Date.parse(sale.timestamp) >= Date.parse(hourStart))));
  const activityLogs = (store.activityLogs || []).filter((entry) => (!cutoff || entry.date >= cutoff) && entry.date <= through);
  const inventoryLogs = (store.inventoryLogs || []).filter((entry) => (!cutoff || String(entry.date || '').slice(0, 10) >= cutoff) && String(entry.date || '').slice(0, 10) <= through);
  const salesWithoutLog = sales.filter((sale) => !activityLogs.some((entry) => entry.targetId === sale.id));
  const revenue = sales.reduce((sum, sale) => sum + sale.total, 0);
  const profit = sales.reduce((sum, sale) => sum + saleProfit(sale, store.products), 0);
  const units = sales.reduce((sum, sale) => sum + (sale.items || []).reduce((subtotal, item) => subtotal + item.qty, 0), 0);
  const daily = Array.from({ length: 7 }, (_, index) => {
    const date = new Date();
    date.setDate(date.getDate() - (6 - index));
    const key = dayKey(date);
    return { key, label: new Intl.DateTimeFormat('en', { weekday: 'short' }).format(date), total: sales.filter((sale) => sale.date === key).reduce((sum, sale) => sum + sale.total, 0) };
  });
  const max = Math.max(...daily.map((item) => item.total), 1);
  const productRows = Object.entries(sales.flatMap((sale) => sale.items || []).reduce((map, item) => {
    map[item.name] = (map[item.name] || 0) + item.qty;
    return map;
  }, {})).sort((a, b) => b[1] - a[1]).slice(0, 5);
  const totalUnits = store.products.reduce((sum, product) => sum + product.stock, 0);
  const lowStock = store.products.filter((product) => product.stock <= product.minStock);
  const noStock = store.products.filter((product) => product.stock <= 0);
  const inventoryValue = store.products.reduce((sum, product) => sum + product.stock * product.cost, 0);
  const productProfit = store.products.map((product) => ({
    ...product,
    profitPerUnit: product.price - product.cost,
    margin: product.price > 0 ? ((product.price - product.cost) / product.price) * 100 : 0,
  })).sort((a, b) => b.margin - a.margin);
  const rangeCaption = period === 'total' ? 'Since your first sale' : period === 'hour' ? 'Sales in the last hour' : (cutoff ? shortDate(cutoff) + ' – ' + shortDate(through) : 'Select a date range');

  return (
    <>
      <PageHeader title="Reports" description="Review sales, inventory, profit, and store activity." action={<Button variant="outline" icon="download" onClick={() => exportSales(sales)}>Export CSV</Button>} />
      <div className="report-tabs" role="tablist" aria-label="Report sections">
        {tabs.map((item) => <button key={item} role="tab" aria-selected={tab === item} className={'report-tab ' + (tab === item ? 'report-tab-active' : '')} onClick={() => setTab(item)}>{item}</button>)}
      </div>
      <Card className="report-range-card">
        <div className="card-heading-row"><div><h2>Report period</h2><p>{rangeCaption}</p></div><span className="chart-legend"><Icon name="calendar" size={16} />{periods.find((item) => item.key === period)?.label}</span></div>
        <div className="filter-chips report-periods" role="group" aria-label="Choose report period">
          {periods.map((item) => <button key={item.key} className={'filter-chip ' + (period === item.key ? 'filter-chip-active' : '')} onClick={() => setPeriod(item.key)}>{item.label}</button>)}
        </div>
        {period === 'custom' && <div className="custom-range-fields"><label className="field"><span>From</span><input type="date" value={customFrom} max={customTo || today} onChange={(event) => setCustomFrom(event.target.value)} /></label><label className="field"><span>To</span><input type="date" value={customTo} min={customFrom} max={today} onChange={(event) => setCustomTo(event.target.value)} /></label></div>}
      </Card>

      {tab === 'Sales' && <>
        <section className="metric-grid report-metric-grid">
          <ReportMetric label="Net revenue" value={money(revenue)} detail={sales.length + ' transactions'} icon="wallet" tone="teal" />
          <ReportMetric label="Estimated profit" value={money(profit)} detail="Based on product costs" icon="reports" tone="mint" />
          <ReportMetric label="Items sold" value={String(units)} detail="Across completed sales" icon="products" tone="gold" />
          <ReportMetric label="Average sale" value={money(sales.length ? revenue / sales.length : 0)} detail="Per transaction" icon="receipt" tone="coral" />
        </section>
        <div className="dashboard-grid report-grid">
          <Card className="chart-card"><div className="card-heading-row"><div><h2>Daily sales</h2><p>Revenue by day for the last seven days</p></div><span className="chart-legend"><i />Revenue</span></div>
            <div className="chart-summary"><strong>{money(daily.reduce((sum, item) => sum + item.total, 0))}</strong><span>Last 7 days</span></div>
            <div className="bar-chart report-chart" role="img" aria-label="Daily sales revenue for the last seven days">{daily.map((item) => <div className="bar-column" key={item.key}><div className="bar-track"><div className={'bar-fill ' + (item.key === today ? 'bar-fill-current' : '')} style={{ height: Math.max(7, (item.total / max) * 100) + '%' }} /></div><span className="bar-label">{item.label}</span></div>)}</div>
          </Card>
          <Card className="top-products-card"><div className="card-heading-row"><div><h2>Top products</h2><p>By quantity sold</p></div><span className="subtle-icon"><Icon name="products" /></span></div>{productRows.length ? <div className="top-products-list">{productRows.map(([name, count], index) => <div className="stock-row" key={name}><span className={'stock-rank rank-' + (index + 1)}>{String(index + 1).padStart(2, '0')}</span><span className="stock-name"><strong>{name}</strong><small>Units sold</small></span><span className="stock-total">{count}<small> pcs</small></span></div>)}</div> : <div className="empty-inline">No sales in this period yet.</div>}</Card>
        </div>
        <SalesTable sales={sales} />
      </>}

      {tab === 'Inventory' && <>
        <section className="metric-grid report-metric-grid">
          <ReportMetric label="Inventory value" value={money(inventoryValue)} detail="At recorded cost price" icon="wallet" tone="teal" />
          <ReportMetric label="Units on hand" value={totalUnits.toLocaleString()} detail={store.products.length + ' product types'} icon="inventory" tone="mint" />
          <ReportMetric label="Low stock" value={String(lowStock.length)} detail="At or below threshold" icon="clock" tone="gold" />
          <ReportMetric label="Out of stock" value={String(noStock.length)} detail="Needs replenishment" icon="inventory" tone="coral" />
        </section>
        <Card className="table-card report-table-card"><div className="card-heading-row"><div><h2>Inventory status</h2><p>Current stock levels by product</p></div><StatusPill tone="neutral">{store.products.length} products</StatusPill></div>
          <div className="table-wrap"><table className="data-table"><thead><tr><th>Product</th><th>Category</th><th>Stock</th><th>Minimum</th><th>Cost value</th><th>Status</th></tr></thead><tbody>{store.products.map((product) => <tr key={product.id}><td><strong>{product.name}</strong><small className="cell-subtext">{product.sku}</small></td><td>{product.category}</td><td>{product.stock} {product.unit}</td><td>{product.minStock}</td><td>{money(product.stock * product.cost)}</td><td><StatusPill tone={product.stock <= 0 ? 'error' : product.stock <= product.minStock ? 'warning' : 'success'}>{product.stock <= 0 ? 'Out of stock' : product.stock <= product.minStock ? 'Low stock' : 'Healthy'}</StatusPill></td></tr>)}</tbody></table></div>
        </Card>
      </>}

      {tab === 'Profit' && <>
        <section className="metric-grid report-metric-grid">
          <ReportMetric label="Period revenue" value={money(revenue)} detail={sales.length + ' transactions'} icon="wallet" tone="teal" />
          <ReportMetric label="Period profit" value={money(profit)} detail="Revenue less product cost" icon="reports" tone="mint" />
          <ReportMetric label="Profit margin" value={(revenue ? (profit / revenue) * 100 : 0).toFixed(1) + '%'} detail="Profit as share of revenue" icon="categories" tone="gold" />
          <ReportMetric label="Average profit / sale" value={money(sales.length ? profit / sales.length : 0)} detail="For selected period" icon="receipt" tone="coral" />
        </section>
        <Card className="table-card report-table-card"><div className="card-heading-row"><div><h2>Profit by product</h2><p>Estimated profit and margin per unit</p></div><StatusPill tone="neutral">Selling price − cost</StatusPill></div>
          <div className="table-wrap"><table className="data-table profit-table"><thead><tr><th>Product</th><th>Cost price</th><th>Selling price</th><th>Profit per unit</th><th>Margin</th></tr></thead><tbody>{productProfit.map((product) => <tr key={product.id}><td><strong>{product.name}</strong><small className="cell-subtext">{product.category}</small></td><td>{money(product.cost)}</td><td>{money(product.price)}</td><td><strong>{money(product.profitPerUnit)}</strong></td><td><StatusPill tone={product.margin >= 30 ? 'success' : product.margin >= 15 ? 'warning' : 'error'}>{product.margin.toFixed(1)}%</StatusPill></td></tr>)}</tbody></table></div>
        </Card>
      </>}

      {tab === 'Activity' && <Card className="table-card report-table-card"><div className="card-heading-row"><div><h2>Store activity</h2><p>Actions, stock movements, and sales in the selected period</p></div><StatusPill tone="neutral">{activityLogs.length + inventoryLogs.length + salesWithoutLog.length} records</StatusPill></div>
        {activityLogs.length || inventoryLogs.length || sales.length ? <div className="activity-list">{activityLogs.slice(0, 100).map((entry) => {
          const action = entry.action.split('_').filter(Boolean).map((word) => word[0].toUpperCase() + word.slice(1)).join(' ') || 'Store update';
          const target = entry.targetName || (entry.targetType ? entry.targetType : 'Store');
          return <div className="activity-row" key={entry.id}><span className="activity-mark"><Icon name="receipt" size={18} /></span><span className="activity-copy"><strong>{action}: {target}</strong><small>{shortDate(entry.date)} · {entry.employeeName}</small></span><span>{entry.targetType}</span></div>;
        })}{inventoryLogs.slice(0, 100).map((entry) => <div className="activity-row" key={'stock-' + entry.id}><span className="activity-mark"><Icon name="inventory" size={18} /></span><span className="activity-copy"><strong>{entry.qty >= 0 ? 'Stock added' : 'Stock removed'}: {entry.productName}</strong><small>{shortDate(String(entry.date || '').slice(0, 10))} · {entry.reason || entry.type} · {entry.employeeName || 'Store owner'}</small></span><strong className={entry.qty >= 0 ? 'inventory-log-add' : 'inventory-log-remove'}>{entry.qty > 0 ? '+' : ''}{entry.qty} units</strong></div>)}{salesWithoutLog.map((sale) => <div className="activity-row" key={'sale-' + sale.id}><span className="activity-mark"><Icon name="receipt" size={18} /></span><span className="activity-copy"><strong>Sale recorded</strong><small>{shortDate(sale.date)} · {sale.customer} · {sale.payment}</small></span><strong>{money(sale.total)}</strong></div>)}</div> : <div className="empty-state"><strong>No activity for this period</strong><p>Activity will appear after store records are updated.</p></div>}
      </Card>}
    </>
  );
}

function SalesTable({ sales }) {
  return <Card className="table-card report-table-card"><div className="card-heading-row"><div><h2>Sales activity</h2><p>{sales.length} transactions in the selected period</p></div><StatusPill tone="neutral">Selected period</StatusPill></div>
    <div className="table-wrap"><table className="data-table"><thead><tr><th>Sale</th><th>Date</th><th>Customer</th><th>Items</th><th>Payment</th><th>Amount</th></tr></thead><tbody>{sales.slice(0, 12).map((sale) => <tr key={sale.id}><td><strong>{sale.id}</strong></td><td>{shortDate(sale.date)}</td><td>{sale.customer}</td><td>{(sale.items || []).reduce((sum, item) => sum + item.qty, 0)}</td><td><StatusPill tone={sale.payment.toLowerCase() === 'cash' ? 'success' : 'gold'}>{sale.payment}</StatusPill></td><td><strong>{money(sale.total)}</strong></td></tr>)}</tbody></table></div>
    {!sales.length && <div className="empty-state"><strong>No sales for this period</strong><p>Transactions will appear here once recorded.</p></div>}
  </Card>;
}

function ReportMetric({ label, value, detail, icon, tone }) {
  return <Card className="metric-card"><div className={'metric-icon metric-' + tone}><Icon name={icon} size={21} /></div><div className="metric-copy"><span>{label}</span><strong>{value}</strong><small>{detail}</small></div></Card>;
}


