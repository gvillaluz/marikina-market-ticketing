import type { Severity } from '@/api/types/common.types';
import type { TicketCategories } from '@/api/types/ticket.types';
import { ApiRequestError } from '@/utils/apiErrors';
import { CATEGORY_OPTIONS, SEVERITY_OPTIONS } from './ordinances.constants';
import type { OrdinanceDetailResponse, OrdinanceSummaryResponse, SaveOrdinanceRequest } from '@/api/types/ordinance.types';
import type { DraftPenaltyTier, OrdinanceDraft, OrdinanceFields, OrdinanceFieldErrors, OrdinanceSummary, TierFieldErrors } from './ordinances.types';

export function isCategory(value: unknown): value is TicketCategories {
  return CATEGORY_OPTIONS.some(option => option.value === value);
}

export function isSeverity(value: unknown): value is Severity {
  return SEVERITY_OPTIONS.some(option => option.value === value);
}

export function normalizeCategory(value: unknown): TicketCategories {
  const category = typeof value === 'number' && Number.isInteger(value) ? CATEGORY_OPTIONS[value]?.value : value;
  if (!isCategory(category)) throw new ApiRequestError();
  return category;
}

export function normalizeSeverity(value: unknown): Severity {
  const severity = typeof value === 'number' && Number.isInteger(value) ? SEVERITY_OPTIONS[value]?.value : value;
  if (!isSeverity(severity)) throw new ApiRequestError();
  return severity;
}

export function normalizeOrdinance(item: OrdinanceSummaryResponse): OrdinanceSummary {
  return { ...item, category: normalizeCategory(item.category), severity: item.severity == null ? null : normalizeSeverity(item.severity) };
}

export function normalizeOrdinanceDetails(item: OrdinanceDetailResponse) {
  if (!Array.isArray(item.penaltyTiers)) throw new ApiRequestError();
  return { ...normalizeOrdinance(item), penaltyTiers: item.penaltyTiers.map(tier => ({ ...tier, severity: normalizeSeverity(tier.severity) })) };
}

export function cloneDraft(draft: OrdinanceDraft): OrdinanceDraft {
  return { fields: { ...draft.fields }, tiers: draft.tiers.map(tier => ({ ...tier })) };
}

export function hasDraftChanges(draft: OrdinanceDraft, baseline: OrdinanceDraft): boolean {
  const text = (value: unknown) => typeof value === 'string' ? value.trim() : '';
  const comparable = (value: OrdinanceDraft) => ({
    fields: {
      ordinanceNumber: text(value.fields.ordinanceNumber), series: text(value.fields.series), marketCode: text(value.fields.marketCode),
      title: text(value.fields.title), description: text(value.fields.description), category: isCategory(value.fields.category) ? value.fields.category : '',
    },
    tiers: value.tiers.map(tier => ({ severity: isSeverity(tier.severity) ? tier.severity : '', amount: parsePenaltyAmount(tier.amount) ?? text(tier.amount) })),
  });
  return JSON.stringify(comparable(draft)) !== JSON.stringify(comparable(baseline));
}

export function emptyOrdinanceFields(): OrdinanceFields {
  return { ordinanceNumber: '', series: '', marketCode: '', title: '', description: '', category: '' };
}

export function parsePenaltyAmount(value: string): number | null {
  if (typeof value !== 'string') return null;
  const text = value.trim();
  if (!/^(?:\d+(?:\.\d{1,2})?|\.\d{1,2})$/.test(text)) return null;
  const amount = Number(text);
  return Number.isFinite(amount) && amount >= 0 && Number.isSafeInteger(Math.round(amount * 100)) ? amount : null;
}

export function validateOrdinance(fields: OrdinanceFields, tiers: DraftPenaltyTier[]) {
  const fieldErrors: OrdinanceFieldErrors = {};
  const required: readonly [Exclude<keyof OrdinanceFields, 'category'>, string][] = [
    ['ordinanceNumber', 'Ordinance number'], ['series', 'Series'], ['marketCode', 'Market code'],
    ['title', 'Title'], ['description', 'Description'],
  ];
  for (const [name, label] of required) if (typeof fields[name] !== 'string' || !fields[name].trim()) fieldErrors[name] = `${label} is required.`;
  if (!isCategory(fields.category)) fieldErrors.category = 'Select a category.';
  const tierErrors: Record<string, TierFieldErrors> = {};
  for (const tier of tiers) {
    const errors: TierFieldErrors = {};
    if (!isSeverity(tier.severity)) errors.severity = 'Select a severity.';
    if (parsePenaltyAmount(tier.amount) === null) errors.amount = 'Enter a nonnegative fee with up to two decimal places.';
    tierErrors[tier.key] = errors;
  }
  const isValid = tiers.length > 0 && Object.keys(fieldErrors).length === 0 && Object.values(tierErrors).every(errors => Object.keys(errors).length === 0);
  return { fieldErrors, tierErrors, isValid };
}

export function buildOrdinanceRequest(fields: OrdinanceFields, tiers: DraftPenaltyTier[]): SaveOrdinanceRequest | null {
  if (!validateOrdinance(fields, tiers).isValid || !isCategory(fields.category)) return null;
  const penaltyTiers: SaveOrdinanceRequest['penaltyTiers'] = [];
  for (const [index, tier] of tiers.entries()) {
    const amount = parsePenaltyAmount(tier.amount);
    if (amount === null || !isSeverity(tier.severity)) return null;
    penaltyTiers.push({ offenseNumber: index + 1, severity: tier.severity, penaltyAmount: amount });
  }
  return {
    ordinanceNumber: fields.ordinanceNumber.trim(), series: fields.series.trim(), marketCode: fields.marketCode.trim(),
    title: fields.title.trim(), description: fields.description.trim(), category: fields.category, penaltyTiers,
  };
}

export function ordinanceError(cause: unknown, fallback: string): string {
  return cause instanceof ApiRequestError && cause.serverMessage ? cause.serverMessage : fallback;
}

export function offenseLabel(number: number): string {
  const remainder = number % 100;
  const suffix = remainder >= 11 && remainder <= 13 ? 'th' : ({ 1: 'st', 2: 'nd', 3: 'rd' } as Record<number, string>)[number % 10] ?? 'th';
  return `${number}${suffix} Offense`;
}
