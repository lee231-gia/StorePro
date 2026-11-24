import React from 'react';
import Icon from './Icon.jsx';

export function Button({ children, variant = 'primary', size = 'md', icon, className = '', type = 'button', ...props }) {
  return (
    <button type={type} className={`button button-${variant} button-${size} ${className}`} {...props}>
      {icon && <Icon name={icon} size={18} />}
      <span>{children}</span>
    </button>
  );
}

export function Card({ children, className = '', ...props }) {
  return <section className={`card ${className}`} {...props}>{children}</section>;
}

export function PageHeader({ title, description, action }) {
  return (
    <div className="page-heading">
      <div><h1>{title}</h1>{description && <p>{description}</p>}</div>
      {action && <div className="page-heading-action">{action}</div>}
    </div>
  );
}

export function StatusPill({ children, tone = 'neutral' }) {
  return <span className={`status-pill status-${tone}`}>{children}</span>;
}

export function SegmentedTabs({ tabs, value, onChange, label = 'Page options' }) {
  return <div className="segmented-tabs" role="tablist" aria-label={label}>{tabs.map((tab) => (
    <button key={tab.key} type="button" role="tab" aria-selected={tab.key === value} className={`segmented-tab${tab.key === value ? ' segmented-tab-active' : ''}`} onClick={() => onChange(tab.key)}>{tab.label}</button>
  ))}</div>;
}

export function Modal({ title, description, onClose, children, footer, className = '' }) {
  return (
    <div className="modal-backdrop" role="presentation" onMouseDown={(event) => event.target === event.currentTarget && onClose()}>
      <section className={`modal ${className}`} role="dialog" aria-modal="true" aria-label={title}>
        <div className="modal-header">
          <div><h2>{title}</h2>{description && <p>{description}</p>}</div>
          <button className="icon-button" aria-label="Close dialog" onClick={onClose}><Icon name="close" /></button>
        </div>
        <div className="modal-body">{children}</div>
        {footer && <div className="modal-footer">{footer}</div>}
      </section>
    </div>
  );
}

export function TextField({ label, hint, className = '', ...props }) {
  return <label className={`field ${className}`}><span>{label}</span><input {...props} />{hint && <small>{hint}</small>}</label>;
}

export function TextAreaField({ label, hint, className = '', ...props }) {
  return <label className={`field ${className}`}><span>{label}</span><textarea {...props} />{hint && <small>{hint}</small>}</label>;
}

export function SelectField({ label, children, ...props }) {
  return <label className="field"><span>{label}</span><select {...props}>{children}</select></label>;
}
