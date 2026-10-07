import { ExternalLink, FileText } from "lucide-react";
import type { VendorRegistrationDocument } from "@/api/types/admin-vendor.types";
import styles from "../AdminVendorRegistrationReviewPage.module.css";

function displayValue(value: string | number | null | undefined) {
  if (value === null || value === undefined || value === "") return "N/A";
  return String(value).replace(/([a-z])([A-Z])/g, "$1 $2");
}

export default function ReviewDocumentCard({
  document,
}: {
  document: VendorRegistrationDocument;
}) {
  const isImage = document.contentType.startsWith("image/");

  return (
    <article className={styles.documentCard}>
      {isImage ? (
        <img src={document.url} alt={document.fileName} />
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
        <a href={document.url} target="_blank" rel="noreferrer">
          <ExternalLink size={14} /> Open
        </a>
      </div>
    </article>
  );
}
