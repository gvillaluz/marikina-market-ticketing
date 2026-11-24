import citySeal from "@/assets/icons/Marikina_City_Seal.svg (1).webp";
import styles from "./PaperSeal.module.css";

// The city seal at the left of a report paper's title.
export default function PaperSeal() {
  return (
    <img className={styles.seal} src={citySeal} alt="Marikina City seal" />
  );
}
