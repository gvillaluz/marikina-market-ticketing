import { Expand, ImageOff } from "lucide-react";
import type { TicketSettlementPhoto as SettlementPhoto } from "@/features/tickets";
import { formatDate, formatNumber } from "@/utils/formatters";
import UrlImage from "@/components/ui/UrlImage";
import styles from "./TicketSettlementPhoto.module.css";

interface TicketSettlementPhotoProps {
  photo: SettlementPhoto;
  variant: "receipt" | "service";
  number: number;
  unavailable: boolean;
  onOpen: () => void;
  onError: () => void;
}

export default function TicketSettlementPhoto({
  photo,
  variant,
  number,
  unavailable,
  onOpen,
  onError,
}: TicketSettlementPhotoProps) {
  const label =
    variant === "receipt"
      ? `Settlement receipt ${number}`
      : `Community service photo ${number}`;
  return (
    <article
      className={[styles.card, styles[variant]].filter(Boolean).join(" ")}
    >
      <button
        className={styles.preview}
        type="button"
        onClick={onOpen}
        disabled={unavailable}
        aria-label={`View ${label.toLowerCase()}`}
      >
        <UrlImage
          className={styles.image}
          src={photo.url}
          alt={label}
          loading="lazy"
          onError={onError}
          fallback={
            <span className={styles.unavailable}>
              <ImageOff size={24} aria-hidden="true" />
              Photo unavailable
            </span>
          }
        />
        {!unavailable && (
          <span className={styles.expand}>
            <Expand size={16} aria-hidden="true" />
          </span>
        )}
      </button>
      {variant === "service" && (
        <div className={styles.metadata}>
          <span>
            {photo.date
              ? formatDate(photo.date, {
                  month: "2-digit",
                  day: "2-digit",
                  timeZone: "Asia/Manila",
                })
              : "Date unavailable"}
          </span>
          <span className={styles.hours}>
            {photo.hours === null
              ? "Hours unavailable"
              : `${formatNumber(photo.hours)} ${photo.hours === 1 ? "hr" : "hrs"}`}
          </span>
        </div>
      )}
    </article>
  );
}
