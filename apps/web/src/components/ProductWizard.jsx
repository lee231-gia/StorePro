import React from 'react';
import { Button, Modal, SelectField, TextAreaField, TextField } from './UI.jsx';
import Icon from './Icon.jsx';
import { uploadProductImage } from '../services/productImageUpload.js';

const LIFE_INDICATORS = ['Expiry Date', 'Best Before', 'Best if Used By', 'Use-By', 'Manufacturing Date (MFG)', 'Production Date', 'Packed On', 'Sell By', 'Period After Opening'];
const key = (prefix) => `${prefix}-${globalThis.crypto?.randomUUID?.() || Math.random().toString(36).slice(2)}`;
const localToday = () => { const now = new Date(); return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`; };
const blankVariant = () => ({ id: key('variant'), name: '', sku: '', unit: 'piece', packaging: 'Solo', pcsPerUnit: '1', price: '', originalPrice: '', costPrice: '', imageUrl: '', imageFile: null, conditions: [], discounts: [], batches: [] });
const blankProduct = (categories, lowStockThreshold) => ({ name: '', description: '', category: categories[0] || '', hasVariants: false, imageUrl: '', imageFile: null, minStock: String(lowStockThreshold ?? 12), variants: [blankVariant()] });

function productFromRow(row, categories, lowStockThreshold) {
  if (!row) return blankProduct(categories, lowStockThreshold);
  const raw = row.__raw || {};
  const variants = (Array.isArray(raw.variants) ? raw.variants : []).map((variant, index) => ({
    ...blankVariant(),
    ...variant,
    id: String(variant.id || `variant-${index}`),
    name: variant.name || '',
    sku: variant.sku || '',
    unit: variant.unit || 'piece',
    packaging: variant.packaging || '',
    pcsPerUnit: String(variant.pcsPerUnit || 1),
    price: String(variant.price ?? ''),
    originalPrice: String(variant.originalPrice ?? variant.price ?? ''),
    costPrice: String(variant.costPrice ?? ''),
    imageUrl: variant.imageUrl || '',
    imageFile: null,
    conditions: Array.isArray(variant.conditions) ? variant.conditions.map((item) => ({ ...item })) : [],
    discounts: Array.isArray(variant.discounts) ? variant.discounts.map((item) => ({ ...item })) : [],
    batches: Array.isArray(variant.batches) ? variant.batches.map((batch) => ({ ...batch, indicators: Array.isArray(batch.indicators) ? batch.indicators.map((item) => ({ ...item })) : [] })) : [],
  }));
  return {
    name: raw.name || row.name || '',
    description: raw.description || '',
    category: raw.categoryName || row.category || categories[0] || '',
    hasVariants: Boolean(raw.hasVariants || variants.length > 1),
    // Older single-product records can keep their photo on the only variant.
    imageUrl: raw.imageUrl || variants[0]?.imageUrl || row.imageUrl || '',
    imageFile: null,
    minStock: String(raw.minStock ?? row.minStock ?? lowStockThreshold ?? 12),
    variants: variants.length ? variants : [{ ...blankVariant(), name: row.variantName || '', sku: row.sku || '', unit: row.unit || 'piece', price: String(row.price ?? ''), costPrice: String(row.cost ?? ''), batches: [] }],
  };
}

function ImagePickerField({ label, imageUrl, imageFile, onFile, onRemove }) {
  const [preview, setPreview] = React.useState('');
  const [error, setError] = React.useState('');
  React.useEffect(() => {
    if (!imageFile) { setPreview(''); return undefined; }
    const url = URL.createObjectURL(imageFile);
    setPreview(url);
    return () => URL.revokeObjectURL(url);
  }, [imageFile]);
  const changeFile = (event) => {
    const file = event.target.files?.[0];
    event.target.value = '';
    if (!file) return;
    if (!file.type.startsWith('image/')) { setError('Choose an image file.'); return; }
    if (file.size > 10 * 1024 * 1024) { setError('Choose an image smaller than 10 MB.'); return; }
    setError('');
    onFile(file);
  };
  const src = preview || imageUrl;
  return <div className="wizard-image-field">
    <div className={`wizard-image-preview${src ? ' wizard-image-preview-filled' : ''}`}>
      {src ? <img src={src} alt={`${label} preview`} /> : <><Icon name="image" size={28} /><span>No image</span></>}
    </div>
    <div className="wizard-image-controls"><strong>{label}</strong><small>JPG, PNG, or WebP · up to 10 MB</small><div className="wizard-image-actions"><label className="button button-outline button-sm wizard-file-button"><Icon name="plus" size={16} /><span>{src ? 'Change image' : 'Choose image'}</span><input type="file" accept="image/*" onChange={changeFile} /></label>{src && <Button size="sm" variant="ghost" onClick={onRemove}>Remove</Button>}</div>{error && <small className="wizard-field-error" role="alert">{error}</small>}</div>
  </div>;
}

function VariantThumbnail({ imageUrl, imageFile, label }) {
  const [preview, setPreview] = React.useState('');
  React.useEffect(() => {
    if (!imageFile) { setPreview(''); return undefined; }
    const url = URL.createObjectURL(imageFile);
    setPreview(url);
    return () => URL.revokeObjectURL(url);
  }, [imageFile]);
  const src = preview || imageUrl;
  return <span className="wizard-stock-image">{src ? <img src={src} alt="" /> : <Icon name="inventory" />}{!src && <span className="visually-hidden">{label}</span>}</span>;
}

function VariantFields({ variant, index, multiple, onChange, onImageRemove, onImageFile, onRemove }) {
  const update = (field, value) => onChange({ ...variant, [field]: value });
  const updateList = (field, at, patch) => update(field, variant[field].map((item, itemIndex) => itemIndex === at ? { ...item, ...patch } : item));
  return <details className="wizard-variant-card" open={index === 0}>
    <summary><span className="wizard-variant-number">{index + 1}</span><span className="wizard-variant-summary"><strong>{variant.name || `Variant ${index + 1}`}</strong><small>{variant.unit || 'Unit'} · {variant.sku || 'No SKU'}</small></span>{multiple && <span className="wizard-variant-summary-actions" onClick={(event) => event.stopPropagation()}><Button variant="ghost" size="sm" onClick={onRemove}>Remove</Button></span>}</summary>
    <div className="wizard-variant-content">
      {multiple && <ImagePickerField label="Variant photo (optional)" imageUrl={variant.imageUrl} imageFile={variant.imageFile} onFile={onImageFile} onRemove={onImageRemove} />}
      <div className="form-grid">
        <TextField label={multiple ? 'Variant name' : 'Variant name (optional)'} placeholder="e.g. 1 liter, Family pack" value={variant.name} onChange={(event) => update('name', event.target.value)} required={multiple} />
        <TextField label="SKU" placeholder="Optional stock code" value={variant.sku} onChange={(event) => update('sku', event.target.value)} />
        <TextField label="Unit of measure" placeholder="piece, bottle, kg" value={variant.unit} onChange={(event) => update('unit', event.target.value)} required />
        <TextField label="Packaging" placeholder="Solo, pack, case" value={variant.packaging} onChange={(event) => update('packaging', event.target.value)} />
        <TextField label="Pieces per unit" type="number" min="1" step="1" value={variant.pcsPerUnit} onChange={(event) => update('pcsPerUnit', event.target.value)} />
        <TextField label="Selling price (₱)" type="number" min="0" step="0.01" value={variant.price} onChange={(event) => update('price', event.target.value)} required />
        <TextField label="Original price (₱)" type="number" min="0" step="0.01" value={variant.originalPrice} onChange={(event) => update('originalPrice', event.target.value)} />
        <TextField label="Cost price (₱)" type="number" min="0" step="0.01" value={variant.costPrice} onChange={(event) => update('costPrice', event.target.value)} />
      </div>
      <details className="wizard-advanced-options"><summary>Optional conditions and discounts</summary>
        <div className="wizard-subsection"><div className="wizard-subsection-heading"><strong>Conditions</strong><Button size="sm" variant="outline" icon="plus" onClick={() => update('conditions', [...variant.conditions, { name: '', additionalPrice: 0 }])}>Add condition</Button></div>
          {variant.conditions.map((condition, at) => <div className="wizard-inline-fields" key={`condition-${at}`}><TextField label="Condition" placeholder="e.g. Chilled" value={condition.name} onChange={(event) => updateList('conditions', at, { name: event.target.value })} /><TextField label="Extra price (₱)" type="number" min="0" step="0.01" value={condition.additionalPrice ?? 0} onChange={(event) => updateList('conditions', at, { additionalPrice: Number(event.target.value) || 0 })} /><Button variant="ghost" size="sm" onClick={() => update('conditions', variant.conditions.filter((_, i) => i !== at))}>Remove</Button></div>)}
        </div>
        <div className="wizard-subsection"><div className="wizard-subsection-heading"><strong>Discounts</strong><Button size="sm" variant="outline" icon="plus" onClick={() => update('discounts', [...variant.discounts, { title: '', type: '%', value: 0 }])}>Add discount</Button></div>
          {variant.discounts.map((discount, at) => <div className="wizard-inline-fields" key={`discount-${at}`}><TextField label="Discount name" placeholder="e.g. Senior" value={discount.title} onChange={(event) => updateList('discounts', at, { title: event.target.value })} /><SelectField label="Type" value={discount.type || '%'} onChange={(event) => updateList('discounts', at, { type: event.target.value })}><option value="%">Percent</option><option value="₱">Peso amount</option></SelectField><TextField label="Value" type="number" min="0" step="0.01" value={discount.value ?? 0} onChange={(event) => updateList('discounts', at, { value: Number(event.target.value) || 0 })} /><Button variant="ghost" size="sm" onClick={() => update('discounts', variant.discounts.filter((_, i) => i !== at))}>Remove</Button></div>)}
        </div>
      </details>
    </div>
  </details>;
}

export default function ProductWizard({ product, categories, lowStockThreshold, onClose, onSave, onAddCategory }) {
  const [form, setForm] = React.useState(() => productFromRow(product, categories, lowStockThreshold));
  const [step, setStep] = React.useState(0);
  const [saving, setSaving] = React.useState(false);
  const [error, setError] = React.useState('');
  const [batchTarget, setBatchTarget] = React.useState(-1);
  const [batchDraft, setBatchDraft] = React.useState(null);
  const [categoryOpen, setCategoryOpen] = React.useState(false);
  const [newCategory, setNewCategory] = React.useState('');
  const steps = ['Basic Info', 'Variants', 'Stocks'];
  const updateVariant = (index, updated) => setForm((current) => ({ ...current, variants: current.variants.map((item, at) => at === index ? updated : item) }));
  const beginBatch = (index) => {
    setBatchTarget(index);
    setBatchDraft({ batchNumber: '', qty: '', costPrice: String(form.variants[index].costPrice || ''), indicators: [] });
  };
  const saveBatch = () => {
    const qty = Number(batchDraft?.qty);
    if (!Number.isFinite(qty) || qty <= 0) { setError('Enter a stock quantity greater than zero.'); return; }
    const batch = { id: key('batch'), batchNumber: batchDraft.batchNumber.trim(), qty, costPrice: Number(batchDraft.costPrice) || 0, indicators: batchDraft.indicators.filter((indicator) => indicator.type !== 'N/A' && indicator.date), addedOn: localToday() };
    updateVariant(batchTarget, { ...form.variants[batchTarget], batches: [...form.variants[batchTarget].batches, batch] });
    setBatchTarget(-1);
    setBatchDraft(null);
    setError('');
  };
  const moveNext = () => {
    setError('');
    if (step === 0 && !form.name.trim()) { setError('Enter a product name to continue.'); return; }
    if (step === 1 && !form.variants.length) { setError('Add at least one variant.'); return; }
    if (step === 1 && form.variants.some((variant) => variant.price === '' || Number(variant.price) < 0)) { setError('Add a valid selling price for each variant.'); return; }
    setStep((current) => Math.min(2, current + 1));
  };
  const addCategory = async () => {
    const name = newCategory.trim();
    if (!name) return;
    try {
      await onAddCategory(name);
      setForm((current) => ({ ...current, category: name }));
      setNewCategory('');
      setCategoryOpen(false);
    } catch (reason) {
      setError(reason.message || 'Could not add this category.');
    }
  };
  const submit = async () => {
    setError('');
    setSaving(true);
    try {
      const productImageUrl = form.imageFile ? await uploadProductImage(form.imageFile, 'products') : form.imageUrl;
      const variants = await Promise.all(form.variants.map(async (variant) => ({
        id: variant.id || key('variant'),
        name: variant.name.trim() || form.name.trim(),
        sku: variant.sku.trim(),
        unit: variant.unit.trim() || 'piece',
        packaging: variant.packaging.trim(),
        pcsPerUnit: Math.max(1, Number(variant.pcsPerUnit) || 1),
        price: Number(variant.price) || 0,
        originalPrice: Number(variant.originalPrice || variant.price) || 0,
        costPrice: Number(variant.costPrice) || 0,
        hasDiscount: variant.discounts.length > 0,
        discounts: variant.discounts.filter((item) => item.title.trim()).map((item) => ({ ...item, title: item.title.trim(), value: Number(item.value) || 0 })),
        conditions: variant.conditions.filter((item) => item.name.trim()).map((item) => ({ ...item, name: item.name.trim(), additionalPrice: Number(item.additionalPrice) || 0 })),
        batches: variant.batches.map((batch) => ({ ...batch, qty: Number(batch.qty) || 0, costPrice: Number(batch.costPrice) || 0 })),
        imageUrl: variant.imageFile ? await uploadProductImage(variant.imageFile, 'variants') : (!form.hasVariants ? productImageUrl : variant.imageUrl),
      })));
      await onSave({ name: form.name.trim(), description: form.description.trim(), category: form.category || 'Uncategorized', hasVariants: form.hasVariants, imageUrl: productImageUrl, minStock: Number(form.minStock) || 0, variants });
    } catch (reason) {
      setError(reason.message || 'Could not save this product.');
    } finally {
      setSaving(false);
    }
  };

  return <Modal className="modal-product-wizard" title={product ? 'Edit product' : 'Add a product'} description={`${product ? 'Update' : 'Add'} the catalog in three quick steps.`} onClose={onClose} footer={<div className="wizard-footer"><span className="wizard-step-caption">Step {step + 1} of 3</span><div className="wizard-footer-actions">{step > 0 && <Button variant="outline" disabled={saving} onClick={() => { setError(''); setStep((current) => current - 1); }}>Back</Button>}{step < 2 ? <Button icon="arrow" onClick={moveNext}>Next: {steps[step + 1]}</Button> : <Button icon="check" disabled={saving} onClick={submit}>{saving ? 'Saving…' : product ? 'Save changes' : 'Add product'}</Button>}</div></div>}>
    <div className="wizard-stepper" aria-label="Product setup steps">{steps.map((label, index) => <button type="button" key={label} className={`wizard-step${index === step ? ' wizard-step-active' : ''}${index < step ? ' wizard-step-done' : ''}`} disabled={index >= step || saving} onClick={() => setStep(index)}><span>{index < step ? <Icon name="check" size={15} /> : index + 1}</span><strong>{label}</strong></button>)}</div>
    {error && <div className="wizard-error" role="alert">{error}</div>}
    <div className="wizard-step-content">
      {step === 0 && <div className="wizard-basic-step">
        <ImagePickerField label="Product photo" imageUrl={form.imageUrl} imageFile={form.imageFile} onFile={(imageFile) => setForm((current) => ({ ...current, imageFile }))} onRemove={() => setForm((current) => ({ ...current, imageUrl: '', imageFile: null }))} />
        <div className="form-grid"><TextField className="wizard-product-name" label="Product name" placeholder="e.g. Coca-Cola" value={form.name} onChange={(event) => setForm((current) => ({ ...current, name: event.target.value }))} required autoFocus /><TextAreaField className="wizard-product-description" label="Description (optional)" placeholder="Brief product description" rows="2" value={form.description} onChange={(event) => setForm((current) => ({ ...current, description: event.target.value }))} /><div className="field wizard-category-field"><span>Category</span><div className="wizard-category-controls"><select value={form.category} onChange={(event) => setForm((current) => ({ ...current, category: event.target.value }))}>{[...new Set([...categories, form.category].filter(Boolean))].map((category) => <option key={category} value={category}>{category}</option>)}</select><Button variant="outline" icon="plus" aria-expanded={categoryOpen} onClick={() => setCategoryOpen((current) => !current)}>Add category</Button></div>{categoryOpen && <div className="wizard-category-create"><TextField label="New category name" value={newCategory} onChange={(event) => setNewCategory(event.target.value)} autoFocus /><Button size="sm" icon="check" onClick={addCategory}>Save category</Button><Button size="sm" variant="ghost" onClick={() => setCategoryOpen(false)}>Cancel</Button></div>}</div><TextField label="Low stock alert at" type="number" min="0" value={form.minStock} onChange={(event) => setForm((current) => ({ ...current, minStock: event.target.value }))} /></div>
        <fieldset className="wizard-product-type"><legend>Product type</legend><label><input type="radio" name="product-type" checked={!form.hasVariants} onChange={() => setForm((current) => {
          const firstVariant = current.variants[0] || blankVariant();
          return {
            ...current,
            hasVariants: false,
            imageUrl: current.imageUrl || firstVariant.imageUrl || '',
            imageFile: current.imageFile || firstVariant.imageFile || null,
            variants: [{ ...firstVariant, imageFile: null }],
          };
        })} /><span><strong>Single product</strong><small>One size or option</small></span></label><label><input type="radio" name="product-type" checked={form.hasVariants} onChange={() => setForm((current) => ({ ...current, hasVariants: true }))} /><span><strong>Has variants</strong><small>Different sizes, types, or options</small></span></label></fieldset>
      </div>}
      {step === 1 && <div className="wizard-variants-step"><div className="wizard-step-intro"><div><h3>{form.hasVariants ? 'Set up your variants' : 'Product details'}</h3><p>{form.hasVariants ? 'Add each size, pack, or type sold separately.' : 'Set the price and unit for this product.'}</p></div>{form.hasVariants && <Button icon="plus" variant="outline" onClick={() => setForm((current) => ({ ...current, variants: [...current.variants, blankVariant()] }))}>Add variant</Button>}</div>
        {form.variants.map((variant, index) => <VariantFields key={variant.id} variant={variant} index={index} multiple={form.hasVariants} onChange={(updated) => updateVariant(index, updated)} onImageFile={(imageFile) => updateVariant(index, { ...variant, imageFile })} onImageRemove={() => updateVariant(index, { ...variant, imageUrl: '', imageFile: null })} onRemove={() => setForm((current) => ({ ...current, variants: current.variants.filter((_, at) => at !== index) }))} />)}
      </div>}
      {step === 2 && <div className="wizard-stocks-step"><div className="wizard-step-intro"><div><h3>Starting stock</h3><p>Add opening quantities and dates by stock batch. You can add more batches later.</p></div></div>{form.variants.map((variant, index) => <section className="wizard-stock-card" key={variant.id}><div className="wizard-stock-heading"><VariantThumbnail imageUrl={variant.imageUrl} imageFile={variant.imageFile} label={variant.name || form.name} /><div><strong>{variant.name || form.name || `Variant ${index + 1}`}</strong><small>{variant.unit} · ₱{Number(variant.price || 0).toFixed(2)}</small></div><strong className="wizard-stock-total">{variant.batches.reduce((sum, batch) => sum + (Number(batch.qty) || 0), 0)} {variant.unit}</strong></div>
          {variant.batches.map((batch, batchIndex) => <div className="wizard-batch-row" key={batch.id || batchIndex}><span><strong>{batch.qty} {variant.unit}</strong>{batch.batchNumber && <small>Batch {batch.batchNumber}</small>}{batch.indicators?.filter((item) => item.date).map((item, at) => <small key={`${item.type}-${at}`}>{item.type}: {item.date}</small>)}</span><Button variant="ghost" size="sm" onClick={() => updateVariant(index, { ...variant, batches: variant.batches.filter((_, at) => at !== batchIndex) })}>Remove</Button></div>)}
          {batchTarget === index && batchDraft ? <div className="wizard-batch-editor"><div className="form-grid"><TextField label="Quantity *" type="number" min="1" step="1" value={batchDraft.qty} onChange={(event) => setBatchDraft((current) => ({ ...current, qty: event.target.value }))} /><TextField label="Batch number (optional)" value={batchDraft.batchNumber} onChange={(event) => setBatchDraft((current) => ({ ...current, batchNumber: event.target.value }))} /><TextField label="Cost per unit (₱)" type="number" min="0" step="0.01" value={batchDraft.costPrice} onChange={(event) => setBatchDraft((current) => ({ ...current, costPrice: event.target.value }))} /></div><div className="wizard-subsection-heading"><strong>Product life indicators</strong><Button size="sm" variant="outline" icon="plus" onClick={() => setBatchDraft((current) => ({ ...current, indicators: [...current.indicators, { type: 'Expiry Date', date: '' }] }))}>Add date</Button></div>{batchDraft.indicators.map((indicator, at) => <div className="wizard-inline-fields" key={`indicator-${at}`}><SelectField label="Date type" value={indicator.type} onChange={(event) => setBatchDraft((current) => ({ ...current, indicators: current.indicators.map((item, i) => i === at ? { ...item, type: event.target.value } : item) }))}><option value="N/A">Choose a date type</option>{LIFE_INDICATORS.map((type) => <option key={type}>{type}</option>)}</SelectField><TextField label="Date" type="date" value={indicator.date} onChange={(event) => setBatchDraft((current) => ({ ...current, indicators: current.indicators.map((item, i) => i === at ? { ...item, date: event.target.value } : item) }))} /><Button variant="ghost" size="sm" onClick={() => setBatchDraft((current) => ({ ...current, indicators: current.indicators.filter((_, i) => i !== at) }))}>Remove</Button></div>)}<div className="wizard-batch-actions"><Button variant="outline" size="sm" onClick={() => { setBatchTarget(-1); setBatchDraft(null); }}>Cancel batch</Button><Button size="sm" icon="check" onClick={saveBatch}>Add batch</Button></div></div> : <Button className="wizard-add-batch" icon="plus" variant="outline" onClick={() => beginBatch(index)}>Add stock batch</Button>}
        </section>)}</div>}
    </div>
  </Modal>;
}
