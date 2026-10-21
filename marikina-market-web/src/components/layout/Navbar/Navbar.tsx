import { FC } from "react";
import { Link } from "react-router-dom";
import { UserRound } from "lucide-react";
import UrlImage from "@/components/ui/UrlImage";
import { useAuth } from "@/context/AuthContext";
import { useProfileAvatar } from "@/features/profile";
import { ROUTES } from "@/routes/routePaths";
import styles from "./Navbar.module.css";

interface NavbarProps {
  onMenuClick: () => void;
  sidebarCollapsed: boolean;
}

const Navbar: FC<NavbarProps> = ({ onMenuClick, sidebarCollapsed }) => {
  const { user } = useAuth();
  const avatar = useProfileAvatar(user?.profileUrl ?? null);

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
        <Link
          to={ROUTES.profile}
          className={styles.profile}
          aria-label="Profile"
          title="Profile"
        >
          <UrlImage
            src={avatar.src}
            alt=""
            onError={avatar.onError}
            referrerPolicy="no-referrer"
            fallback={
              <UserRound
                className={styles.profileIcon}
                size={20}
                strokeWidth={2}
                aria-hidden="true"
              />
            }
          />
        </Link>
      </div>
    </header>
  );
};

export default Navbar;
