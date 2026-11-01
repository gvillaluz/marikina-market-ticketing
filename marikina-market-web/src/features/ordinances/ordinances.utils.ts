import type { Severity } from "@/api/types/common.types";
import type { TicketCategories } from "@/api/types/ticket.types";
import { ApiRequestError } from "@/utils/apiErrors";
import {
  CATEGORY_OPTIONS,
  CATEGORY_VALUES,
  SEVERITY_OPTIONS,
  FINE_KIND_OPTIONS,
} from "./ordinances.constants";
import type {
  OrdinanceDetailResponse,
  OrdinanceSummaryResponse,
  SaveOrdinanceRequest,
  FineKind,
} from "@/api/types/ordinance.types";
import type {
  DraftPenaltyTier,
  OrdinanceDraft,
  OrdinanceFields,
  OrdinanceFieldErrors,
  OrdinanceSummary,
  TierFieldErrors,
} from "./ordinances.types";

export function isCategory(value: unknown): value is TicketCategories {
  return CATEGORY_OPTIONS.some((option) => option.value === value);
}

export function isSeverity(value: unknown): value is Severity {
  return SEVERITY_OPTIONS.some((option) => option.value === value);
}

export function isFineKind(value: unknown): value is FineKind {
  return FINE_KIND_OPTIONS.some((option) => option.value === value);
}

export function normalizeFineKind(value: unknown): FineKind {
  const kind = typeof value === "number" && Number.isInteger(value)
    ? FINE_KIND_OPTIONS[value]?.value : value;
  if (!isFineKind(kind)) throw new ApiRequestError();
  return kind;
}

export function normalizeCategory(value: unknown): TicketCategories {
  const category =
    typeof value === "number" && Number.isInteger(value)
      ? CATEGORY_VALUES[value]
      : value;
  if (
    typeof category !== "string" ||
    !CATEGORY_VALUES.includes(category as TicketCategories)
  )
    throw new ApiRequestError();
  return category as TicketCategories;
}

export function normalizeSeverity(value: unknown): Severity {
  const severity =
    typeof value === "number" && Number.isInteger(value)
      ? SEVERITY_OPTIONS[value]?.value
      : value;
  if (!isSeverity(severity)) throw new ApiRequestError();
  return severity;
}

export function normalizeOrdinance(
  item: OrdinanceSummaryResponse,
): OrdinanceSummary {
  if (typeof item.warningEligible !== "boolean") throw new ApiRequestError();
  return {
    ...item,
    category: normalizeCategory(item.category),
    severity: item.severity == null ? null : normalizeSeverity(item.severity),
  };
}

export function normalizeOrdinanceDetails(item: OrdinanceDetailResponse) {
  if (!Array.isArray(item.penaltyTiers)) throw new ApiRequestError();
  return {
    ...normalizeOrdinance(item),
    penaltyTiers: item.penaltyTiers.map((tier) => ({
      ...tier,
      fineKind: normalizeFineKind(tier.fineKind),
    })),
  };
}

export function cloneDraft(draft: OrdinanceDraft): OrdinanceDraft {
  return {
    fields: { ...draft.fields },
    tiers: draft.tiers.map((tier) => ({ ...tier })),
  };
}

export function hasDraftChanges(
  draft: OrdinanceDraft,
  baseline: OrdinanceDraft,
): boolean {
  const text = (value: unknown) =>
    typeof value === "string" ? value.trim() : "";
  const comparable = (value: OrdinanceDraft) => ({
    fields: {
      ordinanceNumber: text(value.fields.ordinanceNumber),
      series: text(value.fields.series),
      section: text(value.fields.section),
      specificCategory:
        value.fields.category === "Others"
          ? text(value.fields.specificCategory)
          : "",
      title: text(value.fields.title),
      category: isCategory(value.fields.category) ? value.fields.category : "",
      severity: isSeverity(value.fields.severity) ? value.fields.severity : "",
      warningEligible: value.fields.warningEligible,
    },
    tiers: value.tiers.map((tier) => ({
      fineKind: tier.fineKind,
      amount: tier.fineKind === "Fixed" ? parsePenaltyAmount(tier.amount) ?? text(tier.amount) : null,
      maximumFine: tier.fineKind === "UpTo" ? parsePenaltyAmount(tier.maximumFine) ?? text(tier.maximumFine) : null,
      penaltyTerms: text(tier.penaltyTerms),
      allowBloodDonation: tier.allowBloodDonation,
      allowCommunityService: tier.allowCommunityService,
    })),
  });
  return (
    JSON.stringify(comparable(draft)) !== JSON.stringify(comparable(baseline))
  );
}

export function emptyOrdinanceFields(): OrdinanceFields {
  return {
    ordinanceNumber: "",
    series: "",
    section: "",
    specificCategory: "",
    title: "",
    category: "",
    severity: "",
    warningEligible: false,
  };
}

export function parsePenaltyAmount(value: string): number | null {
  if (typeof value !== "string") return null;
  const text = value.trim();
  if (!/^(?:\d+(?:\.\d{1,2})?|\.\d{1,2})$/.test(text)) return null;
  const amount = Number(text);
  return Number.isFinite(amount) &&
    amount >= 0 &&
    Number.isSafeInteger(Math.round(amount * 100))
    ? amount
    : null;
}

export function validateOrdinance(
  fields: OrdinanceFields,
  tiers: DraftPenaltyTier[],
) {
  const fieldErrors: OrdinanceFieldErrors = {};
  const required: readonly [
    "ordinanceNumber" | "series" | "section" | "title",
    string,
  ][] = [
      ["ordinanceNumber", "Ordinance number"],
      ["series", "Series"],
      ["section", "Section of ordinance"],
      ["title", "Title"],
    ];
  for (const [name, label] of required)
    if (typeof fields[name] !== "string" || !fields[name].trim())
      fieldErrors[name] = `${label} is required.`;
  if (
    !fieldErrors.ordinanceNumber &&
    !/^[0-9]+$/.test(fields.ordinanceNumber.trim())
  )
    fieldErrors.ordinanceNumber =
      "Use digits only, without a prefix or series.";
  for (const [name, label, limit] of [
    ["ordinanceNumber", "Ordinance number", 100],
    ["series", "Series", 100],
    ["section", "Section of ordinance", 100],
    ["title", "Title", 250],
  ] as const)
    if (typeof fields[name] === "string" && fields[name].trim().length > limit)
      fieldErrors[name] = `${label} must not exceed ${limit} characters.`;
  if (!isCategory(fields.category)) fieldErrors.category = "Select a category.";
  if (!isSeverity(fields.severity)) fieldErrors.severity = "Select a scoring severity.";
  if (typeof fields.warningEligible !== "boolean") fieldErrors.warningEligible = "Confirm warning eligibility.";
  if (fields.category === "Others") {
    if (
      typeof fields.specificCategory !== "string" ||
      !fields.specificCategory.trim()
    )
      fieldErrors.specificCategory = "Specific category is required.";
    else if (fields.specificCategory.trim().length > 100)
      fieldErrors.specificCategory = "Specific category must not exceed 100 characters.";
  }
  const tierErrors: Record<string, TierFieldErrors> = {};
  for (const [index, tier] of tiers.entries()) {
    const errors: TierFieldErrors = {};
    if (!isFineKind(tier.fineKind)) errors.fineKind = "Select a fine rule.";
    if (tier.fineKind === "Fixed" && parsePenaltyAmount(tier.amount) === null)
      errors.amount = "Enter a nonnegative fine with up to two decimal places.";
    const cap = parsePenaltyAmount(tier.maximumFine);
    if (tier.fineKind === "UpTo" && (cap === null || cap < 100))
      errors.maximumFine = "Enter a maximum of at least ₱100 with up to two decimal places.";
    if (tier.fineKind === "Unconfirmed" && !tier.penaltyTerms?.trim())
      errors.penaltyTerms = "Enter the terms that require confirmation.";
    else if (tier.penaltyTerms?.trim().length > 1000)
      errors.penaltyTerms = "Penalty terms must not exceed 1000 characters.";
    for (const flag of ["allowBloodDonation", "allowCommunityService"] as const)
      if (typeof tier[flag] !== "boolean" || (index > 0 && tier[flag]))
        errors[flag] = "Alternative penalties are available on the first offense only.";
    tierErrors[tier.key] = errors;
  }
  const isValid =
    tiers.length > 0 &&
    Object.keys(fieldErrors).length === 0 &&
    Object.values(tierErrors).every(
      (errors) => Object.keys(errors).length === 0,
    );
  return { fieldErrors, tierErrors, isValid };
}

export function buildOrdinanceRequest(
  fields: OrdinanceFields,
  tiers: DraftPenaltyTier[],
): SaveOrdinanceRequest | null {
  if (!validateOrdinance(fields, tiers).isValid || !isCategory(fields.category) || !isSeverity(fields.severity))
    return null;
  const penaltyTiers: SaveOrdinanceRequest["penaltyTiers"] = [];
  for (const [index, tier] of tiers.entries()) {
    if (!isFineKind(tier.fineKind)) return null;
    penaltyTiers.push({
      offenseNumber: index + 1,
      fineKind: tier.fineKind,
      penaltyAmount: tier.fineKind === "Fixed" ? parsePenaltyAmount(tier.amount) : null,
      maximumFine: tier.fineKind === "UpTo" ? parsePenaltyAmount(tier.maximumFine) : null,
      penaltyTerms: tier.penaltyTerms.trim() || null,
      allowBloodDonation: tier.allowBloodDonation,
      allowCommunityService: tier.allowCommunityService,
    });
  }
  return {
    ordinanceNumber: fields.ordinanceNumber.trim(),
    series: fields.series.trim(),
    section: fields.section.trim(),
    specificCategory:
      fields.category === "Others" ? fields.specificCategory.trim() : null,
    title: fields.title.trim(),
    category: fields.category,
    severity: fields.severity,
    warningEligible: fields.warningEligible,
    penaltyTiers,
  };
}

export function ordinanceError(cause: unknown, fallback: string): string {
  return cause instanceof ApiRequestError && cause.serverMessage
    ? cause.serverMessage
    : fallback;
}

export function offenseLabel(number: number): string {
  const remainder = number % 100;
  const suffix =
    remainder >= 11 && remainder <= 13
      ? "th"
      : (({ 1: "st", 2: "nd", 3: "rd" } as Record<number, string>)[
        number % 10
      ] ?? "th");
  return `${number}${suffix} Offense`;
}
