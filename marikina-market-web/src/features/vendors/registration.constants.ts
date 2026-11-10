import {
  MARKET_SECTION_IDS,
  MARKET_SECTION_LABELS,
  type MarketSection,
} from "@/api/types/common.types";

export const MARKET_SECTION_OPTIONS = Object.entries(MARKET_SECTION_LABELS).map(
  ([section, label]) => ({
    value: String(MARKET_SECTION_IDS[section as MarketSection]),
    label,
  }),
);

export const VENDOR_TYPE_OPTIONS = [
  { value: "Public", label: "Public" },
  { value: "Private", label: "Private" },
];
