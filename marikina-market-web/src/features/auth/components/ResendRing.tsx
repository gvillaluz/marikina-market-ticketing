import styles from "./ResendRing.module.css";

export default function ResendRing({ progress }: { progress: number }) {
  return (
    <svg className={styles.ring} viewBox="0 0 20 20" aria-hidden="true">
      <circle className={styles.track} cx="10" cy="10" r="8" />
      <circle
        className={styles.fill}
        cx="10"
        cy="10"
        r="8"
        pathLength="100"
        strokeDasharray="100"
        strokeDashoffset={100 * (1 - progress)}
      />
    </svg>
  );
}
