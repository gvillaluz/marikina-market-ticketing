import SkeletonBlock from "@/components/ui/Skeleton/SkeletonBlock";
import styles from "./AccountRowsSkeleton.module.css";

export default function AccountRowsSkeleton() {
  return (
    <>
      {Array.from({ length: 5 }, (_, index) => (
        <tr key={index} className={styles.row} aria-hidden="true">
          <td>
            <div className={styles.identity}>
              <SkeletonBlock width="2.25rem" height="2.25rem" radius="50%" />
              <div className={styles.lines}>
                <SkeletonBlock width="7rem" />
                <SkeletonBlock width="5rem" height="0.5rem" />
              </div>
            </div>
          </td>
          <td>
            <SkeletonBlock width="5rem" height="1.25rem" />
          </td>
          <td>
            <div className={styles.lines}>
              <SkeletonBlock width="9rem" />
              <SkeletonBlock width="6rem" height="0.5rem" />
            </div>
          </td>
          <td>
            <SkeletonBlock width="4rem" height="1.5rem" radius="1rem" />
          </td>
          <td>
            <SkeletonBlock width="4rem" height="1.75rem" />
          </td>
        </tr>
      ))}
    </>
  );
}
