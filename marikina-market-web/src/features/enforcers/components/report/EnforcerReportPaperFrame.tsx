import type { ReactNode, RefObject } from "react";
import PaperSeal from "@/components/ui/PaperSeal/PaperSeal";
import styles from "./EnforcerReportPaperFrame.module.css";

interface MetaItem {
  term: string;
  value: string;
}

// The printable sheet shared by both enforcer reports: letterhead, details, content, signatures and footer.
export default function EnforcerReportPaperFrame({
  paperRef,
  title,
  meta,
  children,
}: {
  paperRef: RefObject<HTMLElement>;
  title: string;
  meta: MetaItem[];
  children: ReactNode;
}) {
  return (
    <article ref={paperRef} className={styles.paper} aria-label={title}>
      <header className={styles.header}>
        <PaperSeal />
        <div>
          <h3>Marikina Public Market Administration</h3>
          <p>{title}</p>
        </div>
      </header>
      <dl className={styles.meta}>
        {meta.map((item) => (
          <div key={item.term}>
            <dt>{item.term}</dt>
            <dd>{item.value}</dd>
          </div>
        ))}
      </dl>
      {children}
      <div className={styles.signatures}>
        <div>
          <span className={styles.signatureLine} />
          <span>Prepared by (name and signature)</span>
        </div>
        <div>
          <span className={styles.signatureLine} />
          <span>Reviewed by (name and signature)</span>
        </div>
      </div>
      <footer className={styles.footer}>
        <span>Dates inclusive · Philippine time</span>
        <span>Settled tickets are paid, cleared or waived</span>
      </footer>
    </article>
  );
}
