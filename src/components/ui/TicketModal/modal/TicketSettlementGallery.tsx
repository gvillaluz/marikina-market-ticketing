import { Image } from "lucide-react";
import Lightbox from "yet-another-react-lightbox";
import { Thumbnails, Zoom } from "yet-another-react-lightbox/plugins";
import "yet-another-react-lightbox/styles.css";
import "yet-another-react-lightbox/plugins/thumbnails.css";
import {
  useTicketSettlementGallery,
  type TicketSettlementPhoto as SettlementPhoto,
} from "@/features/tickets";
import TicketSettlementPhoto from "./TicketSettlementPhoto";
import styles from "./TicketSettlementGallery.module.css";

export default function TicketSettlementGallery({
  photos,
  variant,
}: {
  photos: SettlementPhoto[];
  variant: "receipt" | "service";
}) {
  const gallery = useTicketSettlementGallery(photos);
  const photoCount = photos.filter((photo) => photo.url !== null).length;
  return (
    <div className={`${styles.gallery} ${styles[variant]}`}>
      {variant === "service" && (
        <header className={styles.header}>
          <Image size={16} aria-hidden="true" />
          <h4>Community Service Photos</h4>
          <span className={styles.count}>
            {photoCount} {photoCount === 1 ? "photo" : "photos"}
          </span>
        </header>
      )}
      {photos.length === 0 ? (
        <p className={styles.empty}>
          {variant === "receipt"
            ? "No settlement receipt has been submitted."
            : "No community service logs have been submitted."}
        </p>
      ) : (
        <div className={styles.grid}>
          {photos.map((photo, index) => (
            <TicketSettlementPhoto
              key={photo.key}
              photo={photo}
              variant={variant}
              number={index + 1}
              unavailable={gallery.isUnavailable(photo.url)}
              onOpen={() => gallery.open(photo.url)}
              onError={() => photo.url && gallery.onError(photo.url)}
            />
          ))}
        </div>
      )}
      <Lightbox
        open={gallery.isOpen}
        close={gallery.close}
        index={gallery.index}
        slides={gallery.slides}
        plugins={[Zoom, Thumbnails]}
        carousel={{ finite: gallery.slides.length <= 1 }}
        render={
          gallery.slides.length <= 1
            ? { buttonPrev: () => null, buttonNext: () => null }
            : undefined
        }
        zoom={{ scrollToZoom: false }}
      />
    </div>
  );
}
