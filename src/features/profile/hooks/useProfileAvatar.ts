import { useState } from "react";

export function useProfileAvatar(profileUrl: string | null) {
  const [failedUrl, setFailedUrl] = useState<string | null>(null);
  let safeUrl: string | undefined;
  try {
    const url = new URL(profileUrl ?? "");
    if (url.protocol === "https:" || url.protocol === "http:") {
      safeUrl = url.href;
    }
  } catch {
    safeUrl = undefined;
  }
  return {
    src: failedUrl === profileUrl ? undefined : safeUrl,
    onError: () => setFailedUrl(profileUrl),
  };
}
