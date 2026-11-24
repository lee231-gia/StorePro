import React from 'react';
import AppShell from './components/AppShell.jsx';
import Icon from './components/Icon.jsx';
import { useStoreData } from './hooks/useStoreData.js';

const DashboardPage = React.lazy(() => import('./pages/DashboardPage.jsx'));
const ProductsPage = React.lazy(() => import('./pages/ProductsPage.jsx'));
const SalesPage = React.lazy(() => import('./pages/SalesPage.jsx'));
const InventoryPage = React.lazy(() => import('./pages/InventoryPage.jsx'));
const ReportsPage = React.lazy(() => import('./pages/ReportsPage.jsx'));
const ExpiryPage = React.lazy(() => import('./pages/OperationalPages.jsx').then((module) => ({ default: module.ExpiryPage })));
const UtangPage = React.lazy(() => import('./pages/OperationalPages.jsx').then((module) => ({ default: module.UtangPage })));
const NotesPage = React.lazy(() => import('./pages/OperationalPages.jsx').then((module) => ({ default: module.NotesPage })));
const CategoriesPage = React.lazy(() => import('./pages/DirectoryPages.jsx').then((module) => ({ default: module.CategoriesPage })));
const CustomersPage = React.lazy(() => import('./pages/DirectoryPages.jsx').then((module) => ({ default: module.CustomersPage })));
const EmployeesPage = React.lazy(() => import('./pages/DirectoryPages.jsx').then((module) => ({ default: module.EmployeesPage })));
const SettingsPage = React.lazy(() => import('./pages/DirectoryPages.jsx').then((module) => ({ default: module.SettingsPage })));
const EmployeeSessionPage = React.lazy(() => import('./pages/EmployeeSessionPage.jsx'));

export default function StoreApp({ user, theme, onThemeChange }) {
  const [activePage, setActivePage] = React.useState('dashboard');
  const [toast, setToast] = React.useState('');
  const toastTimer = React.useRef(null);
  const store = useStoreData(user);

  const notify = React.useCallback((message) => {
    setToast(message);
    window.clearTimeout(toastTimer.current);
    toastTimer.current = window.setTimeout(() => setToast(''), 3000);
  }, []);

  React.useEffect(() => () => window.clearTimeout(toastTimer.current), []);

  if (store.loading) return <LoadingScreen label="Syncing your store…" />;
  if (!store.activeEmployee) return <React.Suspense fallback={<LoadingScreen label="Opening StorePro…" />}><EmployeeSessionPage store={store} notify={notify} /></React.Suspense>;

  let content;
  switch (activePage) {
    case 'products': content = <ProductsPage store={store} notify={notify} />; break;
    case 'inventory': content = <InventoryPage store={store} notify={notify} />; break;
    case 'expiry': content = <ExpiryPage store={store} notify={notify} />; break;
    case 'sales': content = <SalesPage store={store} notify={notify} />; break;
    case 'utang': content = <UtangPage store={store} notify={notify} />; break;
    case 'notes': content = <NotesPage store={store} notify={notify} />; break;
    case 'reports': content = <ReportsPage store={store} />; break;
    case 'categories': content = <CategoriesPage store={store} notify={notify} />; break;
    case 'customers': content = <CustomersPage store={store} />; break;
    case 'employees': content = <EmployeesPage store={store} notify={notify} />; break;
    case 'settings': content = <SettingsPage store={store} notify={notify} theme={theme} onThemeChange={onThemeChange} />; break;
    default: content = <DashboardPage store={store} onNavigate={setActivePage} />;
  }

  const ownerName = store.profile?.ownerName || user.email || 'Store owner';

  return (
    <>
      <AppShell activePage={activePage} onNavigate={setActivePage} storeName={store.settings.storeName} ownerName={ownerName} activeEmployee={store.activeEmployee} onSwitchEmployee={store.switchEmployee} lowStockCount={store.products.filter((product) => product.stock <= product.minStock).length}>
        {store.pendingReviewCount > 0
          ? <div className="sync-banner" role="alert"><Icon name="refresh" size={18} /><span>{store.pendingReviewCount} offline change{store.pendingReviewCount === 1 ? '' : 's'} need review because stock or catalog data changed before sync.</span><button className="sync-retry-button" type="button" onClick={store.retryPendingSync}>Retry sync</button></div>
          : store.pendingSyncCount > 0
            ? <div className="sync-banner" role="status"><Icon name="refresh" size={18} /><span>{store.isOnline ? 'Syncing' : 'Offline'} · {store.pendingSyncCount} sale or stock change{store.pendingSyncCount === 1 ? '' : 's'} saved on this device and waiting to sync.</span></div>
            : !store.isOnline
              ? <div className="sync-banner" role="status"><Icon name="refresh" size={18} /><span>Offline · your saved store data is available. Sales and stock changes will sync when you reconnect.</span></div>
              : store.error && <div className="sync-banner" role="alert"><Icon name="refresh" size={18} /><span>{store.error}</span></div>}
        <React.Suspense fallback={<LoadingScreen label="Opening page…" />}>{content}</React.Suspense>
      </AppShell>
      {toast && <div className="toast" role="status"><span className="toast-check"><Icon name="check" size={17} /></span>{toast}</div>}
    </>
  );
}

function LoadingScreen({ label }) {
  return <main className="app-loading"><span className="app-loading-mark"><Icon name="box" size={25} /></span><strong>{label}</strong><span className="app-loading-spinner" aria-hidden="true" /></main>;
}
