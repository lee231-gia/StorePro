import React from 'react';
import Icon from './Icon.jsx';

const navItems = [
  { key: 'dashboard', label: 'Dashboard', icon: 'dashboard', group: 'Overview' },
  { key: 'products', label: 'Products', icon: 'products', group: 'Store' },
  { key: 'inventory', label: 'Inventory', icon: 'inventory', group: 'Store' },
  { key: 'expiry', label: 'Expiry', icon: 'expiry', group: 'Store' },
  { key: 'sales', label: 'Sales', icon: 'sales', group: 'Store' },
  { key: 'utang', label: 'Utang', icon: 'utang', group: 'Manage' },
  { key: 'notes', label: 'Notes', icon: 'notes', group: 'Manage' },
  { key: 'categories', label: 'Categories', icon: 'categories', group: 'Manage' },
  { key: 'customers', label: 'Customers', icon: 'customers', group: 'Manage' },
  { key: 'employees', label: 'Employees', icon: 'employees', group: 'Manage' },
  { key: 'reports', label: 'Reports', icon: 'reports', group: 'Insights' },
  { key: 'settings', label: 'Settings', icon: 'settings', group: 'Insights' },
];

const todayLabel = new Intl.DateTimeFormat('en-PH', {
  weekday: 'short', month: 'short', day: 'numeric', year: 'numeric',
}).format(new Date());

export default function AppShell({ activePage, onNavigate, storeName, ownerName = 'Store owner', activeEmployee, onSwitchEmployee, lowStockCount = 0, children }) {
  const [drawerOpen, setDrawerOpen] = React.useState(false);
  const current = navItems.find((item) => item.key === activePage);
  const ownerInitials = (activeEmployee?.name || ownerName).split(' ').filter(Boolean).map((part) => part[0]).slice(0, 2).join('').toUpperCase();

  const navigate = (key) => {
    onNavigate(key);
    setDrawerOpen(false);
  };

  return (
    <div className="app-shell">
      {drawerOpen && <button className="mobile-scrim" aria-label="Close navigation" onClick={() => setDrawerOpen(false)} />}
      <aside className={`sidebar ${drawerOpen ? 'sidebar-open' : ''}`}>
        <div className="brand-row">
          <div className="brand-mark"><Icon name="box" size={22} /></div>
          <div className="brand-copy"><strong>storepro</strong><span>STORE MANAGEMENT</span></div>
          <button className="icon-button sidebar-close" aria-label="Close navigation" onClick={() => setDrawerOpen(false)}><Icon name="close" /></button>
        </div>

        <button className="store-switcher" onClick={() => navigate('settings')}>
          <span className="store-avatar">SP</span>
          <span className="store-switcher-copy"><strong>{storeName}</strong><small>My store</small></span>
          <Icon name="down" size={16} />
        </button>

        <nav className="side-nav" aria-label="Main navigation">
          {['Overview', 'Store', 'Manage', 'Insights'].map((group) => (
            <div className="nav-group" key={group}>
              <p className="nav-group-label">{group}</p>
              {navItems.filter((item) => item.group === group).map((item) => (
                <button
                  key={item.key}
                  className={`nav-link ${activePage === item.key ? 'nav-link-active' : ''}`}
                  onClick={() => navigate(item.key)}
                  aria-current={activePage === item.key ? 'page' : undefined}
                >
                  <Icon name={item.icon} size={19} />
                  <span>{item.label}</span>
                  {item.key === 'inventory' && lowStockCount > 0 && <span className="nav-count">{lowStockCount}</span>}
                </button>
              ))}
            </div>
          ))}
        </nav>

        <div className="sidebar-footer">
          <div className="profile-avatar">{(activeEmployee?.name || ownerName).split(' ').map((part) => part[0]).slice(0, 2).join('').toUpperCase()}</div>
          <div className="profile-copy"><strong>{activeEmployee?.name || ownerName}</strong><span>Using StorePro</span></div>
          <button className="icon-button sidebar-more" aria-label="Switch employee" title="Switch employee" onClick={onSwitchEmployee}><Icon name="employees" /></button>
        </div>
      </aside>

      <main className="main-area">
        <header className="topbar">
          <div className="topbar-left">
            <button className="icon-button mobile-menu" aria-label="Open navigation" onClick={() => setDrawerOpen(true)}><Icon name="menu" /></button>
            <div className="breadcrumb"><span>Store</span><Icon name="arrow" size={14} /><strong>{current?.label || 'Dashboard'}</strong></div>
          </div>
          <div className="topbar-right">
            <div className="today-date"><Icon name="calendar" size={17} /><span>{todayLabel}</span></div>
            <button className="topbar-profile" onClick={() => navigate('settings')} aria-label="Open settings"><span className="profile-avatar profile-avatar-small">{ownerInitials || 'SP'}</span><Icon name="down" size={15} /></button>
          </div>
        </header>
        <div className="page-content">{children}</div>
      </main>
    </div>
  );
}

export const pageLabels = navItems.reduce((labels, item) => ({ ...labels, [item.key]: item.label }), {});

