import React from 'react';
import { Button, Card, Modal, PageHeader, SegmentedTabs, StatusPill } from '../components/UI.jsx';
import { ProductBrowserResults, ProductBrowserToolbar, ProductImage, sortProductRows } from '../components/ProductBrowser.jsx';
import Icon from '../components/Icon.jsx';
import { money } from '../data/formatters.js';

export default function SalesPage({ store, notify }) {
  const [section, setSection] = React.useState('new');
  const [historyRange, setHistoryRange] = React.useState('all');
  const [customFrom, setCustomFrom] = React.useState(localDateKey(new Date()));
  const [customTo, setCustomTo] = React.useState(localDateKey(new Date()));
  const [receiptSale, setReceiptSale] = React.useState(null);
  const [workingSaleId, setWorkingSaleId] = React.useState('');
  const [query, setQuery] = React.useState('');
  const [category, setCategory] = React.useState('All');
  const [viewMode, setViewMode] = React.useState('list');
  const [sortBy, setSortBy] = React.useState('name-asc');
  const [grouped, setGrouped] = React.useState(false);
  const [productsCollapsed, setProductsCollapsed] = React.useState(false);
  const [payment, setPayment] = React.useState('Cash');
  const [customerName, setCustomerName] = React.useState('');
  const [customerPhone, setCustomerPhone] = React.useState('');
  const [customerAddress, setCustomerAddress] = React.useState('');
  const [amountReceived, setAmountReceived] = React.useState('');
  const [cart, setCart] = React.useState([]);
  const [saving, setSaving] = React.useState(false);
  const filtered = sortProductRows(store.products.filter((product) => product.stock > 0 && (product.name + ' ' + product.variantName + ' ' + product.sku).toLowerCase().includes(query.toLowerCase()) && (category === 'All' || product.category === category)), sortBy);
  const subtotal = cart.reduce((sum, line) => sum + line.product.price * line.qty, 0);
  const totalDiscount = cart.reduce((sum, line) => sum + (Number(line.discount) || 0), 0);
  const total = Math.max(0, subtotal - totalDiscount);
  const qty = cart.reduce((sum, line) => sum + line.qty, 0);
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

  const addToCart = (product) => setCart((current) => {
    const found = current.find((line) => line.product.id === product.id);
    if (found) return current.map((line) => line.product.id === product.id ? { ...line, qty: Math.min(line.qty + 1, product.stock) } : line);
    return [...current, { product, qty: 1, discount: 0 }];
  });
  const changeQty = (id, delta) => setCart((current) => current.map((line) => {
    if (line.product.id !== id) return line;
    const qty = Math.min(line.product.stock, line.qty + delta);
    return { ...line, qty, discount: Math.min(line.discount || 0, line.product.price * qty) };
  }).filter((line) => line.qty > 0));
  const changeDiscount = (id, value) => setCart((current) => current.map((line) => line.product.id === id ? { ...line, discount: Math.min(line.product.price * line.qty, Math.max(0, Number(value) || 0)) } : line));
  const checkout = async () => {
    if (!cart.length || saving) return;
    const received = payment === 'Utang' ? 0 : amountReceived === '' ? total : Number(amountReceived) || 0;
    if ((payment === 'Utang' || (payment === 'Multi' && received < total)) && !customerName.trim()) return notify('Enter the customer name for an Utang or unpaid balance.');
    if (payment !== 'Utang' && payment !== 'Multi' && received < total) return notify('Cash payment must cover the sale total. Choose Multi to record a balance.');
    setSaving(true);
    try {
      const sale = await store.completeSale(cart, payment, { customerName, customerPhone, customerAddress, amountPaid: received });
      setCart([]);
      setCustomerName('');
      setCustomerPhone('');
      setCustomerAddress('');
      setAmountReceived('');
      notify(sale.offlinePending ? `Sale saved offline · ${money(sale.total)} · will sync when connected.` : 'Sale completed · ' + money(sale.total));
    } catch (error) {
      notify(error.message);
    } finally {
      setSaving(false);
    }
  };
  const toggleProductPanel = () => {
    const shouldFocusSale = !productsCollapsed;
    setProductsCollapsed(shouldFocusSale);
    if (shouldFocusSale) window.setTimeout(() => document.getElementById('pos-checkout-card')?.scrollIntoView({ behavior: 'smooth', block: 'start' }), 40);
  };

  const refund = async (sale) => {
    if (!window.confirm(`Refund sale ${sale.id}? The items will be returned to inventory.`)) return;
    setWorkingSaleId(sale.id);
    try { await store.refundSale(sale.id, 'Customer refund'); notify(`Sale ${sale.id} refunded and stock restored.`); }
    catch (error) { notify(error.message); }
    finally { setWorkingSaleId(''); }
  };

  const remove = async (sale) => {
    if (!window.confirm(`Delete sale ${sale.id}? This also returns the items to inventory if it has not been refunded.`)) return;
    setWorkingSaleId(sale.id);
    try { await store.deleteSale(sale.id); notify(`Sale ${sale.id} deleted.`); }
    catch (error) { notify(error.message); }
    finally { setWorkingSaleId(''); }
  };

  return (
    <>
      <PageHeader title="Sales" description="Create a sale or review previous transactions." action={<StatusPill tone="success">Register open</StatusPill>} />
      <SegmentedTabs label="Sales sections" value={section} onChange={setSection} tabs={[{ key: 'new', label: 'New sale' }, { key: 'history', label: 'History' }]} />
      {section === 'history' && <section>
        <div className="filter-chips" aria-label="Filter sales history">{[['all', 'All'], ['today', 'Today'], ['week', 'Week'], ['month', 'Month'], ['year', 'Year'], ['custom', 'Custom']].map(([key, label]) => <button type="button" key={key} className={`filter-chip${historyRange === key ? ' filter-chip-active' : ''}`} aria-pressed={historyRange === key} onClick={() => setHistoryRange(key)}>{label}</button>)}</div>
        {historyRange === 'custom' && <div className="sales-custom-range"><label className="field"><span>From</span><input type="date" value={customFrom} onChange={(event) => setCustomFrom(event.target.value)} /></label><label className="field"><span>To</span><input type="date" value={customTo} onChange={(event) => setCustomTo(event.target.value)} /></label></div>}
        {historySales.length ? <div className="sales-history-list">{historySales.map((sale) => <Card className="sales-history-card" key={sale.id}>
          <div className="sales-history-head"><div><h2 className="sales-history-title">{sale.customer || 'Walk-in customer'}</h2><p className="inventory-log-meta">{formatSalesDate(sale.date)} · {sale.payment || 'Cash'} · {sale.items.length} {sale.items.length === 1 ? 'item' : 'items'}</p></div><div className="sales-history-total"><strong>{money(sale.total)}</strong><StatusPill tone={sale.offlinePending || sale.status === 'refunded' || sale.status === 'partial' ? 'warning' : 'success'}>{sale.offlinePending ? 'Pending sync' : sale.status || 'completed'}</StatusPill></div></div>
          <ul className="sales-history-items">{sale.items.map((item, index) => <li key={`${sale.id}-${item.productId}-${item.variantId}-${index}`}><span>{item.name}{item.variantName ? ` · ${item.variantName}` : ''} × {item.qty}</span><strong>{money(item.total)}</strong></li>)}</ul>
          <div className="sales-history-actions"><Button size="sm" variant="outline" onClick={() => setReceiptSale(sale)}>Receipt</Button>{sale.status !== 'refunded' && <Button size="sm" variant="outline" disabled={sale.offlinePending || workingSaleId === sale.id} onClick={() => refund(sale)}>{workingSaleId === sale.id ? 'Saving…' : 'Refund'}</Button>}<Button size="sm" variant="ghost" disabled={sale.offlinePending || workingSaleId === sale.id} onClick={() => remove(sale)}>Delete</Button></div>
        </Card>)}</div> : <div className="empty-state"><strong>No sales in this period</strong><p>Completed sales will appear here.</p></div>}
      </section>}
      {section === 'new' && <div className={`pos-layout${productsCollapsed ? ' pos-layout-products-collapsed' : ''}`}>
        <Card className={`pos-products${productsCollapsed ? ' pos-products-collapsed' : ''}`}>
          <div className="pos-products-heading"><div><h2>Products</h2><p>{filtered.length} available</p></div><Button variant="outline" icon={productsCollapsed ? 'down' : 'close'} aria-expanded={!productsCollapsed} onClick={toggleProductPanel}>{productsCollapsed ? 'Show products' : 'Hide products'}</Button></div>
          {!productsCollapsed && <>
            <div className="catalog-toolbar"><label className="search-field"><Icon name="search" size={19} /><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Find a product" aria-label="Find a product" /></label></div>
            <div className="filter-chips">{['All', ...store.categories].map((item) => <button type="button" key={item} className={'filter-chip ' + (category === item ? 'filter-chip-active' : '')} onClick={() => setCategory(item)}>{item}</button>)}</div>
            <ProductBrowserToolbar viewMode={viewMode} onViewModeChange={setViewMode} sortBy={sortBy} onSortChange={setSortBy} grouped={grouped} onGroupedChange={setGrouped} />
            <ProductBrowserResults products={filtered} viewMode={viewMode} grouped={grouped} emptyMessage="No available products match your search." renderProduct={(product, mode) => <button type="button" className={`pos-product pos-product-${mode}`} key={product.id} aria-label={`Add ${product.name}${product.variantName ? `, ${product.variantName}` : ''} to the sale`} onClick={() => addToCart(product)}>
              <ProductImage product={product} className={`product-browser-image product-browser-image-${mode}`} /><strong>{product.name}{mode !== 'grid' && product.variantName && product.variantName.toLowerCase() !== product.name.toLowerCase() ? ` · ${product.variantName}` : ''}</strong>{mode === 'grid' && product.variantName && product.variantName.toLowerCase() !== product.name.toLowerCase() && <small>{product.variantName}</small>}
              {mode === 'details' && <span className="pos-product-detail">{product.category} · {product.sku || 'No SKU'} · {product.stock} {product.unit} left</span>}
              <span className="pos-product-bottom"><span>{money(product.price)}</span><small>{product.stock} {product.unit} left</small></span>
              <span className="pos-product-add">Add to sale</span>
            </button>} />
          </>}
        </Card>
        <Card id="pos-checkout-card" className="checkout-card">
          <div className="checkout-heading"><div><h2>Current sale</h2><p>{qty} {qty === 1 ? 'item' : 'items'}</p></div><button type="button" className="text-link" onClick={() => setCart([])} disabled={!cart.length}>Clear</button></div>
          <div className="cart-lines">{cart.map((line) => <div className="cart-line" key={line.product.id}><div className="cart-line-copy"><strong>{saleLineLabel(line.product)}</strong><small>{money(line.product.price)} each</small></div><div className="quantity-control"><button aria-label={'Remove one ' + line.product.name} onClick={() => changeQty(line.product.id, -1)}>−</button><span>{line.qty}</span><button aria-label={'Add one ' + line.product.name} onClick={() => changeQty(line.product.id, 1)}>+</button></div><strong className="cart-line-total">{money(line.product.price * line.qty - line.discount)}</strong><label className="cart-discount"><span>Item discount</span><input aria-label={`Discount for ${line.product.name}`} type="number" min="0" max={line.product.price * line.qty} step="0.01" value={line.discount || ''} onChange={(event) => changeDiscount(line.product.id, event.target.value)} /></label></div>)}{!cart.length && <div className="cart-empty"><span className="empty-illustration"><Icon name="sales" size={24} /></span><strong>Your sale is empty</strong><p>Choose products to get started.</p></div>}</div>
          <div className="checkout-bottom"><label className="field payment-field"><span>Customer name {payment === 'Utang' || payment === 'Multi' ? '(required for balance)' : '(optional)'}</span><input value={customerName} onChange={(event) => setCustomerName(event.target.value)} placeholder="Walk-in customer" /></label><label className="field payment-field"><span>Payment method</span><select value={payment} onChange={(event) => setPayment(event.target.value)}><option>Cash</option><option>Utang</option><option>Multi</option></select></label>{(payment === 'Utang' || payment === 'Multi') && <><label className="field payment-field"><span>Phone (optional)</span><input type="tel" value={customerPhone} onChange={(event) => setCustomerPhone(event.target.value)} placeholder="Customer phone" /></label><label className="field payment-field"><span>Address (optional)</span><input value={customerAddress} onChange={(event) => setCustomerAddress(event.target.value)} placeholder="Customer address" /></label></>}{payment !== 'Utang' && <label className="field payment-field"><span>Amount received</span><input type="number" min="0" step="0.01" value={amountReceived} onChange={(event) => setAmountReceived(event.target.value)} placeholder={money(total)} /></label>}{totalDiscount > 0 && <div className="sale-discount-summary"><span>Subtotal</span><strong>{money(subtotal)}</strong><span>Discount</span><strong>− {money(totalDiscount)}</strong></div>}<div className="total-row"><span>Total</span><strong>{money(total)}</strong></div><Button className="checkout-button" icon="check" disabled={!cart.length || saving} onClick={checkout}>{saving ? 'Saving sale…' : 'Complete sale'}</Button><p className="checkout-hint">Stock and reports update across your signed-in devices.</p></div>
        </Card>
      </div>}
      {receiptSale && <Modal title="Sales receipt" description={`Transaction ${receiptSale.id} · ${formatSalesDate(receiptSale.date)}`} onClose={() => setReceiptSale(null)} footer={<Button variant="outline" onClick={() => setReceiptSale(null)}>Close</Button>}>
        <div className="receipt-details"><p><strong>Customer</strong><span>{receiptSale.customer || 'Walk-in customer'}</span></p><p><strong>Payment</strong><span>{receiptSale.payment}</span></p>{receiptSale.items.map((item, index) => <p key={`${item.productId}-${item.variantId}-${index}`}><strong>{item.name}{item.variantName ? ` · ${item.variantName}` : ''} × {item.qty}{item.discount > 0 ? ` · discount ${money(item.discount)}` : ''}</strong><span>{money(item.total)}</span></p>)}{receiptSale.totalDiscount > 0 && <p><strong>Subtotal</strong><span>{money(receiptSale.subtotal)}</span></p>}{receiptSale.totalDiscount > 0 && <p><strong>Discount</strong><span>− {money(receiptSale.totalDiscount)}</span></p>}<p className="receipt-total"><strong>Total</strong><span>{money(receiptSale.total)}</span></p>{receiptSale.amountPaid < receiptSale.total && <p><strong>Balance</strong><span>{money(receiptSale.total - receiptSale.amountPaid)}</span></p>}{receiptSale.change > 0 && <p><strong>Change</strong><span>{money(receiptSale.change)}</span></p>}</div>
      </Modal>}
    </>
  );
}

function localDateKey(date) {
  return [date.getFullYear(), String(date.getMonth() + 1).padStart(2, '0'), String(date.getDate()).padStart(2, '0')].join('-');
}

function saleLineLabel(product) {
  const name = String(product.name || '').trim();
  const variantName = String(product.variantName || '').trim();
  return variantName && variantName.toLocaleLowerCase() !== name.toLocaleLowerCase()
    ? `${name} · ${variantName}`
    : name;
}

function formatSalesDate(value) {
  if (!value) return '—';
  const date = new Date(`${value}T00:00:00`);
  return Number.isNaN(date.getTime()) ? value : new Intl.DateTimeFormat('en-PH', { dateStyle: 'medium' }).format(date);
}

