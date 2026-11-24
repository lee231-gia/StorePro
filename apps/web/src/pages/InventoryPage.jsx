import React from 'react';
import { Button, Card, Modal, PageHeader, SegmentedTabs, SelectField, StatusPill, TextField } from '../components/UI.jsx';
import { ProductBrowserResults, ProductBrowserToolbar, ProductImage, sortProductRows } from '../components/ProductBrowser.jsx';
import Icon from '../components/Icon.jsx';

export default function InventoryPage({ store, notify }) {
  const [section, setSection] = React.useState('overview');
  const [query, setQuery] = React.useState('');
  const [viewMode, setViewMode] = React.useState('list');
  const [sortBy, setSortBy] = React.useState('stock-asc');
  const [grouped, setGrouped] = React.useState(true);
  const [restockItem, setRestockItem] = React.useState(null);
  const [adjustmentMode, setAdjustmentMode] = React.useState('add');
  const [amount, setAmount] = React.useState('10');
  const [costPrice, setCostPrice] = React.useState('');
  const [expiryDate, setExpiryDate] = React.useState('');
  const [removeReason, setRemoveReason] = React.useState('adjustment');
  const products = sortProductRows(store.products.filter((product) => `${product.name} ${product.variantName} ${product.sku} ${product.category}`.toLowerCase().includes(query.toLowerCase())), sortBy);
  const lowStock = store.products.filter((product) => product.stock <= product.minStock).length;
  const replenishProducts = sortProductRows(store.products, sortBy);
  const totalUnits = store.products.reduce((sum, product) => sum + product.stock, 0);
  const confirmRestock = async (event) => {
    event.preventDefault();
    const count = Math.max(1, Number(amount) || 1);
    try {
      if (adjustmentMode === 'add') {
        await store.restock(restockItem.id, count, { costPrice, expiryDate });
        notify(`${count} ${restockItem.unit} added to ${restockItem.name}.`);
      } else {
        await store.removeStock(restockItem.id, count, removeReason);
        notify(`${count} ${restockItem.unit} removed from ${restockItem.name}.`);
      }
      setRestockItem(null);
    } catch (error) {
      notify(error.message);
    }
  };
  const openAdjustment = (product, mode) => {
    setRestockItem(product);
    setAdjustmentMode(mode);
    setAmount(mode === 'add' ? '10' : '1');
    setCostPrice('');
    setExpiryDate('');
    setRemoveReason('adjustment');
  };

  return (
    <>
      <PageHeader title="Inventory" description="Track stock on hand and restock items that need attention." action={<Button variant="outline" icon="products" onClick={() => notify(`${totalUnits} units across ${store.products.length} products.`)}>Stock summary</Button>} />
      <SegmentedTabs label="Inventory sections" value={section} onChange={setSection} tabs={[{ key: 'overview', label: 'Overview' }, { key: 'replenish', label: 'Replenish' }, { key: 'logs', label: 'Logs' }]} />
      {section === 'overview' && <>
      <section className="inventory-metrics"><div className="inventory-mini"><span className="mini-icon mini-teal"><Icon name="package" /></span><span><small>Total units</small><strong>{totalUnits.toLocaleString()}</strong></span></div><div className="inventory-mini"><span className="mini-icon mini-amber"><Icon name="inventory" /></span><span><small>Low stock items</small><strong>{lowStock}</strong></span></div><div className="inventory-mini"><span className="mini-icon mini-mint"><Icon name="categories" /></span><span><small>Product types</small><strong>{store.products.length}</strong></span></div></section>
      <Card className="catalog-card"><div className="inventory-toolbar"><div><h2>Stock levels</h2><p>Low stock items are highlighted for quick action.</p></div><label className="search-field inventory-search"><Icon name="search" size={19} /><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search inventory" aria-label="Search inventory" /></label></div>
        {lowStock > 0 && <div className="inventory-alert"><span className="alert-icon"><Icon name="inventory" size={18} /></span><span><strong>{lowStock} products need attention</strong><small>Restock them to keep your shelves ready.</small></span></div>}
        <ProductBrowserToolbar viewMode={viewMode} onViewModeChange={setViewMode} sortBy={sortBy} onSortChange={setSortBy} grouped={grouped} onGroupedChange={setGrouped} />
        <ProductBrowserResults products={products} viewMode={viewMode} grouped={grouped} emptyMessage="No inventory items match your search." renderProduct={(product, mode) => <article className={`browser-product browser-product-${mode}`} key={product.id}>
          <div className="browser-product-main"><ProductImage product={product} className={`product-browser-image product-browser-image-${mode}`} /><span className="browser-product-copy"><strong>{product.name}</strong><small>{product.variantName && product.variantName.toLowerCase() !== product.name.toLowerCase() ? product.variantName : product.sku}</small></span></div>
          <span className="browser-product-category">{product.category}</span><span className="browser-product-stock"><strong>{product.stock}</strong> {product.unit}</span><span className="browser-product-sku">Alert at {product.minStock} {product.unit}</span>
          <span className="browser-product-status">{product.stock <= product.minStock ? <StatusPill tone="warning">Restock soon</StatusPill> : <StatusPill tone="success">Healthy</StatusPill>}</span>
          {mode === 'details' && <span className="browser-product-extra">SKU {product.sku || 'not set'}{product.expiryDate ? ` · Expires ${product.expiryDate}` : ''}</span>}
          <span className="browser-product-actions"><Button size="sm" variant="outline" onClick={() => openAdjustment(product, 'add')}>Restock</Button></span>
        </article>} />
      </Card>
      </>}
      {section === 'replenish' && <Card className="catalog-card"><div className="inventory-toolbar"><div><h2>Replenish or adjust stock</h2><p>Sort by stock level or another field, then adjust as needed.</p></div></div>
        <ProductBrowserToolbar viewMode={viewMode} onViewModeChange={setViewMode} sortBy={sortBy} onSortChange={setSortBy} grouped={grouped} onGroupedChange={setGrouped} />
        <ProductBrowserResults products={replenishProducts} viewMode={viewMode} grouped={grouped} emptyMessage="No products yet. Add products before adjusting stock." renderProduct={(product, mode) => <article className={`browser-product browser-product-${mode}`} key={product.id}>
          <div className="browser-product-main"><ProductImage product={product} className={`product-browser-image product-browser-image-${mode}`} /><span className="browser-product-copy"><strong>{product.name}</strong><small>{product.variantName && product.variantName.toLowerCase() !== product.name.toLowerCase() ? product.variantName : product.category}</small></span></div>
          <span className="browser-product-stock"><strong>{product.stock}</strong> {product.unit}</span><span className="browser-product-sku">Alert at {product.minStock} {product.unit}</span>
          {mode === 'details' && <span className="browser-product-extra">{product.category} · SKU {product.sku || 'not set'}{product.expiryDate ? ` · Expires ${product.expiryDate}` : ''}</span>}
          <span className="browser-product-actions"><Button size="sm" variant="outline" onClick={() => openAdjustment(product, 'add')}>Add</Button><Button size="sm" variant="ghost" disabled={!product.stock} onClick={() => openAdjustment(product, 'remove')}>Remove</Button></span>
        </article>} />
      </Card>}
      {section === 'logs' && <Card className="catalog-card"><div className="inventory-toolbar"><div><h2>Stock movement</h2><p>Restocks and sales recorded across your signed-in devices.</p></div></div>
        {store.inventoryLogs?.length ? <div className="table-wrap"><table className="data-table"><thead><tr><th>Date</th><th>Product</th><th>Movement</th><th>Reason</th><th>Recorded by</th></tr></thead><tbody>{store.inventoryLogs.map((log) => <tr key={log.id}><td>{formatLogDate(log.date)}</td><td><strong>{log.productName}</strong>{log.variantName && <small className="cell-subtext">{log.variantName}</small>}</td><td className={`inventory-log-quantity ${log.qty >= 0 ? 'inventory-log-add' : 'inventory-log-remove'}`}>{log.qty > 0 ? '+' : ''}{log.qty}</td><td>{log.reason || log.type}</td><td>{log.employeeName || 'Store owner'}</td></tr>)}</tbody></table></div> : <div className="empty-state"><strong>No stock activity yet</strong><p>Restocks and completed sales will appear here.</p></div>}
      </Card>}
      {restockItem && <Modal title={`${adjustmentMode === 'add' ? 'Add' : 'Remove'} stock · ${restockItem.name}`} description={`Current stock: ${restockItem.stock} ${restockItem.unit}.`} onClose={() => setRestockItem(null)} footer={<><Button variant="outline" onClick={() => setRestockItem(null)}>Cancel</Button><Button icon="check" type="submit" form="restock-form">{adjustmentMode === 'add' ? 'Add stock' : 'Remove stock'}</Button></>}><form id="restock-form" className="form-grid" onSubmit={confirmRestock}><TextField label={`Quantity (${restockItem.unit})`} type="number" min="1" max={adjustmentMode === 'remove' ? restockItem.stock : undefined} value={amount} onChange={(event) => setAmount(event.target.value)} required autoFocus />{adjustmentMode === 'add' ? <><TextField label="Cost per unit (optional)" type="number" min="0" step="0.01" value={costPrice} onChange={(event) => setCostPrice(event.target.value)} placeholder={String(restockItem.cost)} /><TextField label="Expiry date (optional)" type="date" value={expiryDate} onChange={(event) => setExpiryDate(event.target.value)} /></> : <SelectField label="Reason for removal" value={removeReason} onChange={(event) => setRemoveReason(event.target.value)}><option value="adjustment">Adjustment</option><option value="personal_use">Personal use</option><option value="waste_damage">Waste or damage</option><option value="stock_loss">Stock loss or missing</option></SelectField>}</form></Modal>}
    </>
  );
}

function formatLogDate(value) {
  if (!value) return '—';
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? value : new Intl.DateTimeFormat('en-PH', { dateStyle: 'medium' }).format(date);
}
