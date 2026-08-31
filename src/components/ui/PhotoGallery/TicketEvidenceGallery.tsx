import { useState } from 'react';
import styles from './TicketEvidenceGallery.module.css';
import Lightbox from 'yet-another-react-lightbox';
import { Thumbnails, Zoom } from 'yet-another-react-lightbox/plugins';
import { createPortal } from 'react-dom';
import 'yet-another-react-lightbox/styles.css';
import 'yet-another-react-lightbox/plugins/thumbnails.css';

interface TicketGalleryProps {
  images: string[];
}

function TicketEvidenceGallery({ images }: TicketGalleryProps) {
  const [isOpen, setIsOpen] = useState(false);
  const [index, setIndex] = useState(0);

  const slides = images.map((src) => ({ src }));

  return <div className={styles.imageContainer}>
      {images.length <= 0 
        ? (
            <span>No photo evidence available</span>
        ) : (
            images.map((url, i) => (
              <img 
                key={i}
                src={url}
                className={styles.evidence}
                onClick={() => {
                  setIndex(i);
                  setIsOpen(true)
                }}
              />
            ))
      )}

      {isOpen &&
        createPortal(
          <Lightbox
            open={isOpen}
            close={() => setIsOpen(false)}
            index={index}
            slides={slides}
            plugins={[Zoom, Thumbnails]}
            render={
              images.length <= 1
                ? { buttonPrev: () => null, buttonNext: () => null }
                : undefined
            }
            zoom={{
              scrollToZoom: false,
            }}
            className={styles.gallery}
          />,
          document.body
        )}
  </div>
}

export default TicketEvidenceGallery;