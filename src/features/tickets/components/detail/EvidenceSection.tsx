import UrlImage, { useImagePreview } from "@/components/ui/UrlImage";
import styles from "./EvidenceSection.module.css";
import { createPortal } from "react-dom";
import Lightbox from "yet-another-react-lightbox";
import { Thumbnails, Zoom } from "yet-another-react-lightbox/plugins";

interface EvidenceProps {
  images: string[];
}

function EvidenceSection({ images }: EvidenceProps) {
  const gallery = useImagePreview(images);

  return (
    <div className={styles.imageContainer}>
      {gallery.urls.map((url, i) => (
        <button
          className={styles.preview}
          key={url}
          type="button"
          aria-label={`View evidence photo ${i + 1}`}
          disabled={gallery.isFailed(url)}
          onClick={() => gallery.open(url)}
        >
          <UrlImage
            src={url}
            className={styles.evidence}
            alt={`Evidence photo ${i + 1}`}
            loading="lazy"
            onError={() => gallery.onError(url)}
          />
        </button>
      ))}

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

export default EvidenceSection;
