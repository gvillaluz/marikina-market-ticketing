import {
  MARKET_SECTION_IDS,
  MARKET_SECTION_LABELS,
  type MarketSection,
} from "@/api/types/common.types";

export const TOTAL_STEPS = 4;

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

export const GOVERNMENT_ID_OPTIONS = [
  { value: "NationalID", label: "PhilSys National ID" },
  { value: "UMID", label: "UMID" },
  { value: "SSSID", label: "SSS ID" },
  { value: "GSISID", label: "GSIS ID" },
  { value: "PhilHealthID", label: "PhilHealth ID" },
  { value: "DriversLicense", label: "Driver's License" },
  { value: "Passport", label: "Passport" },
  { value: "PRCID", label: "PRC ID" },
  { value: "PostalID", label: "Postal ID" },
  { value: "VotersID", label: "Voter's ID" },
  { value: "TINID", label: "TIN ID" },
];
