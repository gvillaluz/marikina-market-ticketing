export const AUDIT_PAGE_SIZE = 10;
export const AUDIT_MODULE_OPTIONS = [
  { value: "Users", label: "Users" },
  { value: "Security", label: "Security" },
  { value: "Ordinances", label: "Ordinances" },
  { value: "Vendors", label: "Vendors" },
  { value: "Tickets", label: "Tickets" },
  { value: "MarketSections", label: "Market Sections" },
  { value: "Backups", label: "Data & Backups" },
  { value: "Reports", label: "Reports" },
  { value: "Notifications", label: "Notifications" },
  { value: "AuditLogs", label: "Audit Logs" },
] as const;
export const AUDIT_RESULT_OPTIONS = [
  { value: "Success", label: "Success" },
  { value: "Failed", label: "Failed" },
] as const;
export const AUDIT_DATE_OPTIONS = [
  { value: "AllTime", label: "All time" },
  { value: "Last7Days", label: "Last 7 days" },
  { value: "Today", label: "Today" },
  { value: "Yesterday", label: "Yesterday" },
  { value: "Last30Days", label: "Last 30 days" },
  { value: "ThisMonth", label: "This month" },
  { value: "LastMonth", label: "Last month" },
] as const;
