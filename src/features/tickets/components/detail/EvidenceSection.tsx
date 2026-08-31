import { useState } from 'react';
import styles from './EvidenceSection.module.css';
import { createPortal } from 'react-dom';
import Lightbox from 'yet-another-react-lightbox';
import { Thumbnails, Zoom } from 'yet-another-react-lightbox/plugins';

interface EvidenceProps {
    images: string[];
}

function EvidenceSection({ images }: EvidenceProps) {
    const [index, setIndex] = useState(0);
    const [isOpen, setIsOpen] = useState(false);

    const slides = images.map((src) => ({ src }));

    return <div className={styles.imageContainer}>
        {images.map((img, i) => (
            <img 
                key={i}
                src={img}
                className={styles.evidence}
                onClick={() => {
                    setIndex(i);
                    setIsOpen(true)
                }}
            />
        ))}

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

export default EvidenceSection;