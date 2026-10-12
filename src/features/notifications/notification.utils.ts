import { ROUTES } from "@/routes/routePaths";

export interface VendorRegistrationPushData {
  type: string;
  registration_id: string;
}

export function getVendorRegistrationReviewPath(
  data: Record<string, string> | undefined,
): string | null {
  if (!data || data.type !== "vendor_registration") return null;
  const registrationId = data.registration_id;
  if (!registrationId || !/^\d{1,12}$/.test(registrationId)) return null;
  return ROUTES.adminVendorRegistration(registrationId);
}

export function getVendorRegistrationPushKey(
  data: Record<string, string> | undefined,
  messageId: string | undefined,
): string | null {
  const reviewPath = getVendorRegistrationReviewPath(data);
  if (!reviewPath) return null;
  const id = typeof messageId === "string" ? messageId.trim() : "";
  return id && id.length <= 256
    ? `message:${id}`
    : `registration:${reviewPath}`;
}
