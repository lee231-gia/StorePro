import React from 'react';
import { Button, Card, PageHeader, StatusPill } from '../components/UI.jsx';
import ProductWizard from '../components/ProductWizard.jsx';
import { ProductBrowserResults, ProductBrowserToolbar, ProductImage, sortProductRows } from '../components/ProductBrowser.jsx';
import Icon from '../components/Icon.jsx';
import { money } from '../data/formatters.js';

export default function ProductsPage({ store, notify }) {
  const [query, setQuery] = React.useState('');
  const [category, setCategory] = React.useState('All');
  const [viewMode, setViewMode] = React.useState('list');
  const [sortBy, setSortBy] = React.useState('recent');
  const [grouped, setGrouped] = React.useState(true);
  const [wizardProduct, setWizardProduct] = React.useState(null);
  const [showWizard, setShowWizard] = React.useState(false);
  const categories = ['All', ...store.categories];
  const productCount = new Set(store.products.map((item) => item.firestoreId || item.id)).size;
  const products = sortProductRows(store.products.filter((product) => {
    const matchesQuery = (product.name + ' ' + product.variantName + ' ' + product.sku + ' ' + product.category).toLowerCase().includes(query.toLowerCase());
    return matchesQuery && (category === 'All' || product.category === category);
  }), sortBy);

  const openAdd = () => {
    setWizardProduct(null);
    setShowWizard(true);
  };
  const openEdit = (product) => {
    setWizardProduct(product);
    setShowWizard(true);
  };
  const submit = async (product) => {
    try {
      if (wizardProduct) {
        await store.updateProduct(wizardProduct.id, product);
        notify('Product updated.');
      } else {
        await store.addProduct(product);
        notify('Product added.');
      }
      setShowWizard(false);
      setWizardProduct(null);
    } catch (error) {
      notify(error.message);
      throw error;
    }
  };
  const removeProduct = async (product) => {
    if (!window.confirm(`Delete ${product.name}${product.variantName ? ` · ${product.variantName}` : ''}? This removes it from the product catalog.`)) return;
    try {
      await store.deleteProduct(product.id);
      notify('Product deleted.');
    } catch (error) {
      notify(error.message);
    }
  };

  return (
    <>
      <PageHeader title="Products" description="Manage your catalog, prices, and stock levels." action={<Button icon="plus" onClick={openAdd}>Add product</Button>} />
      <div className="product-summary-strip"><span><strong>{productCount}</strong> products</span><span className="summary-divider" /><span><strong>{store.categories.length}</strong> categories</span><span className="summary-divider" /><span><strong>{store.products.filter((item) => item.stock <= item.minStock).length}</strong> low stock variants</span></div>
      <Card className="catalog-card">
        <div className="catalog-toolbar"><label className="search-field"><Icon name="search" size={19} /><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search products or SKU" aria-label="Search products or SKU" /></label><span className="result-count">{products.length} variants</span></div>
        <div className="filter-chips" aria-label="Filter by category">{categories.map((item) => <button key={item} className={'filter-chip ' + (category === item ? 'filter-chip-active' : '')} onClick={() => setCategory(item)}>{item}</button>)}</div>
        <ProductBrowserToolbar viewMode={viewMode} onViewModeChange={setViewMode} sortBy={sortBy} onSortChange={setSortBy} grouped={grouped} onGroupedChange={setGrouped} />
        <ProductBrowserResults products={products} viewMode={viewMode} grouped={grouped} emptyMessage="No products match these filters." renderProduct={(product, mode) => <article className={`browser-product browser-product-${mode}`} key={product.id}>
          <div className="browser-product-main"><ProductImage product={product} className={`product-browser-image product-browser-image-${mode}`} /><span className="browser-product-copy"><strong>{product.name}</strong><small>{product.variantName && product.variantName.toLowerCase() !== product.name.toLowerCase() ? product.variantName : product.unit}</small></span></div>
          <span className="browser-product-sku">{product.sku || 'No SKU'}</span>
          <span className="browser-product-category">{product.category}</span>
          <span className="browser-product-stock"><strong>{product.stock}</strong> {product.unit}</span>
          <span className="browser-product-price"><strong>{money(product.price)}</strong><small>Cost {money(product.cost)}</small></span>
          <span className="browser-product-status">{product.stock <= product.minStock ? <StatusPill tone="warning">Low stock</StatusPill> : <StatusPill tone="success">In stock</StatusPill>}</span>
          {mode === 'details' && <span className="browser-product-extra">Low stock at {product.minStock} {product.unit}{product.expiryDate ? ` · Expires ${product.expiryDate}` : ''}</span>}
          <span className="browser-product-actions"><Button size="sm" variant="outline" onClick={() => openEdit(product)}>Edit</Button><Button size="sm" variant="ghost" onClick={() => removeProduct(product)}>Delete</Button></span>
        </article>} />
      </Card>
      {showWizard && <ProductWizard product={wizardProduct} categories={store.categories} lowStockThreshold={store.settings.lowStockThreshold} onClose={() => { setShowWizard(false); setWizardProduct(null); }} onSave={submit} onAddCategory={async (name) => { await store.addCategory(name); notify('Category added.'); }} />}
    </>
  );
}

