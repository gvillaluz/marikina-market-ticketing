import { useState } from "react";

export function useAccountAvatar(profileUrl: string | null) {
  const [failedUrl, setFailedUrl] = useState<string | null>(null);
  let safeUrl: string | undefined;
  try {
    const url = new URL(profileUrl ?? "");
    if (url.protocol === "https:") safeUrl = url.href;
  } catch {
    /* Missing or invalid images use initials. */
  }
  return {
    src: safeUrl && failedUrl !== profileUrl ? safeUrl : undefined,
    onError: () => setFailedUrl(profileUrl),
  };
}
