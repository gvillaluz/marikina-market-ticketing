import { useEffect, useId, useRef, useState } from "react";
import { FileText, Image as ImageIcon, UploadCloud, X } from "lucide-react";
import styles from "./FormField.module.css";

interface FileUploadProps {
  label: string;
  description: string;
  error?: string;
  required?: boolean;
  file: File | null;
  onChange: (file: File | null) => void;
}

export default function FileUpload({
  label,
  description,
  error,
  required,
  file,
  onChange,
}: FileUploadProps) {
  const inputId = useId();
  const errorId = `${inputId}-error`;
  const inputRef = useRef<HTMLInputElement>(null);
  const [previewUrl, setPreviewUrl] = useState("");

  useEffect(() => {
    if (!file || !file.type.startsWith("image/")) {
      setPreviewUrl("");
      return;
    }
    const url = URL.createObjectURL(file);
    setPreviewUrl(url);
    return () => URL.revokeObjectURL(url);
  }, [file]);

  return (
    <div className={styles.field}>
      <span className={styles.label}>
        {label}
        {required && <span className={styles.required}> *</span>}
      </span>
      <input
        ref={inputRef}
        id={inputId}
        className={styles.fileInput}
        type="file"
        required={required}
        aria-label={label}
        accept=".jpg,.jpeg,.png,.pdf,image/jpeg,image/png,application/pdf"
        aria-invalid={Boolean(error)}
        aria-describedby={error ? errorId : undefined}
        onChange={(event) => {
          onChange(event.currentTarget.files?.[0] ?? null);
          event.currentTarget.value = "";
        }}
      />
      {file ? (
        <div className={`${styles.filePreview} ${error ? styles.invalid : ""}`}>
          {previewUrl ? (
            <img
              className={styles.previewImage}
              src={previewUrl}
              alt={`${label} preview`}
            />
          ) : (
            <span className={styles.fileIcon}>
              {file.type === "application/pdf" ? (
                <FileText size={26} aria-hidden="true" />
              ) : (
                <ImageIcon size={26} aria-hidden="true" />
              )}
            </span>
          )}
          <div className={styles.fileDetails}>
            <strong title={file.name}>{file.name}</strong>
            <span>{(file.size / (1024 * 1024)).toFixed(2)} MB</span>
          </div>
          <button
            type="button"
            className={styles.removeFile}
            onClick={() => {
              onChange(null);
              if (inputRef.current) inputRef.current.value = "";
            }}
            aria-label={`Remove ${label}`}
          >
            <X size={16} />
          </button>
        </div>
      ) : (
        <label
          className={`${styles.uploadBox} ${error ? styles.invalid : ""}`}
          htmlFor={inputId}
        >
          <span className={styles.uploadIcon}>
            <UploadCloud size={22} aria-hidden="true" />
          </span>
          <strong>Upload a clear photo of your {label.toLowerCase()}</strong>
          <span>{description}</span>
          <small>JPG, PNG, or PDF · 5 MB max</small>
        </label>
      )}
      {error && (
        <span id={errorId} className={styles.error}>
          {error}
        </span>
      )}
    </div>
  );
}
