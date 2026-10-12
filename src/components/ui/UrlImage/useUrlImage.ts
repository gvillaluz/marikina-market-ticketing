import { useLayoutEffect, useRef, useState, type SyntheticEvent } from "react";

export function getUrlImageSource(value: unknown): string | undefined {
  if (typeof value !== "string" || !value.trim()) return undefined;
  const source = value.trim();
  if (source.startsWith("/") && !source.startsWith("//")) return source;
  try {
    const url = new URL(source);
    if (["https:", "http:", "blob:"].includes(url.protocol)) return source;
  } catch {
    // Missing or invalid URLs use the supplied fallback.
  }
  return undefined;
}

export function useUrlImage(source: string | null | undefined) {
  const src = getUrlImageSource(source);
  const imageRef = useRef<HTMLImageElement>(null);
  const [result, setResult] = useState<{
    src: string;
    status: "ready" | "error";
  } | null>(null);
  const status = !src
    ? "error"
    : result?.src === src
      ? result.status
      : "loading";

  useLayoutEffect(() => {
    const image = imageRef.current;
    if (src && image?.complete) {
      setResult({ src, status: image.naturalWidth > 0 ? "ready" : "error" });
    }
  }, [src]);

  return {
    src,
    imageRef,
    status,
    onLoad(event: SyntheticEvent<HTMLImageElement>) {
      if (src && event.currentTarget === imageRef.current)
        setResult({ src, status: "ready" });
    },
    onError(event: SyntheticEvent<HTMLImageElement>) {
      if (src && event.currentTarget === imageRef.current)
        setResult({ src, status: "error" });
    },
  };
}
