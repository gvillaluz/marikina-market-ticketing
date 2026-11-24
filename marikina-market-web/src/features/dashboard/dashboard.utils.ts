export function formatDashboardTimestamp(value: string): string {
  const date = new Date(value);
  if (!Number.isFinite(date.getTime())) return "Time unavailable";

  return new Intl.DateTimeFormat("en-US", {
    timeZone: "Asia/Manila",
    month: "short",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
  }).format(date);
}
export function formatDashboardUpdatedAt(value: string): string {
  return formatDashboardTimestamp(value);
}

export function formatDaysOverdue(days: number): string {
  if (days === 0) return "Overdue since today";
  return days === 1 ? "1 day overdue" : `${days} days overdue`;
}
