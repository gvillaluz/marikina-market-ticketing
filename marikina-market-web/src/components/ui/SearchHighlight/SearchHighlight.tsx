import { searchParts } from "@/utils/searchMatch";
import styles from "./SearchHighlight.module.css";

interface SearchHighlightProps {
  text: string;
  search: string;
}

export default function SearchHighlight({ text, search }: SearchHighlightProps) {
  return (
    <>
      {searchParts(text, search).map((part, index) =>
        part.match ? (
          <mark key={index} className={styles.mark}>
            {part.text}
          </mark>
        ) : (
          part.text
        ),
      )}
    </>
  );
}
