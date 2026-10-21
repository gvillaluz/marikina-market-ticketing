import { useImagePreview, getUrlImageSource } from "@/components/ui/UrlImage";
import type { TicketSettlementPhoto } from "./useTicketSettlement";

export function useTicketSettlementGallery(photos: TicketSettlementPhoto[]) {
  const preview = useImagePreview(
    photos
      .map((photo) => photo.url)
      .filter((url): url is string => url !== null),
  );
  return {
    ...preview,
    open: (url: string | null) => {
      const src = getUrlImageSource(url);
      if (src) preview.open(src);
    },
    isUnavailable: (url: string | null) => {
      const src = getUrlImageSource(url);
      return !src || preview.isFailed(src);
    },
    onError: (url: string) => {
      const src = getUrlImageSource(url);
      if (src) preview.onError(src);
    },
  };
}
