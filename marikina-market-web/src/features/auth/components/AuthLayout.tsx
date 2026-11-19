import { FC } from "react";
import { Outlet } from "react-router-dom";
import citySeal from "@/assets/icons/Marikina_City_Seal.svg (1).webp";
import { useAuthSlide } from "../hooks/useAuthSlide";
import styles from "./AuthLayout.module.css";

const roles = [
  {
    name: "Head Admin",
    text: "Everything an Admin Officer does, plus creating and managing staff accounts.",
  },
  {
    name: "Admin Officer",
    text: "Reviews inspections and tickets, keeps business and person records, reads reports.",
  },
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
          <p className={styles.eyebrow}>FOR MARKET ADMINISTRATORS</p>
          <p className={styles.headline}>
            For managing market inspections, tickets and records.
          </p>
          <div className={styles.audience}>
            <ul className={styles.roles}>
              {roles.map(({ name, text }) => (
                <li key={name} className={styles.role}>
                  <span className={styles.roleName}>{name}</span>
                  {text}
                </li>
              ))}
            </ul>
            <p className={styles.fieldNote}>
              Market enforcers record inspections in the field with the phone
              app.
            </p>
          </div>
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
        Need an account? Ask your Head Admin to create one for you.
      </p>
    </div>
  );
};

export default AuthLayout;
