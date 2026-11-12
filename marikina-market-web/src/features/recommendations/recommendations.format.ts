const MANILA_TIME_ZONE = "Asia/Manila";

export type RiskTone = "high" | "moderate" | "neutral";

function manilaParts(iso: string, options: Intl.DateTimeFormatOptions) {
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone: MANILA_TIME_ZONE,
    ...options,
  }).formatToParts(new Date(iso));
  return (type: Intl.DateTimeFormatPartTypes) =>
    parts.find((part) => part.type === type)?.value ?? "";
}

export function formatManilaDate(iso: string): string {
  const part = manilaParts(iso, {
    day: "numeric",
    month: "short",
    year: "numeric",
  });
  return `${part("day")} ${part("month")} ${part("year")}`;
}

export function formatManilaDateTime(iso: string): string {
  const part = manilaParts(iso, {
    hour: "numeric",
    minute: "2-digit",
    hour12: true,
  });
  return `${formatManilaDate(iso)}, ${part("hour")}:${part("minute")} ${part("dayPeriod")}`;
}

export function recordCountText(count: number): string {
  return `${count} ${count === 1 ? "record" : "records"}`;
}

export function peakHours(startHour: number): number[] {
  return [0, 1, 2].map((offset) => (startHour + offset) % 24);
}

function hourText(hour: number): string {
  return `${String(hour % 24).padStart(2, "0")}:00`;
}

export function formatPeakWindow(startHour: number): string {
  return `${hourText(startHour)}–${hourText(startHour + 3)}`;
}

export function riskTone(riskLevel: string): RiskTone {
  if (riskLevel === "High") return "high";
  if (riskLevel === "Moderate") return "moderate";
  return "neutral";
}
