import type { AdminVendorInspection } from "@/api/types/admin-vendor.types";

// A ticket records the name written on paper; a warning only has the confirmed person.
export function formatInspectionViolator(
  inspection: AdminVendorInspection,
): string {
  const name =
    String(inspection.type).toLowerCase() === "warning"
      ? inspection.personFullName
      : inspection.paperViolatorName;
  return name || "Unconfirmed (legacy record)";
}
