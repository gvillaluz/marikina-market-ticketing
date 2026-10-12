import { ImageOff } from "lucide-react";
import type { ImgHTMLAttributes, ReactNode } from "react";
import SkeletonBlock from "@/components/ui/Skeleton/SkeletonBlock";
import { useUrlImage } from "./useUrlImage";
import styles from "./UrlImage.module.css";

interface UrlImageProps extends Omit<
  ImgHTMLAttributes<HTMLImageElement>,
  "src"
> {
  src?: string | null;
  fallback?: ReactNode;
  fallbackClassName?: string;
  fit?: "cover" | "contain";
}

export default function UrlImage({
  src,
  alt = "",
  className = "",
  fallbackClassName,
  fallback,
  fit = "cover",
  onLoad,
  onError,
  ...props
}: UrlImageProps) {
  const image = useUrlImage(src);
  const failed = image.status === "error";
  return (
    <span
      className={[
        styles.frame,
        styles[fit],
        image.status === "loading" ? styles.loading : "",
        failed ? (fallbackClassName ?? className) : className,
      ]
        .filter(Boolean)
        .join(" ")}
      aria-busy={image.status === "loading"}
      role={failed && alt ? "img" : undefined}
      aria-label={failed && alt ? alt : undefined}
    >
      {!failed && (
        <img
          {...props}
          key={image.src}
          ref={image.imageRef}
          className={styles.image}
          src={image.src}
          alt={alt}
          onLoad={(event) => {
            image.onLoad(event);
            onLoad?.(event);
          }}
          onError={(event) => {
            image.onError(event);
            onError?.(event);
          }}
        />
      )}
      {image.status === "loading" && (
        <span className={styles.skeleton} aria-hidden="true">
          <SkeletonBlock width="100%" height="100%" radius="inherit" />
        </span>
      )}
      {failed &&
        (fallback ?? (
          <span className={styles.fallback}>
            <ImageOff size={20} aria-hidden="true" />
            <span>Image unavailable</span>
          </span>
        ))}
    </span>
  );
}
