export function displayProfileValue(value: string | null): string {
  return value?.trim() || "Not provided";
}

export function formatProfileDate(value: string, dateOnly = false): string {
  if (dateOnly && !/^\d{4}-\d{2}-\d{2}$/.test(value)) return "Not provided";
  const date = new Date(dateOnly ? `${value}T00:00:00Z` : value);
  if (!Number.isFinite(date.getTime())) return "Not provided";
  if (dateOnly && date.toISOString().slice(0, 10) !== value)
    return "Not provided";
  return new Intl.DateTimeFormat("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
    timeZone: "UTC",
  }).format(date);
}
