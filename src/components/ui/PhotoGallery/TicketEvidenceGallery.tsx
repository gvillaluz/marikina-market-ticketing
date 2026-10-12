import UrlImage, { useImagePreview } from "@/components/ui/UrlImage";
import styles from "./TicketEvidenceGallery.module.css";
import Lightbox from "yet-another-react-lightbox";
import { Thumbnails, Zoom } from "yet-another-react-lightbox/plugins";
import { createPortal } from "react-dom";
import "yet-another-react-lightbox/styles.css";
import "yet-another-react-lightbox/plugins/thumbnails.css";

interface TicketGalleryProps {
  images: string[];
}

function TicketEvidenceGallery({ images }: TicketGalleryProps) {
  const gallery = useImagePreview(images);

  return (
    <div className={styles.imageContainer}>
      {gallery.urls.length <= 0 ? (
        <span>No photo evidence available</span>
      ) : (
        gallery.urls.map((url, i) => (
          <button
            key={url}
            className={styles.preview}
            type="button"
            aria-label={`View photo evidence ${i + 1}`}
            disabled={gallery.isFailed(url)}
            onClick={() => gallery.open(url)}
          >
            <UrlImage
              src={url}
              className={styles.evidence}
              alt={`Photo evidence ${i + 1}`}
              loading="lazy"
              onError={() => gallery.onError(url)}
            />
          </button>
        ))
      )}

      {gallery.isOpen &&
        createPortal(
          <Lightbox
            open={gallery.isOpen}
            close={gallery.close}
            index={gallery.index}
            slides={gallery.slides}
            plugins={[Zoom, Thumbnails]}
            render={
              gallery.slides.length <= 1
                ? { buttonPrev: () => null, buttonNext: () => null }
                : undefined
            }
            zoom={{
              scrollToZoom: false,
            }}
            className={styles.gallery}
          />,
          document.body,
        )}
    </div>
  );
}

export default TicketEvidenceGallery;
