import { FC, ReactNode } from "react";
import { Link } from "react-router-dom";
import citySeal from "@/assets/icons/Marikina_City_Seal.svg (1).webp";
import styles from "./AuthLayout.module.css";

interface AuthLayoutProps {
  subtext: string;
  showBackHome?: boolean;
  children: ReactNode;
}

const AuthLayout: FC<AuthLayoutProps> = ({
  subtext,
  showBackHome = true,
  children,
}) => {
  return (
    <div className={`route-motion ${styles.page}`}>
      {showBackHome && (
        <div className={styles.backHomeWrapper}>
          <Link to="/" className={styles.backHome}>
            <span aria-hidden>←</span> Back Home
          </Link>
        </div>
      )}

      <div className={styles.cardArea}>
        <div className={styles.card}>
          <div className={styles.brandPanel}>
            <div className={styles.seal}>
              <img
                className={styles.sealImage}
                src={citySeal}
                alt="Marikina City seal"
              />
            </div>
            <h1 className={styles.brandTitle}>
              Marikina Public Market Inspection System
            </h1>
            <p className={styles.brandSubtext}>{subtext}</p>
          </div>

          <div className={styles.formPanel}>
            {children}
          </div>
        </div>
      </div>
    </div>
  );
};

export default AuthLayout;
