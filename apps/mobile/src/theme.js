import React from 'react';
import { useColorScheme } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';

const lightPalette = {
  primary: '#3D5A56', primaryDark: '#2F4945', primarySoft: '#DCEAE5', accent: '#D4A72C',
  background: '#EAF2EF', surface: '#FFFFFF', surfaceSoft: '#F7FAF8', border: '#9AAFA8',
  text: '#16231F', muted: '#3C504A', success: '#236640', successSoft: '#E7F3E9',
  warning: '#785500', warningSoft: '#FFF3D3', error: '#B3261E', goldSoft: '#F8F0D9',
};

const darkPalette = {
  primary: '#9AC8AE', primaryDark: '#D8E9DF', primarySoft: '#2B4538', accent: '#E4C56C',
  background: '#111A16', surface: '#1C2722', surfaceSoft: '#24312B', border: '#43564C',
  text: '#EDF4EF', muted: '#B9C8BF', success: '#9ED8AD', successSoft: '#274536',
  warning: '#F0CF7D', warningSoft: '#4C4124', error: '#F2B8AF', goldSoft: '#494024',
};

export const colors = { ...lightPalette };
let activeIsDark = false;
let paletteVersion = 0;
const paletteSubscribers = new Set();

function subscribeToPalette(callback) {
  paletteSubscribers.add(callback);
  return () => paletteSubscribers.delete(callback);
}

function getPaletteVersion() {
  return paletteVersion;
}

function applyPalette(isDark) {
  if (activeIsDark === isDark) return;
  activeIsDark = isDark;
  Object.assign(colors, isDark ? darkPalette : lightPalette);
  paletteVersion += 1;
  paletteSubscribers.forEach((callback) => callback());
}

export const spacing = { xs: 6, sm: 10, md: 16, lg: 22, xl: 28 };

function colorForStyleProperty(property, color) {
  if (!activeIsDark || typeof color !== 'string') return color;
  const normalized = color.toLowerCase();
  if (property === 'color' || property === 'tintColor') {
    const map = {
      [lightPalette.primary.toLowerCase()]: darkPalette.primary,
      [lightPalette.primaryDark.toLowerCase()]: darkPalette.primaryDark,
      [lightPalette.text.toLowerCase()]: darkPalette.text,
      [lightPalette.muted.toLowerCase()]: darkPalette.muted,
      [lightPalette.success.toLowerCase()]: darkPalette.success,
      [lightPalette.warning.toLowerCase()]: darkPalette.warning,
      [lightPalette.error.toLowerCase()]: darkPalette.error,
      '#a0473d': '#F0B8AE', '#8f2922': '#FFD5CF', '#a12f26': '#FFD5CF', '#785500': darkPalette.warning,
      '#75857d': darkPalette.muted,
      '#78877f': darkPalette.muted,
      '#718078': darkPalette.muted,
      '#74827b': darkPalette.muted,
      '#42574e': darkPalette.muted,
      '#344a41': darkPalette.text,
      '#203b30': darkPalette.text,
      '#533f0e': darkPalette.warning,
    };
    return map[normalized] || color;
  }
  if (property.toLowerCase().includes('border')) {
    if (normalized === lightPalette.border.toLowerCase() || normalized === '#edf1ef' || normalized === '#edf2ef' || normalized === '#b9cac2') return darkPalette.border;
    if (normalized === lightPalette.primary.toLowerCase()) return '#638572';
    return color;
  }
  if (property === 'backgroundColor') {
    const map = {
      [lightPalette.background.toLowerCase()]: darkPalette.background,
      [lightPalette.surface.toLowerCase()]: darkPalette.surface,
      [lightPalette.surfaceSoft.toLowerCase()]: darkPalette.surfaceSoft,
      [lightPalette.primary.toLowerCase()]: '#35674F',
      [lightPalette.primaryDark.toLowerCase()]: '#28453A',
      [lightPalette.primarySoft.toLowerCase()]: darkPalette.primarySoft,
      [lightPalette.successSoft.toLowerCase()]: darkPalette.successSoft,
      [lightPalette.warningSoft.toLowerCase()]: darkPalette.warningSoft,
      [lightPalette.goldSoft.toLowerCase()]: darkPalette.goldSoft,
      '#e5efeb': '#294536', '#e8f0eb': '#30483C', '#e7eef2': '#2D414B',
      '#f4e9e3': '#49342E', '#fbe9e6': '#4A2926', '#f8f0d9': '#494024',
      '#f8f0d9ff': '#494024', '#edf1ef': '#29372F', '#edf3f0': '#303E36',
      '#fff9e9': '#342E1D', '#fff8e5': '#342E1D', '#eff4f1': '#29372F',
      '#f3f7f5': '#E6F0E9', '#d9e5df': '#D5E5DA',
      '#fff': darkPalette.surface, '#ffffff': darkPalette.surface, '#f5f8f6': '#202D26',
      '#e5f2e9': '#294536', '#e6f2e9': '#294536', '#f9e9e4': '#492E2B',
      '#fff3d3': '#4C4124', '#f0d1cb': '#633B35', '#e6eee9': '#2E4137',
      '#dceae5': '#2B4538',
    };
    return map[normalized] || color;
  }
  return color;
}

export function createThemeAwareStyles(definitions) {
  return new Proxy(definitions, {
    get(target, styleName, receiver) {
      const value = Reflect.get(target, styleName, receiver);
      if (!value || typeof value !== 'object' || Array.isArray(value)) return value;
      return new Proxy(value, {
        get(style, property, styleReceiver) {
          return colorForStyleProperty(property, Reflect.get(style, property, styleReceiver));
        },
      });
    },
  });
}

const ThemeContext = React.createContext({ themePreference: 'system', isDark: false, setThemePreference: async () => {} });
const THEME_STORAGE_KEY = 'storepro-theme';

export function ThemeProvider({ children }) {
  const systemScheme = useColorScheme();
  const [themePreference, setThemePreferenceState] = React.useState('system');
  const [loaded, setLoaded] = React.useState(false);
  React.useEffect(() => {
    let alive = true;
    AsyncStorage.getItem(THEME_STORAGE_KEY).then((value) => {
      if (alive && ['system', 'light', 'dark'].includes(value)) setThemePreferenceState(value);
    }).catch(() => {}).finally(() => { if (alive) setLoaded(true); });
    return () => { alive = false; };
  }, []);
  const isDark = themePreference === 'dark' || (themePreference === 'system' && systemScheme === 'dark');
  React.useEffect(() => {
    applyPalette(isDark);
  }, [isDark]);
  const setThemePreference = React.useCallback(async (next) => {
    if (!['system', 'light', 'dark'].includes(next)) return;
    setThemePreferenceState(next);
    try { await AsyncStorage.setItem(THEME_STORAGE_KEY, next); } catch { /* Current session still applies the selected mode. */ }
  }, []);
  const value = React.useMemo(() => ({ themePreference, isDark, ready: loaded, setThemePreference }), [themePreference, isDark, loaded, setThemePreference]);
  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
}

export function useAppTheme() {
  React.useSyncExternalStore(subscribeToPalette, getPaletteVersion, getPaletteVersion);
  return React.useContext(ThemeContext);
}
