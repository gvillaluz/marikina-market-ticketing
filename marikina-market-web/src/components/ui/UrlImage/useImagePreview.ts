import { useEffect, useState } from "react";
import { getUrlImageSource } from "./useUrlImage";

export function useImagePreview(images: readonly string[]) {
  const urls = Array.isArray(images)
    ? [
        ...new Set(
          images
            .map(getUrlImageSource)
            .filter((url): url is string => Boolean(url)),
        ),
      ]
    : [];
  const [selectedUrl, setSelectedUrl] = useState<string | null>(null);
  const [failed, setFailed] = useState<string[]>([]);
  const imageKey = urls.join("\n");
  useEffect(() => {
    setSelectedUrl(null);
  }, [imageKey]);
  const available = urls.filter((url) => !failed.includes(url));
  const index = selectedUrl ? available.indexOf(selectedUrl) : -1;
  return {
    urls,
    slides: available.map((src) => ({ src })),
    isOpen: index >= 0,
    index: Math.max(0, index),
    open: (url: string) => {
      if (available.includes(url)) setSelectedUrl(url);
    },
    close: () => setSelectedUrl(null),
    isFailed: (url: string) => !urls.includes(url) || failed.includes(url),
    onError: (url: string) =>
      setFailed((current) =>
        current.includes(url) ? current : [...current, url],
      ),
  };
}
