import React from 'react';
import { ActivityIndicator, Pressable, Text, View } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useNetworkState } from 'expo-network';
import * as Network from 'expo-network';
import { onAuthStateChanged, signOut } from 'firebase/auth';
import { collection, deleteDoc, deleteField, doc, getDoc, getDocs, onSnapshot, query, runTransaction, setDoc, updateDoc, where, writeBatch } from 'firebase/firestore';
import AuthScreen from '../screens/AuthScreen';
import EmployeeSessionScreen from '../screens/EmployeeSessionScreen';
import { auth, db } from '../firebaseClient';
import {
  categoryFromDocument,
  changeProductExpiry,
  customerFromDocument,
  dateToString,
  deductProductVariant,
  employeeFromDocument,
  inventoryLogFromDocument,
  isoNow,
  newProductDocument,
  noteFromDocument,
  patchProductDocument,
  productRowsFromDocument,
  restockProductVariant,
  saleFromDocument,
  todayKey,
  utangFromDocument,
} from '../data/firebaseAdapters';
import { colors, useAppTheme, createThemeAwareStyles } from '../theme';

const emptyData = {
  products: [], sales: [], customers: [], categories: [], categoryRecords: [], employees: [], activityLogs: [], inventoryLogs: [], utangs: [], notes: [],
  settings: { storeName: 'My Store', lowStockThreshold: 12, currency: 'PHP' }, profile: null,
};
const StoreContext = React.createContext(null);

function firebaseMessage(error) {
  if (error?.code === 'permission-denied') return 'Firebase denied access. Check this account’s Firestore rules.';
  if (error?.code === 'unauthenticated') return 'Your session ended. Sign in again.';
  if (error?.code === 'unavailable') return 'StorePro is offline. Check your internet connection.';
  return error?.message || 'Could not sync this change.';
}

function removeLegacyEmployeePins(snapshot) {
  const documents = snapshot.docs.filter((entry) => Object.prototype.hasOwnProperty.call(entry.data(), 'pin'));
  for (let index = 0; index < documents.length; index += 450) {
    const batch = writeBatch(db);
    documents.slice(index, index + 450).forEach((entry) => batch.update(entry.ref, { pin: deleteField() }));
    batch.commit().catch(() => {});
  }
}

function dateMillis(value) {
  if (!value) return 0;
  if (typeof value.toMillis === 'function') return value.toMillis();
  if (typeof value.toDate === 'function') return value.toDate().getTime();
  const timestamp = value instanceof Date ? value.getTime() : Date.parse(String(value));
  return Number.isFinite(timestamp) ? timestamp : 0;
}

function compareDatesDescending(left, right) {
  return dateMillis(right) - dateMillis(left);
}

function getActor(activeEmployee, profile, user) {
  return {
    employeeId: activeEmployee?.id || 'owner',
    employeeName: activeEmployee?.name || profile?.ownerName || user?.email || 'Owner',
  };
}

function isNetworkFailure(error) {
  const code = String(error?.code || '').toLowerCase();
  return ['unavailable', 'deadline-exceeded', 'network-request-failed'].some((value) => code.includes(value))
    || /offline|network|timed out|unreachable/i.test(String(error?.message || ''));
}

const snapshotKey = (uid) => `storepro:${uid}:snapshot`;
const queueKey = (uid) => `storepro:${uid}:pending-operations`;

function projectedStock(row, operations) {
  let stock = Number(row.stock) || 0;
  for (const operation of operations) {
    if (operation.type === 'sale') {
      for (const item of operation.cart) {
        if (item.firestoreId === row.firestoreId && String(item.variantId) === String(row.variantId)) stock -= Number(item.qty) || 0;
      }
    } else if (operation.product?.firestoreId === row.firestoreId && String(operation.product.variantId) === String(row.variantId)) {
      stock += operation.type === 'restock' ? Number(operation.amount) || 0 : -(Number(operation.amount) || 0);
    }
  }
  return Math.max(0, stock);
}

function syncQueuedOperation(storeId, operation) {
  if (operation.type === 'sale') {
    const saleRef = doc(db, 'stores', storeId, 'sales', operation.sale.id);
    return runTransaction(db, async (transaction) => {
      const existingSale = await transaction.get(saleRef);
      if (existingSale.exists()) return;
      const grouped = new Map();
      operation.cart.forEach((item) => {
        const current = grouped.get(item.firestoreId) || { name: item.productName, variants: new Map() };
        current.variants.set(item.variantId, (current.variants.get(item.variantId) || 0) + item.qty);
        grouped.set(item.firestoreId, current);
      });
      const productReads = await Promise.all([...grouped].map(async ([id, entry]) => {
        const ref = doc(db, 'stores', storeId, 'products', id);
        const snapshot = await transaction.get(ref);
        if (!snapshot.exists()) throw new Error(`${entry.name} is no longer in the catalog.`);
        let updated = { ...snapshot.data(), id: snapshot.id };
        for (const [variantId, qty] of entry.variants) updated = deductProductVariant(updated, variantId, qty, storeId);
        return { ref, value: { ...updated, id: snapshot.id } };
      }));
      const customerRef = operation.customer ? doc(db, 'stores', storeId, 'customers', operation.customer.id) : null;
      const customerSnapshot = customerRef ? await transaction.get(customerRef) : null;
      productReads.forEach(({ ref, value }) => transaction.set(ref, value));
      if (customerRef) {
        const raw = customerSnapshot?.exists() ? customerSnapshot.data() : null;
        const customer = operation.customer;
        transaction.set(customerRef, {
          ...(raw || {}), id: customer.id, storeId, name: customer.name,
          phone: customer.phone || raw?.phone || '', address: customer.address || raw?.address || '',
          notes: raw?.notes || customer.notes || '', visits: Number(raw?.visits ?? customer.visits) || 0,
          totalPurchases: (Number(raw?.totalPurchases ?? customer.spent) || 0) + operation.sale.total,
          createdAt: raw?.createdAt || customer.createdAt || operation.createdAt,
          updatedAt: operation.createdAt,
        });
      }
      transaction.set(saleRef, operation.sale);
      if (operation.activity) transaction.set(doc(db, 'stores', storeId, 'activity_logs', operation.activity.id), operation.activity);
      operation.inventoryLogs.forEach((log) => transaction.set(doc(db, 'stores', storeId, 'inventory_logs', log.id), log));
      if (operation.utang) transaction.set(doc(db, 'stores', storeId, 'utang', operation.utang.id), operation.utang);
    });
  }
  const logRef = doc(db, 'stores', storeId, 'inventory_logs', operation.log.id);
  return runTransaction(db, async (transaction) => {
    if ((await transaction.get(logRef)).exists()) return;
    const productRef = doc(db, 'stores', storeId, 'products', operation.product.firestoreId);
    const snapshot = await transaction.get(productRef);
    if (!snapshot.exists()) throw new Error(`${operation.product.name} is no longer in the catalog.`);
    const raw = { ...snapshot.data(), id: snapshot.id };
    const updated = operation.type === 'restock'
      ? restockProductVariant(raw, operation.product.variantId, operation.amount, storeId, operation.options)
      : deductProductVariant(raw, operation.product.variantId, operation.amount, storeId);
    transaction.set(productRef, { ...updated, id: snapshot.id });
    transaction.set(logRef, operation.log);
  });
}

function withCustomerMetrics(customers, sales) {
  return customers.map((customer) => {
    const purchases = sales.filter((sale) => !['cancelled', 'refunded'].includes(sale.status) && (sale.customerId === customer.id || (!sale.customerId && sale.customer === customer.name)));
    return {
      ...customer,
      visits: Math.max(Number(customer.__raw?.visits) || 0, purchases.length),
      spent: Math.max(customer.spent || 0, purchases.reduce((sum, sale) => sum + sale.total, 0)),
    };
  }).sort((a, b) => a.name.localeCompare(b.name));
}

export function StoreProvider({ children }) {
  useAppTheme();
  const networkState = useNetworkState();
  const networkReachable = networkState?.isInternetReachable ?? networkState?.isConnected ?? true;
  const [user, setUser] = React.useState(null);
  const activeStoreId = user?.uid;
  const [authReady, setAuthReady] = React.useState(false);
  const [data, setData] = React.useState(emptyData);
  const [ready, setReady] = React.useState(false);
  const [error, setError] = React.useState('');
  const [activeEmployee, setActiveEmployee] = React.useState(null);
  const [hydratedUid, setHydratedUid] = React.useState('');
  const [pendingOps, setPendingOps] = React.useState([]);
  const [backendOffline, setBackendOffline] = React.useState(false);
  const pendingOpsRef = React.useRef([]);
  const queueWriteRef = React.useRef(Promise.resolve());
  const syncingQueueRef = React.useRef(false);
  const selectEmployee = React.useCallback((employee) => setActiveEmployee({ id: employee.id, name: employee.name }), []);
  const switchEmployee = React.useCallback(() => setActiveEmployee(null), []);

  React.useEffect(() => onAuthStateChanged(auth, (currentUser) => {
    setUser(currentUser);
    setHydratedUid('');
    setPendingOps([]);
    pendingOpsRef.current = [];
    setData(emptyData);
    setReady(false);
    setError('');
    setBackendOffline(false);
    setActiveEmployee(null);
    setAuthReady(true);
  }), []);

  React.useEffect(() => {
    const storeId = activeStoreId;
    if (!storeId) return undefined;
    let active = true;
    AsyncStorage.multiGet([snapshotKey(storeId), queueKey(storeId)]).then((entries) => {
      if (!active) return;
      const [snapshotValue, queueValue] = entries.map((entry) => entry?.[1] || '');
      try {
        const cached = JSON.parse(snapshotValue || 'null');
        if (cached && Array.isArray(cached.products)) {
          setData({ ...emptyData, ...cached });
          setReady(true);
        }
      } catch {}
      try {
        const queue = JSON.parse(queueValue || '[]');
        const safeQueue = Array.isArray(queue) ? queue : [];
        pendingOpsRef.current = safeQueue;
        setPendingOps(safeQueue);
      } catch {
        pendingOpsRef.current = [];
        setPendingOps([]);
      }
      setHydratedUid(storeId);
    }).catch(() => {
      if (active) setHydratedUid(storeId);
    });
    return () => { active = false; };
  }, [activeStoreId, user?.email]);

  React.useEffect(() => {
    const subscription = Network.addNetworkStateListener((state) => {
      if (state.isInternetReachable ?? state.isConnected) setBackendOffline(false);
    });
    return () => subscription.remove();
  }, []);

  React.useEffect(() => {
    if (!user?.uid || hydratedUid !== user.uid) return;
    AsyncStorage.setItem(snapshotKey(user.uid), JSON.stringify(data, (_key, value) => (
      value && typeof value.toDate === 'function' ? value.toDate().toISOString() : value
    ))).catch(() => {});
  }, [data, user?.uid, hydratedUid]);

  React.useEffect(() => {
    if (!user?.uid) return undefined;
    if (hydratedUid !== user.uid) return undefined;

    const storePath = ['stores', user.uid];
    const required = ['profile', 'products', 'sales', 'customers', 'categories', 'employees', 'activity_logs', 'inventory_logs', 'utang', 'notes'];
    const completed = new Set();
    const failures = new Map();
    let syncTimedOut = false;
    let syncTimeout;
    const finishOne = (key) => {
      completed.add(key);
      if (completed.size === required.length) {
        clearTimeout(syncTimeout);
        syncTimedOut = false;
        setReady(true);
        setError(failures.values().next().value || '');
      }
    };
    const markHealthy = (key) => {
      failures.delete(key);
      setError(failures.values().next().value || (syncTimedOut ? 'Some store data is still loading. Check your connection and Firestore access.' : ''));
    };
    const markFailed = (key, reason) => {
      if (isNetworkFailure(reason)) setBackendOffline(true);
      failures.set(key, `${key}: ${firebaseMessage(reason)}`);
      setError(failures.values().next().value || '');
    };
    const listen = (name, mapper, apply) => onSnapshot(
      collection(db, ...storePath, name),
      (snapshot) => {
        if (!snapshot.metadata?.fromCache) setBackendOffline(false);
        apply(snapshot.docs.map((entry) => mapper(entry.id, entry.data())), snapshot);
        markHealthy(name);
        finishOne(name);
      },
      (reason) => { markFailed(name, reason); finishOne(name); },
    );

    const unsubscribers = [
      onSnapshot(doc(db, ...storePath), (snapshot) => {
        if (!snapshot.metadata?.fromCache) setBackendOffline(false);
        if (!snapshot.exists()) {
          failures.set('profile', 'This account has no StorePro store profile yet. Create or restore the store profile, then sign in again.');
          setError(failures.values().next().value || '');
          setData((current) => ({ ...current, profile: null }));
        } else {
          const profile = snapshot.data();
          const ownerName = [profile.firstName, profile.lastName].filter(Boolean).join(' ');
          setData((current) => ({
            ...current,
            profile: { ...profile, id: snapshot.id, ownerName: ownerName || user.email || 'Store owner' },
            settings: {
              storeName: profile.storeName || 'My Store',
              lowStockThreshold: Number.isFinite(Number(profile.lowStockThreshold)) ? Number(profile.lowStockThreshold) : 12,
              currency: profile.currency || 'PHP',
              trackActivity: profile.trackActivity !== false,
              notificationsEnabled: profile.notificationsEnabled !== false,
            },
          }));
          markHealthy('profile');
        }
        finishOne('profile');
      }, (reason) => { markFailed('profile', reason); finishOne('profile'); }),
      listen('products', (id, raw) => ({ id, raw }), (records) => setData((current) => ({
        ...current,
        products: records.flatMap((record) => productRowsFromDocument(record.id, record.raw)),
      }))),
      listen('sales', saleFromDocument, (records) => setData((current) => {
        const sales = records.sort((a, b) => compareDatesDescending(a.timestamp || a.date, b.timestamp || b.date));
        return { ...current, sales, customers: withCustomerMetrics(current.customers, sales) };
      })),
      listen('customers', customerFromDocument, (records) => setData((current) => ({
        ...current,
        customers: withCustomerMetrics(records, current.sales),
      }))),
      listen('categories', categoryFromDocument, (records) => setData((current) => ({
        ...current,
        categoryRecords: records,
        categories: records.map((item) => item.name).filter(Boolean).sort((a, b) => a.localeCompare(b)),
      }))),
      listen('employees', employeeFromDocument, (records, snapshot) => {
        removeLegacyEmployeePins(snapshot);
        setData((current) => ({
          ...current, employees: records.sort((a, b) => a.name.localeCompare(b.name)),
        }));
      }),
      listen('activity_logs', (id, raw) => ({ id, ...raw, timestamp: dateToString(raw.timestamp) }), (records) => setData((current) => ({
        ...current, activityLogs: records.sort((a, b) => compareDatesDescending(a.timestamp, b.timestamp)),
      }))),
      listen('inventory_logs', inventoryLogFromDocument, (records) => setData((current) => ({
        ...current, inventoryLogs: records.sort((a, b) => compareDatesDescending(a.date, b.date)),
      }))),
      listen('utang', utangFromDocument, (records) => setData((current) => ({
        ...current, utangs: records.sort((a, b) => compareDatesDescending(a.createdAt, b.createdAt)),
      }))),
      listen('notes', noteFromDocument, (records) => setData((current) => ({
        ...current, notes: records.sort((a, b) => compareDatesDescending(a.createdAt, b.createdAt)),
      }))),
    ];
    syncTimeout = setTimeout(() => {
      if (completed.size === required.length) return;
      syncTimedOut = true;
      setReady(true);
      const waitingFor = required.filter((key) => !completed.has(key));
      setError(`StorePro opened, but these sections are still syncing: ${waitingFor.join(', ')}. Check your connection and Firestore access.`);
    }, 10000);
    return () => {
      clearTimeout(syncTimeout);
      unsubscribers.forEach((unsubscribe) => unsubscribe());
    };
  }, [user?.uid, user?.email, hydratedUid]);

  const persistPendingOps = React.useCallback((update) => {
    const task = queueWriteRef.current.then(async () => {
      const current = pendingOpsRef.current;
      const next = typeof update === 'function' ? update(current) : update;
      try { await AsyncStorage.setItem(queueKey(activeStoreId), JSON.stringify(next)); }
      catch { throw new Error('This device could not save the offline change. Check its available storage before continuing.'); }
      pendingOpsRef.current = next;
      setPendingOps(next);
      return next;
    });
    queueWriteRef.current = task.catch(() => {});
    return task;
  }, [activeStoreId]);

  const enqueueOfflineOperation = React.useCallback(async (operation) => {
    await persistPendingOps((current) => [...current, operation]);
  }, [persistPendingOps]);

  React.useEffect(() => {
    if (!user?.uid || hydratedUid !== user.uid || !networkReachable || backendOffline || syncingQueueRef.current) return;
    if (!pendingOpsRef.current.some((operation) => operation.status !== 'needs-review')) return;
    syncingQueueRef.current = true;
    (async () => {
      try {
        while (true) {
          const operation = pendingOpsRef.current.find((item) => item.status !== 'needs-review');
          if (!operation) break;
          try {
            await syncQueuedOperation(user.uid, operation);
            await persistPendingOps((current) => current.filter((item) => item.id !== operation.id));
            setError('');
          } catch (reason) {
            if (isNetworkFailure(reason)) {
              setBackendOffline(true);
              break;
            }
            await persistPendingOps((current) => current.map((item) => item.id === operation.id
              ? { ...item, status: 'needs-review', error: reason?.message || 'This change needs review before it can sync.' }
              : item));
            setError(`A saved offline change needs review: ${reason?.message || 'the stock or catalog changed while this device was offline.'}`);
          }
        }
      } finally {
        syncingQueueRef.current = false;
      }
    })();
  }, [user?.uid, hydratedUid, networkReachable, backendOffline, pendingOps, persistPendingOps]);

  const commitOrQueueOffline = React.useCallback(async (operation) => {
    if (!networkReachable || backendOffline) {
      await enqueueOfflineOperation(operation);
      return false;
    }
    try {
      await syncQueuedOperation(activeStoreId, operation);
      return true;
    } catch (reason) {
      if (!isNetworkFailure(reason)) throw reason;
      setBackendOffline(true);
      await enqueueOfflineOperation(operation);
      return false;
    }
  }, [activeStoreId, networkReachable, backendOffline, enqueueOfflineOperation]);

  const runWrite = React.useCallback(async (operation) => {
    try {
      return await operation();
    } catch (reason) {
      const message = firebaseMessage(reason);
      setError(message);
      throw new Error(message);
    }
  }, []);

  const addProduct = React.useCallback((product) => runWrite(async () => {
    const actor = getActor(activeEmployee, data.profile, user);
    const productRef = doc(collection(db, 'stores', user.uid, 'products'));
    const activityRef = doc(collection(db, 'stores', user.uid, 'activity_logs'));
    const category = data.categoryRecords.find((item) => item.name === product.category);
    const batch = writeBatch(db);
    let categoryId = category?.id || '';
    if (!categoryId && product.category) {
      const categoryRef = doc(collection(db, 'stores', user.uid, 'categories'));
      categoryId = categoryRef.id;
      batch.set(categoryRef, { id: categoryRef.id, storeId: user.uid, name: product.category, details: '', iconIndex: 0, colorIndex: 0, imageUrl: '', updatedAt: isoNow() });
    }
    const now = isoNow();
    batch.set(productRef, newProductDocument(product, productRef.id, user.uid, categoryId));
    if (data.profile?.trackActivity !== false) batch.set(activityRef, { id: activityRef.id, storeId: user.uid, ...actor, action: 'add_product', targetType: 'product', targetId: productRef.id, targetName: product.name, timestamp: now, details: { productName: product.name } });
    await batch.commit();
    return { id: productRef.id, name: product.name };
  }), [user, data.categoryRecords, data.profile, activeEmployee, runWrite]);

  const updateProduct = React.useCallback((productId, product) => runWrite(async () => {
    const actor = getActor(activeEmployee, data.profile, user);
    const row = data.products.find((item) => item.id === productId);
    if (!row) throw new Error('This product changed on another device. Refresh and try again.');
    let categoryId = data.categoryRecords.find((item) => item.name === product.category)?.id || '';
    if (!categoryId && product.category && product.category !== 'Uncategorized') {
      const categoryRef = doc(collection(db, 'stores', user.uid, 'categories'));
      categoryId = categoryRef.id;
      await setDoc(categoryRef, { id: categoryRef.id, storeId: user.uid, name: product.category, details: '', iconIndex: 0, colorIndex: 0, imageUrl: '', updatedAt: isoNow() });
    }
    const ref = doc(db, 'stores', user.uid, 'products', row.firestoreId);
    const activityRef = doc(collection(db, 'stores', user.uid, 'activity_logs'));
    await runTransaction(db, async (transaction) => {
      const snapshot = await transaction.get(ref);
      if (!snapshot.exists()) throw new Error('This product no longer exists.');
      const updated = patchProductDocument({ ...snapshot.data(), id: snapshot.id }, product, row.variantId, user.uid, categoryId);
      updated.id = snapshot.id;
      transaction.set(ref, updated);
      if (data.profile?.trackActivity !== false) transaction.set(activityRef, { id: activityRef.id, storeId: user.uid, ...actor, action: 'edit_product', targetType: 'product', targetId: row.firestoreId, targetName: product.name || row.name, timestamp: isoNow(), details: { productName: product.name || row.name } });
    });
  }), [data.products, data.categoryRecords, data.profile, activeEmployee, user, runWrite]);

  const deleteProduct = React.useCallback((productId) => runWrite(async () => {
    const row = data.products.find((item) => item.id === productId);
    if (!row) throw new Error('This product changed on another device. Refresh and try again.');
    const ref = doc(db, 'stores', user.uid, 'products', row.firestoreId);
    const activityRef = doc(collection(db, 'stores', user.uid, 'activity_logs'));
    const actor = getActor(activeEmployee, data.profile, user);
    await runTransaction(db, async (transaction) => {
      const snapshot = await transaction.get(ref);
      if (!snapshot.exists()) throw new Error('This product no longer exists.');
      const raw = snapshot.data();
      const variants = Array.isArray(raw.variants) ? raw.variants : [];
      if (variants.length > 1) transaction.update(ref, { variants: variants.filter((variant) => String(variant.id) !== String(row.variantId)), updatedAt: isoNow() });
      else transaction.delete(ref);
      if (data.profile?.trackActivity !== false) transaction.set(activityRef, {
        id: activityRef.id, storeId: user.uid, ...actor, action: 'delete_product', targetType: 'product',
        targetId: row.firestoreId, targetName: `${raw.name || row.name}${row.variantName ? ` · ${row.variantName}` : ''}`, timestamp: isoNow(),
        details: { productName: raw.name || row.name, variantName: row.variantName || '' },
      });
    });
  }), [data.products, data.profile, activeEmployee, user, runWrite]);

  const restock = React.useCallback((productId, amount, options = {}) => runWrite(async () => {
    const actor = getActor(activeEmployee, data.profile, user);
    const row = data.products.find((item) => item.id === productId);
    if (!row) throw new Error('This product changed on another device. Refresh and try again.');
    const logRef = doc(collection(db, 'stores', user.uid, 'inventory_logs'));
    const quantity = Math.floor(Number(amount) || 0);
    if (quantity <= 0) throw new Error('Enter a quantity greater than zero.');
    const now = isoNow();
    await commitOrQueueOffline({
      id: logRef.id, type: 'restock', status: 'pending', createdAt: now,
      product: { firestoreId: row.firestoreId, variantId: row.variantId, name: row.name, unit: row.unit },
      amount: quantity, options: { ...options },
      log: {
        id: logRef.id, storeId: user.uid, productId: row.firestoreId, productName: row.name,
        variantId: row.variantId, variantName: row.variantName || row.unit, type: 'add', qty: quantity,
        costPrice: options.costPrice === '' || options.costPrice === undefined ? Number(row.cost) || 0 : Math.max(0, Number(options.costPrice) || 0),
        reason: 'replenishment', ...actor, date: todayKey(), updatedAt: now,
      },
    });
  }), [data.products, data.profile, activeEmployee, user, runWrite, commitOrQueueOffline]);

  const removeStock = React.useCallback((productId, amount, reason = 'adjustment') => runWrite(async () => {
    const actor = getActor(activeEmployee, data.profile, user);
    const row = data.products.find((item) => item.id === productId);
    const quantity = Math.floor(Number(amount) || 0);
    if (!row) throw new Error('This product changed on another device. Refresh and try again.');
    if (quantity <= 0) throw new Error('Enter a quantity greater than zero.');
    const available = projectedStock(row, pendingOpsRef.current);
    if (quantity > available) throw new Error(`Cannot remove more than ${available} ${row.unit}.`);
    const logRef = doc(collection(db, 'stores', user.uid, 'inventory_logs'));
    const now = isoNow();
    await commitOrQueueOffline({
      id: logRef.id, type: 'removeStock', status: 'pending', createdAt: now,
      product: { firestoreId: row.firestoreId, variantId: row.variantId, name: row.name, unit: row.unit }, amount: quantity,
      log: {
        id: logRef.id, storeId: user.uid, productId: row.firestoreId, productName: row.name,
        variantId: row.variantId, variantName: row.variantName || row.unit, type: 'remove', qty: -quantity,
        costPrice: Number(row.cost) || 0, reason, ...actor, date: todayKey(), updatedAt: now,
      },
    });
  }), [data.products, data.profile, activeEmployee, user, runWrite, commitOrQueueOffline]);

  const refundSale = React.useCallback((saleId, reason = 'Customer refund') => runWrite(async () => {
    const storeId = user.uid;
    const actor = getActor(activeEmployee, data.profile, user);
    const saleRef = doc(db, 'stores', storeId, 'sales', saleId);
    const timestamp = isoNow();
    await runTransaction(db, async (transaction) => {
      const saleSnapshot = await transaction.get(saleRef);
      if (!saleSnapshot.exists()) throw new Error('This sale no longer exists.');
      const rawSale = saleSnapshot.data();
      if (rawSale.status === 'refunded') return;
      const sale = saleFromDocument(saleSnapshot.id, rawSale);
      const activityRef = doc(collection(db, 'stores', storeId, 'activity_logs'));
      const customerQuery = !sale.customerId && sale.customer && sale.customer !== 'Walk-in customer'
        ? query(collection(db, 'stores', storeId, 'customers'), where('name', '==', sale.customer))
        : null;
      const [customerMatches, linkedUtangs] = await Promise.all([
        customerQuery ? getDocs(customerQuery) : Promise.resolve(null),
        getDocs(query(collection(db, 'stores', storeId, 'utang'), where('saleId', '==', saleId))),
      ]);
      const customerRef = sale.customerId
        ? doc(db, 'stores', storeId, 'customers', sale.customerId)
        : customerMatches?.docs[0]?.ref || null;
      const productIds = [...new Set(sale.items.map((item) => item.productId).filter(Boolean))];
      const productRefs = productIds.map((id) => doc(db, 'stores', storeId, 'products', id));
      const productSnapshots = await Promise.all(productRefs.map((ref) => transaction.get(ref)));
      const customerSnapshot = customerRef ? await transaction.get(customerRef) : null;
      const utangSnapshots = await Promise.all(linkedUtangs.docs.map((snapshot) => transaction.get(snapshot.ref)));
      const updatedProducts = new Map();
      productSnapshots.forEach((snapshot) => {
        if (snapshot.exists()) updatedProducts.set(snapshot.id, { ...snapshot.data(), id: snapshot.id });
      });
      for (const item of sale.items) {
        if (!updatedProducts.has(item.productId) || item.qty <= 0) continue;
        updatedProducts.set(item.productId, restockProductVariant(
          updatedProducts.get(item.productId), item.variantId, item.qty, storeId, { costPrice: item.cost },
        ));
      }
      const customerDocument = customerSnapshot?.exists()
        ? { ref: customerRef, raw: customerSnapshot.data() }
        : null;
      if (customerDocument) {
        transaction.set(customerDocument.ref, {
          ...customerDocument.raw,
          totalPurchases: Math.max(0, (Number(customerDocument.raw.totalPurchases) || 0) - sale.total),
          updatedAt: timestamp,
        });
      }
      utangSnapshots.filter((utangSnapshot) => utangSnapshot.exists()).forEach((utangSnapshot) => {
        const rawUtang = utangSnapshot.data();
        transaction.set(utangSnapshot.ref, {
          ...rawUtang,
          totalAmount: 0,
          amountPaid: 0,
          status: 'paid',
          notes: [rawUtang.notes, `Linked sale was refunded on ${timestamp}`].filter(Boolean).join('\n'),
          updatedAt: timestamp,
        });
      });
      updatedProducts.forEach((product, id) => {
        const ref = productRefs[productIds.indexOf(id)];
        transaction.set(ref, { ...product, id });
      });
      sale.items.forEach((item) => {
        if (!item.productId || item.qty <= 0) return;
        const logRef = doc(collection(db, 'stores', storeId, 'inventory_logs'));
        transaction.set(logRef, {
          id: logRef.id, storeId, productId: item.productId, productName: item.name,
          variantId: item.variantId, variantName: item.variantName, type: 'return', qty: item.qty,
          costPrice: item.cost, reason, ...actor,
          date: todayKey(), updatedAt: timestamp,
        });
      });
      transaction.set(saleRef, {
        ...rawSale,
        status: 'refunded', amountPaid: 0, change: 0,
        notes: [rawSale.notes, `Refund reason: ${reason}`].filter(Boolean).join('\n'), updatedAt: timestamp,
        editHistory: [...(Array.isArray(rawSale.editHistory) ? rawSale.editHistory : []), {
          type: 'refund', reason, at: timestamp, actorId: actor.employeeId,
          actorName: actor.employeeName, before: rawSale,
        }],
      });
      if (data.profile?.trackActivity !== false) transaction.set(activityRef, {
        id: activityRef.id, storeId, ...actor,
        action: 'refund_sale', targetType: 'sale', targetId: sale.id, targetName: sale.customer,
        timestamp, details: { customerName: sale.customer, grandTotal: sale.total, reason },
      });
    });
  }), [data.profile, activeEmployee, user, runWrite]);

  const deleteSale = React.useCallback((saleId) => runWrite(async () => {
    const ref = doc(db, 'stores', user.uid, 'sales', saleId);
    const snapshot = await getDoc(ref);
    if (!snapshot.exists()) return;
    if (snapshot.data().status !== 'refunded') await refundSale(saleId, 'Sale record deleted');
    await deleteDoc(ref);
  }), [user, refundSale, runWrite]);

  const completeSale = React.useCallback((cart, payment, options = {}) => runWrite(async () => {
    const storeId = user.uid;
    const actor = getActor(activeEmployee, data.profile, user);
    const saleRef = doc(collection(db, 'stores', storeId, 'sales'));
    const activityRef = doc(collection(db, 'stores', storeId, 'activity_logs'));
    const customerName = String(options.customerName || '').trim();
    const paymentType = payment === 'Utang' ? 'utang' : ['Multi', 'Mixed'].includes(payment) ? 'multi' : 'cash';
    const existingCustomer = data.customers.find((item) => item.name.toLowerCase() === customerName.toLowerCase());
    const customerRef = customerName
      ? (existingCustomer
        ? doc(db, 'stores', storeId, 'customers', existingCustomer.id)
        : doc(collection(db, 'stores', storeId, 'customers')))
      : null;
    const selectedCustomerId = existingCustomer?.id || customerRef?.id || '';
    const inventoryLogRefs = cart.map(() => doc(collection(db, 'stores', storeId, 'inventory_logs')));
    const timestamp = isoNow();
    const items = cart.map(({ product, qty, discount = 0 }) => {
      const price = Number(product.price) || 0;
      return {
        productId: product.firestoreId, productName: product.name,
        variantId: product.variantId, variantName: product.variantName || product.unit,
        conditionName: '', qty, price, costPrice: Number(product.cost) || 0,
        discount: Math.min(price * qty, Math.max(0, Number(discount) || 0)),
      };
    });
    const subtotal = items.reduce((sum, item) => sum + item.price * item.qty, 0);
    const totalDiscount = items.reduce((sum, item) => sum + item.discount, 0);
    const total = Math.max(0, subtotal - totalDiscount);
    const amountPaid = paymentType === 'utang' ? 0 : Math.max(0, Number(options.amountPaid ?? total) || 0);
    if (paymentType === 'cash' && amountPaid < total) throw new Error('Cash payment must cover the sale total. Choose Multi to record a balance.');
    if ((paymentType === 'utang' || (paymentType === 'multi' && amountPaid < total)) && !customerName) throw new Error('Enter the customer name for an Utang or unpaid balance.');
    const hasBalance = amountPaid < total;
    const utangRef = hasBalance ? doc(collection(db, 'stores', storeId, 'utang')) : null;
    const sale = {
      id: saleRef.id, storeId, customerId: selectedCustomerId, customerName: customerName || 'Walk-in customer', ...actor,
      items, subtotal, totalDiscount, total,
      amountPaid, change: Math.max(0, amountPaid - total),
      paymentType, status: hasBalance ? 'partial' : 'completed',
      notes: payment === 'GCash' ? 'Paid through GCash' : '', date: todayKey(), timestamp, updatedAt: timestamp, editHistory: [],
    };

    const requestedByVariant = new Map();
    cart.forEach(({ product, qty }) => {
      const key = `${product.firestoreId}::${product.variantId}`;
      requestedByVariant.set(key, (requestedByVariant.get(key) || 0) + Number(qty));
    });
    for (const [key, quantity] of requestedByVariant) {
      const row = data.products.find((item) => `${item.firestoreId}::${item.variantId}` === key);
      const available = row ? projectedStock(row, pendingOpsRef.current) : 0;
      if (!row || quantity > available) throw new Error(`Not enough ${row?.unit || 'stock'} for ${row?.name || 'this item'}. ${available} available.`);
    }
    const operation = {
      id: sale.id, type: 'sale', status: 'pending', createdAt: timestamp, sale,
      cart: cart.map(({ product, qty }) => ({
        firestoreId: product.firestoreId, productName: product.name, variantId: product.variantId,
        variantName: product.variantName || product.unit, qty: Number(qty),
      })),
      customer: customerRef ? {
        id: customerRef.id, name: customerName,
        phone: String(options.customerPhone || '').trim() || existingCustomer?.phone || '',
        address: String(options.customerAddress || '').trim() || existingCustomer?.address || '',
        notes: existingCustomer?.notes || '', visits: existingCustomer?.visits || 0,
        spent: existingCustomer?.spent || 0, createdAt: timestamp,
      } : null,
      activity: data.profile?.trackActivity !== false ? {
        id: activityRef.id, storeId, ...actor, action: 'new_sale', targetType: 'sale',
        targetId: saleRef.id, targetName: sale.customerName, timestamp,
        details: { customerName: sale.customerName, grandTotal: total, cash: Math.min(amountPaid, total), utang: Math.max(0, total - amountPaid), subtotal, discount: totalDiscount, paymentType: sale.paymentType },
      } : null,
      inventoryLogs: cart.map(({ product, qty }, index) => ({
        id: inventoryLogRefs[index].id, storeId, productId: product.firestoreId, productName: product.name,
        variantId: product.variantId, variantName: product.variantName || product.unit, type: 'sale', qty: -Number(qty),
        costPrice: Number(product.cost) || 0, reason: 'sale', ...actor, date: todayKey(), updatedAt: timestamp,
      })),
      utang: utangRef ? {
        id: utangRef.id, storeId, customerId: selectedCustomerId, customerName: sale.customerName,
        customerPhone: String(options.customerPhone || '').trim() || existingCustomer?.phone || '',
        saleId: saleRef.id, items, totalAmount: total, amountPaid: Math.min(amountPaid, total),
        startDate: todayKey(), dueDate: '',
        status: amountPaid >= total ? 'paid' : amountPaid > 0 ? 'partial' : 'pending',
        payments: [], notes: 'Created from mobile sale', updatedAt: timestamp,
      } : null,
    };
    const synced = await commitOrQueueOffline(operation);
    return { ...saleFromDocument(sale.id, sale), offlinePending: !synced };
  }), [user, data.profile, data.customers, data.products, activeEmployee, runWrite, commitOrQueueOffline]);

  const addCategory = React.useCallback((name) => runWrite(async () => {
    const ref = doc(collection(db, 'stores', user.uid, 'categories'));
    await setDoc(ref, { id: ref.id, storeId: user.uid, name, details: '', iconIndex: 0, colorIndex: 0, imageUrl: '', updatedAt: isoNow() });
  }), [user, runWrite]);

  const setProductExpiryDate = React.useCallback((productId, expiryDate) => runWrite(async () => {
    const row = data.products.find((item) => item.id === productId);
    if (!row) throw new Error('This product changed on another device. Refresh and try again.');
    const ref = doc(db, 'stores', user.uid, 'products', row.firestoreId);
    await runTransaction(db, async (transaction) => {
      const snapshot = await transaction.get(ref);
      if (!snapshot.exists()) throw new Error('This product no longer exists.');
      const updated = changeProductExpiry({ ...snapshot.data(), id: snapshot.id }, row.variantId, expiryDate, user.uid);
      transaction.set(ref, { ...updated, id: snapshot.id });
    });
  }), [data.products, user, runWrite]);

  const addUtang = React.useCallback((utang) => runWrite(async () => {
    const ref = doc(collection(db, 'stores', user.uid, 'utang'));
    const customer = data.customers.find((item) => item.name === utang.customer);
    await setDoc(ref, {
      id: ref.id, storeId: user.uid, customerId: customer?.id || '', customerName: utang.customer.trim(),
      customerPhone: customer?.phone || '', saleId: '', items: [], totalAmount: Number(utang.amount) || 0,
      amountPaid: 0, startDate: todayKey(), dueDate: utang.dueDate || '', status: 'pending', payments: [],
      notes: utang.note || '', updatedAt: isoNow(),
    });
  }), [user, data.customers, runWrite]);

  const recordUtangPayment = React.useCallback((utangId, amount) => runWrite(async () => {
    const actor = getActor(activeEmployee, data.profile, user);
    const ref = doc(db, 'stores', user.uid, 'utang', utangId);
    await runTransaction(db, async (transaction) => {
      const snapshot = await transaction.get(ref);
      if (!snapshot.exists()) throw new Error('This balance no longer exists.');
      const raw = snapshot.data();
      const total = Number(raw.totalAmount) || 0;
      const amountPaid = Math.min(total, (Number(raw.amountPaid) || 0) + Number(amount));
      const timestamp = isoNow();
      const payments = Array.isArray(raw.payments) ? raw.payments : [];
      transaction.update(ref, {
        amountPaid,
        status: amountPaid >= total ? 'paid' : amountPaid > 0 ? 'partial' : 'pending',
        payments: [...payments, { id: `payment-${Date.now()}`, amount: Number(amount), method: 'cash', paidItemId: '', paidItemName: '', paidQty: 0, date: todayKey(), employeeName: actor.employeeName }],
        updatedAt: timestamp,
      });
    });
  }), [user, data.profile, activeEmployee, runWrite]);

  const addNote = React.useCallback((note) => runWrite(async () => {
    const ref = doc(collection(db, 'stores', user.uid, 'notes'));
    await setDoc(ref, {
      id: ref.id, storeId: user.uid, type: note.type || 'note', title: note.title.trim(),
      content: note.content || '', date: note.dueDate || todayKey(), reminderAt: '', done: false, updatedAt: isoNow(),
    });
  }), [user, runWrite]);

  const toggleNote = React.useCallback((noteId) => runWrite(async () => {
    const ref = doc(db, 'stores', user.uid, 'notes', noteId);
    await runTransaction(db, async (transaction) => {
      const snapshot = await transaction.get(ref);
      if (!snapshot.exists()) throw new Error('This note was removed.');
      transaction.update(ref, { done: !snapshot.data().done, updatedAt: isoNow() });
    });
  }), [user, runWrite]);

  const deleteNote = React.useCallback((noteId) => runWrite(async () => {
    await deleteDoc(doc(db, 'stores', user.uid, 'notes', noteId));
  }), [user, runWrite]);

  const addEmployee = React.useCallback((employee) => runWrite(async () => {
    const ref = doc(collection(db, 'stores', user.uid, 'employees'));
    const now = isoNow();
    const created = { id: ref.id, name: employee.name.trim() };
    await setDoc(ref, { ...created, storeId: user.uid, createdAt: now, updatedAt: now });
    return created;
  }), [user, runWrite]);

  const updateEmployee = React.useCallback((employeeId, changes) => runWrite(async () => {
    const name = String(changes.name || '').trim();
    if (!user?.uid || !employeeId) throw new Error('Choose an employee to edit.');
    if (!name) throw new Error('Enter the employee name.');
    const id = String(employeeId);
    await updateDoc(doc(db, 'stores', user.uid, 'employees', id), { name, pin: deleteField(), updatedAt: isoNow() });
    if (String(activeEmployee?.id) === id) setActiveEmployee({ id, name });
  }), [user, activeEmployee, runWrite]);

  const removeEmployee = React.useCallback((employeeId) => runWrite(async () => {
    if (!user?.uid || !employeeId) throw new Error('Choose an employee to remove.');
    await deleteDoc(doc(db, 'stores', user.uid, 'employees', String(employeeId)));
    if (String(activeEmployee?.id) === String(employeeId)) setActiveEmployee(null);
  }), [user, activeEmployee, runWrite]);

  const updateSettings = React.useCallback((settings) => runWrite(async () => {
    await setDoc(doc(db, 'stores', user.uid), { ...settings, updatedAt: isoNow() }, { merge: true });
  }), [user, runWrite]);

  const retryPendingSync = React.useCallback(async () => {
    await persistPendingOps((current) => current.map((operation) => operation.status === 'needs-review'
      ? { ...operation, status: 'pending', error: '' }
      : operation));
    setError('');
  }, [persistPendingOps]);

  const pendingSales = pendingOps.filter((operation) => operation.type === 'sale');
  const visibleSales = [
    ...data.sales.filter((sale) => !pendingSales.some((operation) => operation.sale.id === sale.id)),
    ...pendingSales.map((operation) => ({
      ...saleFromDocument(operation.sale.id, operation.sale), offlinePending: true, syncError: operation.error || '',
    })),
  ].sort((a, b) => compareDatesDescending(a.timestamp || a.date, b.timestamp || b.date));
  const visibleProducts = data.products.map((row) => {
    const stock = projectedStock(row, pendingOps);
    return stock === row.stock ? row : { ...row, stock, offlinePending: true };
  });
  const visibleInventoryLogs = [
    ...data.inventoryLogs,
    ...pendingOps.flatMap((operation) => operation.type === 'sale' ? operation.inventoryLogs : [operation.log])
      .map((log) => ({ ...inventoryLogFromDocument(log.id, log), offlinePending: true })),
  ];
  const visibleUtangs = [
    ...data.utangs,
    ...pendingSales.filter((operation) => operation.utang).map((operation) => ({
      ...utangFromDocument(operation.utang.id, operation.utang), offlinePending: true,
    })),
  ];
  const isOnline = networkReachable && !backendOffline;
  const pendingReviewCount = pendingOps.filter((operation) => operation.status === 'needs-review').length;
  const signOutUser = React.useCallback(() => signOut(auth), []);
  const value = {
    ...data, products: visibleProducts, sales: visibleSales, customers: withCustomerMetrics(data.customers, visibleSales),
    inventoryLogs: visibleInventoryLogs, utangs: visibleUtangs,
    ready, error, isOnline, pendingSyncCount: pendingOps.length,
    pendingReviewCount,
    retryPendingSync,
    user, activeEmployee, selectEmployee, switchEmployee, addProduct, updateProduct, deleteProduct, restock, removeStock, completeSale, refundSale, deleteSale, addCategory, setProductExpiryDate,
    addUtang, recordUtangPayment, addNote, toggleNote, deleteNote, addEmployee, updateEmployee, removeEmployee, updateSettings, signOut: signOutUser,
  };

  if (!authReady) return <StoreStatus label="Connecting to StorePro…" />;
  if (!user) return <AuthScreen />;
  if (!ready) return <StoreStatus label="Syncing your store…" />;

  return <StoreContext.Provider value={value}>
    <View style={styles.root}>
      {pendingReviewCount > 0
        ? <View style={styles.errorBanner}><Text style={styles.errorText}>{pendingReviewCount} offline change{pendingReviewCount === 1 ? '' : 's'} need review because stock or catalog data changed before sync.</Text><Pressable accessibilityRole="button" onPress={retryPendingSync} style={styles.retryButton}><Text style={styles.retryText}>Retry sync</Text></Pressable></View>
        : pendingOps.length > 0
          ? <View style={styles.errorBanner}><Text style={styles.errorText}>{isOnline ? 'Syncing' : 'Offline'} · {pendingOps.length} sale or stock change{pendingOps.length === 1 ? '' : 's'} saved on this device and waiting to sync.</Text></View>
          : !isOnline
            ? <View style={styles.errorBanner}><Text style={styles.errorText}>Offline · saved store data is available. Sales and stock changes will sync when you reconnect.</Text></View>
            : error ? <View style={styles.errorBanner}><Text style={styles.errorText}>{error}</Text></View> : null}
      <View style={styles.root}>{activeEmployee ? children : <EmployeeSessionScreen store={value} />}</View>
    </View>
  </StoreContext.Provider>;
}

function StoreStatus({ label }) {
  return <View style={styles.status}><ActivityIndicator color={colors.primary} /><Text style={styles.statusText}>{label}</Text></View>;
}

export function useStore() {
  useAppTheme();
  const value = React.useContext(StoreContext);
  if (!value) throw new Error('useStore must be used inside StoreProvider.');
  return value;
}

const styles = createThemeAwareStyles({
  root: { flex: 1, backgroundColor: colors.background },
  status: { flex: 1, alignItems: 'center', justifyContent: 'center', gap: 12, backgroundColor: colors.background },
  statusText: { color: colors.muted, fontSize: 15, fontWeight: '600' },
  errorBanner: { paddingHorizontal: 16, paddingVertical: 10, backgroundColor: '#FFF3D3' },
  errorText: { color: '#785500', fontSize: 13, lineHeight: 18, textAlign: 'center' },
  retryButton: { alignSelf: 'center', paddingVertical: 8, paddingHorizontal: 12, marginTop: 7, borderWidth: 1, borderColor: '#B17D12', borderRadius: 8 },
  retryText: { color: '#785500', fontSize: 13, fontWeight: '700' },
});
