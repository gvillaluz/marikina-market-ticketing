import { ExternalLink, FileText } from "lucide-react";
import type { VendorRegistrationDocument } from "@/api/types/admin-vendor.types";
import styles from "./ReviewDocumentCard.module.css";
import { useReviewDocument } from "../../hooks/useReviewDocument";

function displayValue(value: string | number | null | undefined) {
  if (value === null || value === undefined || value === "") return "N/A";
  return String(value).replace(/([a-z])([A-Z])/g, "$1 $2");
}

export default function ReviewDocumentCard({
  document,
}: {
  document: VendorRegistrationDocument;
}) {
  const { url, isImage, onImageError } = useReviewDocument(document);

  return (
    <article className={styles.documentCard}>
      {isImage ? (
        <img
          src={url}
          alt={document.fileName}
          onError={onImageError}
          referrerPolicy="no-referrer"
        />
      ) : (
        <div className={styles.documentPreview}>
          <FileText size={38} />
          <span>{document.contentType}</span>
        </div>
      )}
      <div className={styles.documentInfo}>
        <div>
          <strong>{document.fileName}</strong>
          <span>
            {displayValue(document.documentType)} ·{" "}
            {(document.size / 1024 / 1024).toFixed(1)} MB
          </span>
        </div>
        {url ? (
          <a href={url} target="_blank" rel="noreferrer">
            <ExternalLink size={14} /> Open
          </a>
        ) : (
          <span>Document unavailable</span>
        )}
      </div>
    </article>
  );
}
