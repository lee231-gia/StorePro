const moneyFormatter = new Intl.NumberFormat('en-PH', {
  style: 'currency',
  currency: 'PHP',
  maximumFractionDigits: 0,
});

const dateFormatter = new Intl.DateTimeFormat('en-PH', {
  month: 'short',
  day: 'numeric',
  year: 'numeric',
});

export const money = (value) => moneyFormatter.format(Number(value) || 0);

export function shortDate(value) {
  if (!value) return '—';
  const input = value instanceof Date ? value : new Date(`${String(value).slice(0, 10)}T12:00:00`);
  return Number.isNaN(input.getTime()) ? '—' : dateFormatter.format(input);
}
