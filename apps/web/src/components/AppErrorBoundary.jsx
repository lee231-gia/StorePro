import React from 'react';
import Icon from './Icon.jsx';

export default class AppErrorBoundary extends React.Component {
  state = { error: null };

  static getDerivedStateFromError(error) {
    return { error };
  }

  componentDidCatch(error, info) {
    console.error('StorePro could not render the signed-in app.', error, info.componentStack);
  }

  render() {
    if (!this.state.error) return this.props.children;
    return <main className="app-error" role="alert">
      <span className="app-error-icon"><Icon name="warning" size={25} /></span>
      <h1>StorePro could not open this screen</h1>
      <p>{this.state.error.message || 'A display error stopped the app from loading.'}</p>
      <button className="button button-primary" onClick={() => window.location.reload()}>Reload StorePro</button>
    </main>;
  }
}
