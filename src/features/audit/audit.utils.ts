import type { AuditLogRecord } from "./audit.types";

export function auditActorName(
  record: Pick<AuditLogRecord, "userId" | "firstName" | "lastName">,
): string {
  const name = [record.firstName?.trim(), record.lastName?.trim()]
    .filter(Boolean)
    .join(" ");
  return name || (record.userId === null ? "System" : `User #${record.userId}`);
}

export function formatAuditTimestamp(value: string): string {
  const date = new Date(value);
  if (!Number.isFinite(date.getTime())) return "Date unavailable";
  return new Intl.DateTimeFormat("en-US", {
    timeZone: "Asia/Manila",
    month: "short",
    day: "numeric",
    year: "numeric",
    hour: "numeric",
    minute: "2-digit",
  }).format(date);
}

export function auditActionLabel(value: string): string {
  return value
    .replace(/([a-z\d])([A-Z])/g, "$1 $2")
    .replace(/([A-Z])([A-Z][a-z])/g, "$1 $2")
    .replace(/[_-]+/g, " ")
    .trim();
}

function csvCell(value: string | number | null): string {
  let text = String(value ?? "").replace(/\u0000/g, "");
  if (/^[\s]*[=+\-@]/.test(text) || /^[\t\r\n]/.test(text)) text = `'${text}`;
  return `"${text.replace(/"/g, '""')}"`;
}

export function auditCsv(records: readonly AuditLogRecord[]): string {
  const header = [
    "Audit ID",
    "Timestamp (UTC)",
    "User ID",
    "First name",
    "Last name",
    "Role",
    "Action",
    "Module",
    "Result",
  ];
  const rows = records.map((record) =>
    [
      record.id,
      record.timestamp,
      record.userId,
      record.firstName,
      record.lastName,
      record.role,
      record.action,
      record.module,
      record.result,
    ]
      .map(csvCell)
      .join(","),
  );
  return [header.map(csvCell).join(","), ...rows].join("\r\n");
}
