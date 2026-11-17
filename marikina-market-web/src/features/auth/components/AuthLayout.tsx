import { FC } from "react";
import { Outlet } from "react-router-dom";
import { ChartColumn, ClipboardCheck, Store } from "lucide-react";
import citySeal from "@/assets/icons/Marikina_City_Seal.svg (1).webp";
import { useAuthSlide } from "../hooks/useAuthSlide";
import styles from "./AuthLayout.module.css";

const features = [
  {
    Icon: ClipboardCheck,
    text: "Inspections and tickets recorded in the field",
  },
  { Icon: Store, text: "Business and person records kept together" },
  { Icon: ChartColumn, text: "Reports, analytics and a full audit trail" },
];

const AuthLayout: FC = () => {
  const slide = useAuthSlide();
  return (
    <div className={styles.page}>
      <div className={styles.panelBackground} aria-hidden="true">
        <img className={styles.watermark} src={citySeal} alt="" />
      </div>

      <div className={styles.panel}>
        <div className={styles.brand}>
          <img
            className={styles.seal}
            src={citySeal}
            alt="Marikina City seal"
          />
          <h1 className={styles.brandTitle}>
            <span className={styles.brandName}>Marikina Public Market</span>
            <span className={styles.brandSystem}>Inspection System</span>
          </h1>
        </div>

        <div className={styles.intro}>
          <p className={styles.eyebrow}>MARIKINA CITY · PUBLIC MARKET</p>
          <p className={styles.headline}>
            Market inspections, tickets and records in one place.
          </p>
          <ul className={styles.features}>
            {features.map(({ Icon, text }) => (
              <li key={text} className={styles.feature}>
                <span className={styles.featureIcon}>
                  <Icon size={20} aria-hidden="true" />
                </span>
                {text}
              </li>
            ))}
          </ul>
        </div>
      </div>

      <main className={styles.content}>
        <div className={styles.contentInner}>
          <div
            key={slide.pathname}
            className={styles.slide}
            data-direction={slide.direction ?? undefined}
          >
            <Outlet />
          </div>
        </div>
      </main>

      <p className={styles.note}>
        Need an account? Ask your Head Admin to add one for you.
      </p>
    </div>
  );
};

export default AuthLayout;
