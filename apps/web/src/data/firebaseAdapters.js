const expiryTypes = new Set([
  'Expiry Date',
  'Use-By',
  'Best Before',
  'Best if Used By',
  'Sell By',
  'Period After Opening',
]);

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

function batchQuantity(batch) {
  return Math.max(0, Number(batch?.qty) || 0);
}

export function productRowsFromDocument(id, raw) {
  const sourceVariants = Array.isArray(raw.variants) && raw.variants.length
    ? raw.variants
    : [{ id: 'default', name: raw.name || 'Item', unit: 'piece', batches: [], price: 0, costPrice: 0 }];
  return sourceVariants.map((variant, index) => {
    const variantId = String(variant.id || 'variant-' + index);
    const batches = Array.isArray(variant.batches) ? variant.batches : [];
    const stock = batches.reduce((sum, batch) => sum + batchQuantity(batch), 0);
    const costTotal = batches.reduce((sum, batch) => sum + batchQuantity(batch) * (Number(batch.costPrice) || Number(variant.costPrice) || 0), 0);
    const indicators = batches.flatMap((batch) => Array.isArray(batch.indicators) ? batch.indicators : [])
      .filter((item) => expiryTypes.has(item.type) && item.date)
      .map((item) => dateToDayString(item.date))
      .filter(Boolean)
      .sort();
    return {
      id: id + '::' + variantId,
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
      expiryDate: indicators[0] || '',
      __raw: raw,
    };
  });
}

export function saleFromDocument(id, raw) {
  const items = (Array.isArray(raw.items) ? raw.items : []).map((item) => ({
    productId: item.productId || '',
    variantId: item.variantId || '',
    name: item.productName || '',
    variantName: item.variantName || '',
    conditionName: item.conditionName || '',
    qty: Number(item.qty) || 0,
    price: Number(item.price) || 0,
    cost: Number(item.costPrice) || 0,
    discount: Number(item.discount) || 0,
    total: Math.max(0, (Number(item.price) || 0) * (Number(item.qty) || 0) - (Number(item.discount) || 0)),
  }));
  let payment = 'Cash';
  if (raw.paymentType === 'utang') payment = 'Utang';
  else if (raw.paymentType === 'multi') payment = 'Mixed';
  else if ((raw.notes || '').toLowerCase().includes('gcash')) payment = 'GCash';
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
    __raw: raw,
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

export function utangFromDocument(id, raw) {
  const amount = Number(raw.totalAmount) || 0;
  const amountPaid = Number(raw.amountPaid) || 0;
  return {
    id,
    customerId: raw.customerId || '',
    customer: raw.customerName || 'Customer',
    phone: raw.customerPhone || '',
    amount,
    balance: Math.max(0, amount - amountPaid),
    amountPaid,
    createdAt: dateToString(raw.startDate),
    dueDate: dateToDayString(raw.dueDate),
    note: raw.notes || '',
    status: raw.status || 'pending',
    payments: Array.isArray(raw.payments) ? raw.payments : [],
    __raw: raw,
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
    __raw: raw,
  };
}

export function categoryFromDocument(id, raw) {
  return { id, ...raw, name: raw.name || '' };
}

export function customerFromDocument(id, raw) {
  return {
    id,
    name: raw.name || '',
    phone: raw.phone || '',
    visits: Number(raw.visits) || 0,
    spent: Number(raw.totalPurchases) || 0,
    address: raw.address || '',
    notes: raw.notes || '',
    __raw: raw,
  };
}

export function activityFromDocument(id, raw) {
  const timestamp = dateToString(raw.timestamp);
  return {
    id,
    action: raw.action || '',
    targetType: raw.targetType || '',
    targetId: raw.targetId || '',
    targetName: raw.targetName || '',
    employeeName: raw.employeeName || 'Store owner',
    timestamp,
    date: timestamp.slice(0, 10),
    details: raw.details && typeof raw.details === 'object' ? raw.details : {},
    __raw: raw,
  };
}

export function employeeFromDocument(id, raw) {
  const safeRaw = { ...raw };
  delete safeRaw.pin;
  return {
    id,
    name: raw.name || '',
    role: 'Employee',
    email: '',
    status: 'Active',
    __raw: safeRaw,
  };
}

export function newProductDocument(product, id, storeId, category) {
  const inputVariants = Array.isArray(product.variants) && product.variants.length
    ? product.variants
    : [{ id: 'variant-' + id, name: product.name, sku: product.sku || '', unit: product.unit || 'piece', price: product.price, originalPrice: product.price, costPrice: product.cost, batches: Number(product.stock) > 0 ? [{ id: 'batch-' + id, qty: product.stock, costPrice: product.cost, indicators: product.expiryDate ? [{ type: 'Expiry Date', date: product.expiryDate }] : [] }] : [] }];
  const variants = inputVariants.map((variant, index) => ({
    id: variant.id || `variant-${id}-${index}`,
    name: variant.name || product.name,
    sku: variant.sku || '',
    unit: variant.unit || 'piece',
    packaging: variant.packaging || '',
    pcsPerUnit: Math.max(1, Number(variant.pcsPerUnit) || 1),
    price: Number(variant.price) || 0,
    originalPrice: Number(variant.originalPrice ?? variant.price) || 0,
    costPrice: Number(variant.costPrice) || 0,
    hasDiscount: Boolean(variant.hasDiscount || variant.discounts?.length),
    discounts: Array.isArray(variant.discounts) ? variant.discounts : [],
    conditions: Array.isArray(variant.conditions) ? variant.conditions : [],
    imageUrl: variant.imageUrl || '',
    batches: (Array.isArray(variant.batches) ? variant.batches : []).map((batch, batchIndex) => ({
      id: batch.id || `batch-${id}-${index}-${batchIndex}`,
      batchNumber: batch.batchNumber || '',
      qty: Math.max(0, Number(batch.qty) || 0),
      costPrice: Number(batch.costPrice ?? variant.costPrice) || 0,
      indicators: Array.isArray(batch.indicators) ? batch.indicators : [],
      addedOn: batch.addedOn || todayKey(),
    })),
  }));
  return {
    id,
    storeId,
    name: product.name,
    description: product.description || '',
    categoryId: category?.id || '',
    categoryName: product.category || 'Uncategorized',
    hasVariants: Boolean(product.hasVariants),
    iconIndex: 0,
    colorIndex: 0,
    imageUrl: product.imageUrl || '',
    minStock: Number(product.minStock) || 0,
    variants,
    addedOn: todayKey(),
    updatedAt: isoNow(),
  };
}

function changeBatchesToStock(batches, targetStock, costPrice) {
  let next = (Array.isArray(batches) ? batches : []).map((batch) => ({ ...batch }));
  let current = next.reduce((sum, batch) => sum + batchQuantity(batch), 0);
  const target = Math.max(0, Number(targetStock) || 0);
  if (target > current) {
    const batch = {
      id: 'batch-' + Math.random().toString(36).slice(2, 10),
      batchNumber: '',
      qty: target - current,
      costPrice: Number(costPrice) || 0,
      indicators: [],
      addedOn: todayKey(),
    };
    next.push(batch);
    return next;
  }
  let remove = current - target;
  const priority = (batch) => {
    const dates = (Array.isArray(batch.indicators) ? batch.indicators : [])
      .filter((item) => expiryTypes.has(item.type) && item.date)
      .map((item) => dateToDayString(item.date))
      .filter(Boolean)
      .sort();
    return dates[0] || '9999-12-31';
  };
  const order = next.map((batch, index) => ({ batch, index, priority: priority(batch) }))
    .sort((a, b) => a.priority.localeCompare(b.priority));
  for (const entry of order) {
    if (remove <= 0) break;
    const amount = batchQuantity(entry.batch);
    const deducted = Math.min(amount, remove);
    next[entry.index] = { ...entry.batch, qty: amount - deducted };
    remove -= deducted;
  }
  return next.filter((batch) => batchQuantity(batch) > 0);
}

export function patchProductDocument(raw, product, variantId, storeId) {
  const sourceVariants = Array.isArray(raw.variants) ? raw.variants : [];
  const mapCompleteVariant = (completeVariant, index) => {
    const previous = sourceVariants.find((variant, sourceIndex) => String(variant.id || `variant-${sourceIndex}`) === String(completeVariant.id)) || {};
    const price = Number(completeVariant.price) || 0;
    return {
      ...previous,
      id: completeVariant.id || previous.id || `variant-${index}`,
      name: completeVariant.name || product.name || previous.name || '',
      sku: completeVariant.sku || '',
      unit: completeVariant.unit || 'piece',
      packaging: completeVariant.packaging || '',
      pcsPerUnit: Math.max(1, Number(completeVariant.pcsPerUnit) || 1),
      price,
      originalPrice: Number(completeVariant.originalPrice ?? price) || 0,
      costPrice: Number(completeVariant.costPrice) || 0,
      hasDiscount: Boolean(completeVariant.hasDiscount || completeVariant.discounts?.length),
      discounts: Array.isArray(completeVariant.discounts) ? completeVariant.discounts : [],
      conditions: Array.isArray(completeVariant.conditions) ? completeVariant.conditions : [],
      imageUrl: completeVariant.imageUrl || '',
      batches: Array.isArray(completeVariant.batches) ? completeVariant.batches : [],
    };
  };
  let variants;
  if (Array.isArray(product.variants)) {
    variants = product.variants.map(mapCompleteVariant);
  } else {
    variants = sourceVariants.map((variant) => {
    if (String(variant.id) !== String(variantId)) return variant;
    const price = product.price === undefined ? Number(variant.price) || 0 : Number(product.price) || 0;
    const cost = product.cost === undefined ? Number(variant.costPrice) || 0 : Number(product.cost) || 0;
    return {
      ...variant,
      sku: product.sku === undefined ? (variant.sku || '') : product.sku,
      unit: product.unit === undefined ? (variant.unit || 'piece') : product.unit,
      price,
      originalPrice: price,
      costPrice: cost,
      batches: product.stock === undefined ? (variant.batches || []) : changeBatchesToStock(variant.batches, product.stock, cost),
    };
    });
  }
  return {
    ...raw,
    id: raw.id || '',
    storeId,
    name: product.name === undefined ? raw.name : product.name,
    description: product.description === undefined ? (raw.description || '') : product.description,
    imageUrl: product.imageUrl === undefined ? (raw.imageUrl || '') : product.imageUrl,
    hasVariants: product.hasVariants === undefined ? Boolean(raw.hasVariants) : Boolean(product.hasVariants),
    categoryId: product.categoryId === undefined ? (raw.categoryId || '') : product.categoryId,
    categoryName: product.category === undefined ? (raw.categoryName || '') : product.category,
    minStock: product.minStock === undefined ? Number(raw.minStock ?? 12) : Number(product.minStock) || 0,
    variants,
    updatedAt: isoNow(),
  };
}

export function changeProductExpiry(raw, variantId, expiryDate, storeId) {
  const variants = (Array.isArray(raw.variants) ? raw.variants : []).map((variant) => {
    if (String(variant.id) !== String(variantId)) return variant;
    let batches = (Array.isArray(variant.batches) ? variant.batches : []).map((batch) => ({ ...batch }));
    if (!batches.length && expiryDate) {
      batches = [{
        id: 'batch-' + Math.random().toString(36).slice(2, 10),
        batchNumber: '',
        qty: 0,
        costPrice: Number(variant.costPrice) || 0,
        indicators: [],
        addedOn: todayKey(),
      }];
    }
    if (batches.length) {
      const expiryPriority = (batch) => (Array.isArray(batch.indicators) ? batch.indicators : [])
        .filter((item) => expiryTypes.has(item.type) && item.date)
        .map((item) => dateToDayString(item.date))
        .filter(Boolean)
        .sort()[0] || '9999-12-31';
      const batchIndex = batches.map((batch, index) => ({ index, priority: expiryPriority(batch) }))
        .sort((a, b) => a.priority.localeCompare(b.priority))[0].index;
      const batch = { ...batches[batchIndex] };
      const indicators = (Array.isArray(batch.indicators) ? batch.indicators : []).filter((item) => !expiryTypes.has(item.type));
      if (expiryDate) indicators.push({ type: 'Expiry Date', date: expiryDate });
      batch.indicators = indicators;
      batches[batchIndex] = batch;
    }
    return { ...variant, batches };
  });
  return { ...raw, storeId, variants, updatedAt: isoNow() };
}

export function restockProductVariant(raw, variantId, amount, storeId, options = {}) {
  const variants = (Array.isArray(raw.variants) ? raw.variants : []).map((variant) => {
    if (String(variant.id) !== String(variantId)) return variant;
    const batches = [...(Array.isArray(variant.batches) ? variant.batches : []), {
      id: 'batch-' + Math.random().toString(36).slice(2, 10),
      batchNumber: '',
      qty: Math.max(1, Number(amount) || 1),
      costPrice: options.costPrice === '' || options.costPrice === undefined ? Number(variant.costPrice) || 0 : Math.max(0, Number(options.costPrice) || 0),
      indicators: options.expiryDate ? [{ type: 'Expiry Date', date: options.expiryDate }] : [],
      addedOn: todayKey(),
    }];
    return { ...variant, batches };
  });
  return { ...raw, storeId, variants, updatedAt: isoNow() };
}

export function deductProductVariant(raw, variantId, quantity, storeId) {
  let found = false;
  const variants = (Array.isArray(raw.variants) ? raw.variants : []).map((variant) => {
    if (String(variant.id) !== String(variantId)) return variant;
    found = true;
    const batches = (Array.isArray(variant.batches) ? variant.batches : []).map((batch) => ({ ...batch }));
    let remaining = quantity;
    const priority = (batch) => {
      const dates = (Array.isArray(batch.indicators) ? batch.indicators : [])
        .filter((item) => expiryTypes.has(item.type) && item.date)
        .map((item) => dateToDayString(item.date))
        .filter(Boolean)
        .sort();
      return dates[0] || '9999-12-31';
    };
    const order = batches.map((batch, index) => ({ batch, index, priority: priority(batch) }))
      .sort((a, b) => a.priority.localeCompare(b.priority));
    for (const entry of order) {
      if (remaining <= 0) break;
      const amount = batchQuantity(entry.batch);
      const deducted = Math.min(amount, remaining);
      batches[entry.index] = { ...entry.batch, qty: amount - deducted };
      remaining -= deducted;
    }
    if (remaining > 0) throw new Error('Not enough stock for ' + (raw.name || 'this product') + '.');
    return { ...variant, batches: batches.filter((batch) => batchQuantity(batch) > 0) };
  });
  if (!found) throw new Error('The product variant was removed. Refresh and try again.');
  return { ...raw, storeId, variants, updatedAt: isoNow() };
}

