import { Button, SelectField } from './UI.jsx';

export function ProductImage({ product, className = '' }) {
  const fallback = product?.name?.charAt(0)?.toUpperCase() || '?';
  return product?.imageUrl
    ? <span className={`product-photo ${className}`}><img src={product.imageUrl} alt="" loading="lazy" onError={(event) => { event.currentTarget.style.display = 'none'; }} /><span>{fallback}</span></span>
    : <span className={`product-initial ${className}`}>{fallback}</span>;
}

export const PRODUCT_VIEW_OPTIONS = [
  ['list', 'List'],
  ['compact', 'Compact'],
  ['grid', 'Grid'],
  ['details', 'Details'],
];

export const PRODUCT_SORT_OPTIONS = [
  ['recent', 'Recently added'],
  ['name-asc', 'Name A–Z'],
  ['name-desc', 'Name Z–A'],
  ['category-asc', 'Category A–Z'],
  ['category-desc', 'Category Z–A'],
  ['stock-asc', 'Stock: low to high'],
  ['stock-desc', 'Stock: high to low'],
  ['expiry-asc', 'Expiry: nearest first'],
  ['expiry-desc', 'Expiry: furthest first'],
  ['price-asc', 'Price: low to high'],
  ['price-desc', 'Price: high to low'],
];

function dateValue(value) {
  if (!value) return 0;
  if (typeof value.toMillis === 'function') return value.toMillis();
  if (typeof value.toDate === 'function') return value.toDate().getTime();
  const parsed = Date.parse(String(value));
  return Number.isFinite(parsed) ? parsed : 0;
}

function compareText(left, right) {
  return String(left || '').localeCompare(String(right || ''), undefined, { numeric: true, sensitivity: 'base' });
}

export function sortProductRows(products, sortBy) {
  const collator = (left, right) => compareText(left, right);
  return [...products].sort((a, b) => {
    const nameA = `${a.name} ${a.variantName || ''}`;
    const nameB = `${b.name} ${b.variantName || ''}`;
    switch (sortBy) {
      case 'name-asc': return collator(nameA, nameB);
      case 'name-desc': return collator(nameB, nameA);
      case 'category-asc': return collator(a.category, b.category) || collator(nameA, nameB);
      case 'category-desc': return collator(b.category, a.category) || collator(nameA, nameB);
      case 'stock-asc': return Number(a.stock) - Number(b.stock) || collator(nameA, nameB);
      case 'stock-desc': return Number(b.stock) - Number(a.stock) || collator(nameA, nameB);
      case 'expiry-asc': {
        const left = dateValue(a.expiryDate);
        const right = dateValue(b.expiryDate);
        if (!left) return right ? 1 : collator(nameA, nameB);
        if (!right) return -1;
        return left - right || collator(nameA, nameB);
      }
      case 'expiry-desc': {
        const left = dateValue(a.expiryDate);
        const right = dateValue(b.expiryDate);
        if (!left) return right ? 1 : collator(nameA, nameB);
        if (!right) return -1;
        return right - left || collator(nameA, nameB);
      }
      case 'price-asc': return Number(a.price) - Number(b.price) || collator(nameA, nameB);
      case 'price-desc': return Number(b.price) - Number(a.price) || collator(nameA, nameB);
      case 'recent':
      default:
        return dateValue(b.__raw?.addedOn || b.__raw?.createdAt || b.__raw?.updatedAt)
          - dateValue(a.__raw?.addedOn || a.__raw?.createdAt || a.__raw?.updatedAt)
          || collator(nameA, nameB);
    }
  });
}

export function groupProductRows(products, grouped) {
  if (!grouped) return products.map((product) => ({ id: product.id, product, products: [product] }));
  const groups = new Map();
  products.forEach((product) => {
    const id = product.firestoreId || product.id;
    const group = groups.get(id) || { id, product, products: [] };
    group.products.push(product);
    groups.set(id, group);
  });
  return [...groups.values()];
}

export function ProductBrowserToolbar({ viewMode, onViewModeChange, sortBy, onSortChange, grouped, onGroupedChange }) {
  return <div className="product-browser-controls" aria-label="Product display options">
    <SelectField label="View" value={viewMode} onChange={(event) => onViewModeChange(event.target.value)}>
      {PRODUCT_VIEW_OPTIONS.map(([value, label]) => <option key={value} value={value}>{label}</option>)}
    </SelectField>
    <SelectField label="Sort by" value={sortBy} onChange={(event) => onSortChange(event.target.value)}>
      {PRODUCT_SORT_OPTIONS.map(([value, label]) => <option key={value} value={value}>{label}</option>)}
    </SelectField>
    <Button type="button" variant={grouped ? 'secondary' : 'outline'} icon="products" aria-pressed={grouped} onClick={() => onGroupedChange(!grouped)}>
      {grouped ? 'Grouped' : 'Ungrouped'}
    </Button>
  </div>;
}

export function ProductBrowserResults({ products, viewMode, grouped, renderProduct, emptyMessage = 'No products found.' }) {
  if (!products.length) return <div className="empty-state"><strong>{emptyMessage}</strong></div>;
  const groups = groupProductRows(products, grouped);
  const grid = viewMode === 'grid';
  return <div className={`product-browser-results ${grid ? 'product-browser-results-grid' : 'product-browser-results-list'}`}>
    {groups.map((group) => {
      if (!grouped || group.products.length === 1) return renderProduct(group.product, viewMode);
      const stock = group.products.reduce((sum, product) => sum + Number(product.stock || 0), 0);
      return <section className={`product-browser-group${grid ? ' product-browser-group-grid' : ''}`} key={group.id}>
        <header className="product-browser-group-heading">
          <strong>{group.product.name}</strong>
          <span>{group.product.category} · {group.products.length} {group.products.length === 1 ? 'variant' : 'variants'} · {stock} units</span>
        </header>
        <div className={`product-browser-group-items${grid ? ' product-browser-group-items-grid' : ''}`}>
          {group.products.map((product) => renderProduct(product, viewMode))}
        </div>
      </section>;
    })}
  </div>;
}
