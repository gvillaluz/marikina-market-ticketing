import { FC } from "react";
import { Link } from "react-router-dom";
import { Bell, UserRound } from "lucide-react";
import styles from "./Navbar.module.css";

interface NavbarProps {
  onMenuClick: () => void;
  sidebarCollapsed: boolean;
}

const Navbar: FC<NavbarProps> = ({ onMenuClick, sidebarCollapsed }) => {
  return (
    <header className={styles.navbar}>
      <div className={styles.left}>
        <button
          className={styles.menuBtn}
          onClick={onMenuClick}
          aria-label={sidebarCollapsed ? "Expand sidebar" : "Collapse sidebar"}
          aria-expanded={!sidebarCollapsed}
        >
          <span className={styles.hamburger} />
        </button>
        <div className={styles.brand}>
          <span className={styles.brandText}>Marikina Ticketing</span>
        </div>
      </div>

      <div className={styles.right}>
        <Link to="/" className={styles.iconBtn} aria-label="Notifications">
          <Bell size={18} strokeWidth={1.8} aria-hidden="true" />
        </Link>
        <div className={styles.divider} />
        <span
          className={styles.profile}
          role="img"
          aria-label="Profile"
          title="Profile"
        >
          <UserRound
            className={styles.profileIcon}
            size={24}
            strokeWidth={2}
            aria-hidden="true"
          />
        </span>
      </div>
    </header>
  );
};

export default Navbar;
