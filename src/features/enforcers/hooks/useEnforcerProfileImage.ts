import { useState } from "react";
import type { EnforcerProfile } from "@/api/types/enforcer.types";

export function useEnforcerProfileImage(profile: EnforcerProfile) {
  const [failedUrl, setFailedUrl] = useState<string | null>(null);
  const url =
    typeof profile.profileUrl === "string" ? profile.profileUrl.trim() : "";
  return {
    url,
    hasImage: Boolean(url && failedUrl !== url),
    initials:
      [profile.firstName, profile.lastName]
        .map((part) => part?.trim()[0] || "")
        .join("")
        .toUpperCase() || "E",
    imageFailed() {
      setFailedUrl(url);
    },
  };
}
