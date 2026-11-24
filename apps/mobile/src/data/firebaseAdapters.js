const expiryTypes = new Set(['Expiry Date', 'Use-By', 'Best Before', 'Best if Used By', 'Sell By', 'Period After Opening']);

export const todayKey = () => {
  const now = new Date();
  return [now.getFullYear(), String(now.getMonth() + 1).padStart(2, '0'), String(now.getDate()).padStart(2, '0')].join('-');
};

export const isoNow = () => new Date().toISOString();
export function dateToString(value) {
  if (value == null || value === '') return '';
  if (typeof value === 'string') return value;
  if (value instanceof Date) return Number.isNaN(value.getTime()) ? '' : value.toISOString();
  if (typeof value.toDate === 'function') return dateToString(value.toDate());
  if (typeof value.seconds === 'number') return new Date(value.seconds * 1000).toISOString();
  if (typeof value === 'number') return new Date(value < 1e12 ? value * 1000 : value).toISOString();
  return '';
}
export const dateToDayString = (value) => dateToString(value).slice(0, 10);
const qtyOf = (batch) => Math.max(0, Number(batch?.qty) || 0);

export function productRowsFromDocument(id, raw) {
  const variants = Array.isArray(raw.variants) && raw.variants.length
    ? raw.variants
    : [{ id: 'default', name: raw.name || 'Item', unit: 'piece', batches: [], price: 0, costPrice: 0 }];
  return variants.map((variant, index) => {
    const batches = Array.isArray(variant.batches) ? variant.batches : [];
    const stock = batches.reduce((sum, batch) => sum + qtyOf(batch), 0);
    const costTotal = batches.reduce((sum, batch) => sum + qtyOf(batch) * (Number(batch.costPrice) || Number(variant.costPrice) || 0), 0);
    const expiryDate = batches.flatMap((batch) => batch.indicators || [])
      .filter((indicator) => expiryTypes.has(indicator.type) && indicator.date)
      .map((indicator) => dateToDayString(indicator.date)).filter(Boolean).sort()[0] || '';
    const variantId = String(variant.id || `variant-${index}`);
    return {
      id: `${id}::${variantId}`,
      firestoreId: id,
      variantId,
      name: raw.name || 'Untitled product',
      variantName: variant.name || '',
      sku: variant.sku || '',
      category: raw.categoryName || 'Uncategorized',
      categoryId: raw.categoryId || '',
      unit: variant.unit || 'piece',
      stock,
      minStock: Number(raw.minStock ?? 12),
      cost: stock ? costTotal / stock : Number(variant.costPrice) || 0,
      price: Number(variant.price) || 0,
      imageUrl: variant.imageUrl || raw.imageUrl || '',
      expiryDate,
      __raw: raw,
    };
  });
}

export function saleFromDocument(id, raw) {
  const items = (raw.items || []).map((item) => ({
    productId: item.productId || '',
    variantId: item.variantId || '',
    name: item.productName || '',
    variantName: item.variantName || '',
    conditionName: item.conditionName || '',
    qty: Number(item.qty) || 0,
    price: Number(item.price) || 0,
    cost: Number(item.costPrice) || 0,
    discount: Number(item.discount) || 0,
    total: Math.max(0, (Number(item.qty) || 0) * (Number(item.price) || 0) - (Number(item.discount) || 0)),
  }));
  const payment = raw.paymentType === 'utang' ? 'Utang'
    : raw.paymentType === 'multi' ? 'Mixed'
      : (raw.notes || '').toLowerCase().includes('gcash') ? 'GCash' : 'Cash';
  return {
    id,
    customerId: raw.customerId || '',
    date: dateToDayString(raw.date),
    timestamp: dateToString(raw.timestamp),
    customer: raw.customerName || 'Walk-in customer',
    payment,
    total: Number(raw.total) || 0,
    subtotal: Number(raw.subtotal) || items.reduce((sum, item) => sum + item.price * item.qty, 0),
    totalDiscount: Number(raw.totalDiscount) || items.reduce((sum, item) => sum + item.discount, 0),
    amountPaid: Number(raw.amountPaid) || 0,
    change: Number(raw.change) || 0,
    status: raw.status || 'completed',
    items,
  };
}

export function inventoryLogFromDocument(id, raw) {
  const date = dateToString(raw.date);
  return {
    id,
    storeId: raw.storeId || '',
    productId: raw.productId || '',
    productName: raw.productName || 'Item',
    variantId: raw.variantId || '',
    variantName: raw.variantName || '',
    type: raw.type || 'adjustment',
    qty: Number(raw.qty) || 0,
    costPrice: Number(raw.costPrice) || 0,
    reason: raw.reason || '',
    employeeId: raw.employeeId || '',
    employeeName: raw.employeeName || '',
    date: dateToDayString(date),
    updatedAt: dateToString(raw.updatedAt),
  };
}

export function customerFromDocument(id, raw) {
  return {
    id,
    name: raw.name || '',
    phone: raw.phone || '',
    address: raw.address || '',
    notes: raw.notes || '',
    visits: Number(raw.visits) || 0,
    spent: Number(raw.totalPurchases) || 0,
    __raw: raw,
  };
}

export function categoryFromDocument(id, raw) {
  return { id, ...raw, name: raw.name || '' };
}

export function employeeFromDocument(id, raw) {
  return { id, name: raw.name || '', role: 'Store employee', email: '', status: 'Active' };
}

export function utangFromDocument(id, raw) {
  const amount = Number(raw.totalAmount) || 0;
  const amountPaid = Number(raw.amountPaid) || 0;
  return {
    id,
    customerId: raw.customerId || '',
    customer: raw.customerName || 'Customer',
    phone: raw.customerPhone || '',
    amount,
    amountPaid,
    balance: Math.max(0, amount - amountPaid),
    createdAt: dateToString(raw.startDate),
    dueDate: dateToDayString(raw.dueDate),
    note: raw.notes || '',
    status: raw.status || 'pending',
  };
}

export function noteFromDocument(id, raw) {
  return {
    id,
    type: raw.type || 'note',
    title: raw.title || '',
    content: raw.content || '',
    dueDate: dateToDayString(raw.date),
    done: Boolean(raw.done),
    createdAt: dateToString(raw.updatedAt || raw.date),
  };
}

export function changeProductExpiry(raw, variantId, expiryDate, storeId) {
  const variants = (raw.variants || []).map((variant) => {
    if (String(variant.id) !== String(variantId)) return variant;
    let batches = (variant.batches || []).map((batch) => ({ ...batch }));
    if (!batches.length && expiryDate) batches = [{
      id: `batch-${Date.now()}`, batchNumber: '', qty: 0, costPrice: Number(variant.costPrice) || 0, indicators: [], addedOn: todayKey(),
    }];
    if (batches.length) {
      const expiryPriority = (batch) => (batch.indicators || []).filter((indicator) => expiryTypes.has(indicator.type) && indicator.date).map((indicator) => dateToDayString(indicator.date)).filter(Boolean).sort()[0] || '9999-12-31';
      const index = batches.map((batch, order) => ({ order, date: expiryPriority(batch) })).sort((a, b) => a.date.localeCompare(b.date))[0].order;
      const batch = { ...batches[index] };
      const indicators = (batch.indicators || []).filter((indicator) => !expiryTypes.has(indicator.type));
      if (expiryDate) indicators.push({ type: 'Expiry Date', date: expiryDate });
      batch.indicators = indicators;
      batches[index] = batch;
    }
    return { ...variant, batches };
  });
  return { ...raw, storeId, variants, updatedAt: isoNow() };
}

export function newProductDocument(product, id, storeId, categoryId) {
  const inputVariants = Array.isArray(product.variants) && product.variants.length
    ? product.variants
    : [{ id: `variant-${id}`, name: product.name, sku: product.sku || '', unit: product.unit || 'piece', price: product.price, originalPrice: product.price, costPrice: product.cost, batches: Number(product.stock) > 0 ? [{ id: `batch-${id}`, qty: product.stock, costPrice: product.cost, indicators: [] }] : [] }];
  const variants = inputVariants.map((variant, index) => ({
    id: variant.id || `variant-${id}-${index}`, name: variant.name || product.name, sku: variant.sku || '',
    unit: variant.unit || 'piece', packaging: variant.packaging || '', pcsPerUnit: Math.max(1, Number(variant.pcsPerUnit) || 1),
    price: Number(variant.price) || 0, originalPrice: Number(variant.originalPrice ?? variant.price) || 0,
    costPrice: Number(variant.costPrice) || 0, hasDiscount: Boolean(variant.hasDiscount || variant.discounts?.length),
    discounts: Array.isArray(variant.discounts) ? variant.discounts : [], conditions: Array.isArray(variant.conditions) ? variant.conditions : [], imageUrl: variant.imageUrl || '',
    batches: (Array.isArray(variant.batches) ? variant.batches : []).map((batch, batchIndex) => ({
      id: batch.id || `batch-${id}-${index}-${batchIndex}`, batchNumber: batch.batchNumber || '', qty: Math.max(0, Number(batch.qty) || 0),
      costPrice: Number(batch.costPrice ?? variant.costPrice) || 0, indicators: Array.isArray(batch.indicators) ? batch.indicators : [], addedOn: batch.addedOn || todayKey(),
    })),
  }));
  return {
    id, storeId, name: product.name, description: product.description || '', categoryId: categoryId || '', categoryName: product.category || 'Uncategorized',
    hasVariants: Boolean(product.hasVariants), iconIndex: 0, colorIndex: 0, imageUrl: product.imageUrl || '', minStock: Math.max(0, Number(product.minStock) || 0), variants,
    addedOn: todayKey(), updatedAt: isoNow(),
  };
}

function batchesAtStock(batches, target, cost) {
  const next = (batches || []).map((batch) => ({ ...batch }));
  const current = next.reduce((sum, batch) => sum + qtyOf(batch), 0);
  const goal = Math.max(0, Number(target) || 0);
  if (goal > current) next.push({ id: `batch-${Date.now()}`, batchNumber: '', qty: goal - current, costPrice: cost, indicators: [], addedOn: todayKey() });
  let remove = Math.max(0, current - goal);
  const ordered = next.map((batch, index) => ({ index, date: (batch.indicators || []).filter((item) => expiryTypes.has(item.type) && item.date).map((item) => dateToDayString(item.date)).filter(Boolean).sort()[0] || '9999-12-31' })).sort((a, b) => a.date.localeCompare(b.date));
  for (const entry of ordered) {
    if (!remove) break;
    const amount = qtyOf(next[entry.index]);
    const used = Math.min(amount, remove);
    next[entry.index] = { ...next[entry.index], qty: amount - used };
    remove -= used;
  }
  return next.filter((batch) => qtyOf(batch) > 0);
}

export function patchProductDocument(raw, product, variantId, storeId, categoryId) {
  const oldVariants = Array.isArray(raw.variants) ? raw.variants : [];
  const variants = Array.isArray(product.variants) ? product.variants.map((item, index) => {
    const previous = oldVariants.find((variant, sourceIndex) => String(variant.id || `variant-${sourceIndex}`) === String(item.id)) || {};
    const price = Number(item.price) || 0;
    return {
      ...previous, id: item.id || previous.id || `variant-${index}`, name: item.name || product.name || previous.name || '', sku: item.sku || '',
      unit: item.unit || 'piece', packaging: item.packaging || '', pcsPerUnit: Math.max(1, Number(item.pcsPerUnit) || 1),
      price, originalPrice: Number(item.originalPrice ?? price) || 0, costPrice: Number(item.costPrice) || 0,
      hasDiscount: Boolean(item.hasDiscount || item.discounts?.length), discounts: Array.isArray(item.discounts) ? item.discounts : [],
      conditions: Array.isArray(item.conditions) ? item.conditions : [], imageUrl: item.imageUrl || '', batches: Array.isArray(item.batches) ? item.batches : [],
    };
  }) : oldVariants.map((variant) => String(variant.id) !== String(variantId) ? variant : ({
    ...variant, sku: product.sku, unit: product.unit, price: Number(product.price) || 0, originalPrice: Number(product.price) || 0,
    costPrice: Number(product.cost) || 0, batches: batchesAtStock(variant.batches, product.stock, Number(product.cost) || 0),
  }));
  return {
    ...raw, storeId, name: product.name, description: product.description === undefined ? (raw.description || '') : product.description,
    imageUrl: product.imageUrl === undefined ? (raw.imageUrl || '') : product.imageUrl, hasVariants: product.hasVariants === undefined ? Boolean(raw.hasVariants) : Boolean(product.hasVariants),
    categoryId: categoryId || raw.categoryId || '', categoryName: product.category,
    minStock: Math.max(0, Number(product.minStock) || 0), variants, updatedAt: isoNow(),
  };
}

export function restockProductVariant(raw, variantId, amount, storeId, options = {}) {
  const variants = (raw.variants || []).map((variant) => String(variant.id) !== String(variantId) ? variant : ({
    ...variant,
    batches: [...(variant.batches || []), { id: `batch-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`, batchNumber: '', qty: Math.max(1, Number(amount) || 1), costPrice: options.costPrice === '' || options.costPrice === undefined ? Number(variant.costPrice) || 0 : Math.max(0, Number(options.costPrice) || 0), indicators: options.expiryDate ? [{ type: 'Expiry Date', date: options.expiryDate }] : [], addedOn: todayKey() }],
  }));
  return { ...raw, storeId, variants, updatedAt: isoNow() };
}

export function deductProductVariant(raw, variantId, quantity, storeId) {
  let found = false;
  const variants = (raw.variants || []).map((variant) => {
    if (String(variant.id) !== String(variantId)) return variant;
    found = true;
    const batches = (variant.batches || []).map((batch) => ({ ...batch }));
    const priority = (batch) => (batch.indicators || []).filter((item) => expiryTypes.has(item.type) && item.date).map((item) => dateToDayString(item.date)).filter(Boolean).sort()[0] || '9999-12-31';
    const order = batches.map((batch, index) => ({ index, date: priority(batch) })).sort((a, b) => a.date.localeCompare(b.date));
    let remaining = Number(quantity) || 0;
    for (const entry of order) {
      if (remaining <= 0) break;
      const amount = qtyOf(batches[entry.index]);
      const used = Math.min(amount, remaining);
      batches[entry.index] = { ...batches[entry.index], qty: amount - used };
      remaining -= used;
    }
    if (remaining > 0) throw new Error(`Not enough stock for ${raw.name || 'this product'}.`);
    return { ...variant, batches: batches.filter((batch) => qtyOf(batch) > 0) };
  });
  if (!found) throw new Error('This product variant was removed. Refresh and try again.');
  return { ...raw, storeId, variants, updatedAt: isoNow() };
}
