import { useEffect, useId, useRef, useState } from "react";

export function useFileUpload(file: File | null) {
  const inputId = useId();
  const inputRef = useRef<HTMLInputElement>(null);
  const [preview, setPreview] = useState<{ file: File; url: string } | null>(
    null,
  );
  useEffect(() => {
    if (!file || !file.type.startsWith("image/")) {
      setPreview(null);
      return;
    }
    const url = URL.createObjectURL(file);
    setPreview({ file, url });
    return () => URL.revokeObjectURL(url);
  }, [file]);
  return {
    inputId,
    errorId: `${inputId}-error`,
    inputRef,
    previewUrl: preview?.file === file ? preview.url : "",
  };
}
