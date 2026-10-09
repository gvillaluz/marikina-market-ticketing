import { useState } from "react";
import type { VendorRegistrationDocument } from "@/api/types/admin-vendor.types";

export function useReviewDocument(document: VendorRegistrationDocument) {
  const [failedUrl, setFailedUrl] = useState("");
  let url: string | undefined;
  try {
    const parsed = new URL(document.url);
    if (parsed.protocol === "https:") url = parsed.href;
  } catch {
    /* An unavailable attachment has no open link. */
  }
  return {
    url,
    isImage: Boolean(
      url && document.contentType.startsWith("image/") && failedUrl !== url,
    ),
    onImageError: () => setFailedUrl(url ?? ""),
  };
}
