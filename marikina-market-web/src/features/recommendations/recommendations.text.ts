import type { SectionRecommendation } from "@/api/types/recommendations.types";
import {
  formatManilaDate,
  formatPeakWindow,
  recordCountText,
} from "./recommendations.format";

// Plain-language versions of the evidence each of the model's 29 categories asks for.
const WHAT_TO_RECORD: Record<string, string> = {
  "Vendor Identification":
    "Record who was selling and whether their assigned vendor ID was missing, invalid, or not displayed as required.",
  "Permit & Licensing":
    "Record the vendor activity, the permit or certificate it requires, and whether that document is missing, expired, or does not match the holder or scope.",
  Sanitation:
    "Record the specific hygiene or food-safety problem seen and the vendor responsible for it.",
  WeightMeasures:
    "Record the declared and measured quantities in the same unit, or any scale fault, tampering, or registration lapse.",
  "Lighting & Energy":
    "Record the lighting or energy-use restriction that applies and the equipment or electrical use that breaches it.",
  "Stall Occupancy":
    "Record how the stall is actually being occupied or used and how that differs from the stall award, contract, or occupancy condition.",
  "Stall Management":
    "Record the stallholder duty that applies, such as daily management or safety equipment, and how it was not carried out.",
  "Stall Construction":
    "Record the physical change made by the vendor and whether it lacks approval or differs from the approved plan.",
  Utilities:
    "Record the unauthorized connection, tampering, or specific water, drainage, or shared-utility rule that the vendor breached.",
  "Stall Rental":
    "Record the lease term or rent obligation checked and the unpaid amount, unauthorized rental or transfer, or other breach found.",
  "Illegal Vendor":
    "Record the exact location of the selling and confirm that the vendor has no authorization to sell there.",
  "Public Order":
    "Record the vendor-caused disturbance, such as fighting, dangerous disorder, or noise, and how it disrupted market activity.",
  Liquor:
    "Record the alcohol restriction that applies and the sale, service, or consumption that breached it.",
  "Market Conduct":
    "Record the specific act toward a shopper or neighboring vendor, such as harassment, coercion, or deception.",
  Obstruction:
    "Record the passage or exit affected and how the vendor's item blocks or narrows it.",
  DressCode:
    "Record the vendor activity, the attire requirement that applies, and what the vendor wore or lacked.",
  "Bladed Instruments":
    "Record the blade, how the vendor handled or stored it, and the specific requirement that was breached.",
  Traffic:
    "Record the vendor vehicle or delivery and the specific traffic restriction or marked zone it violated.",
  "Porter Regulation":
    "Record the person working as a porter and the registration, identification, rate, or operating rule that was breached.",
  Promotions:
    "Record the vendor promotion and the approval, prize, location, or other stated condition that was breached.",
  Advertising:
    "Record the vendor advertisement and the content, approval, or distribution rule it violates.",
  "Signage & Streamers":
    "Record the vendor's sign or streamer and the breach in its approval, size, placement, or display period.",
  "Entertainment Activities":
    "Record the vendor-run event and whether its required approval is missing or an approved condition was breached.",
  "Lighting Facilities":
    "Record the failed or unmaintained light and the vendor's maintenance duty for that fixture.",
  "Market Rules":
    "Record the specific operating rule that applies and how the vendor breached it.",
  "Price Monitoring":
    "Record the price display rule that applies, or compare the posted price with the price charged for the same unit.",
  "Market Fees & Surcharges":
    "Record the fee or surcharge that applies and the missed, late, or insufficient payment shown in the records.",
  "Resisting Authority":
    "Record the inspector or enforcement action involved and how the vendor interfered, obstructed, or impersonated an officer.",
  "General Penalties":
    "Record the suspension or closure order still in force and how the vendor continued the prohibited activity.",
};

export function whatToRecord(categoryCode: string): string | undefined {
  return WHAT_TO_RECORD[categoryCode];
}

// The main category is chosen by seriousness as well as count, so this says "leading", not "most common".
// The peak hours and latest date cover every detected violation on the street.
export function prominentViolationText(card: SectionRecommendation): string {
  return [
    `is the leading concern on ${card.marketSectionName}, appearing in ${card.categoryRecordCount} of the ${card.sectionRecordCount} warnings and tickets recorded in the last 30 days.`,
    `The busiest period for detected violations was ${formatPeakWindow(card.peakStartHour)}, and the latest was on ${formatManilaDate(card.lastFlaggedAt)}.`,
    `Risk is rated ${card.riskLevel}.`,
    `Confidence is ${card.patternConfidence} because this pattern is based on ${recordCountText(card.sectionRecordCount)}.`,
  ].join(" ");
}

export function recommendedActionText(card: SectionRecommendation): string {
  return [
    card.recommendedAction,
    `For any on-site check, go around ${formatPeakWindow(card.peakStartHour)}, the busiest period for detected violations on this street.`,
    whatToRecord(card.categoryCode),
    "Follow up afterward to confirm the problem has been corrected.",
  ]
    .filter(Boolean)
    .join(" ");
}
