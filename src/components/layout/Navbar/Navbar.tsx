import { FC } from 'react';
import { Link } from 'react-router-dom';
import { Bell, UserRound } from 'lucide-react';
import { useAuth } from '@/context/AuthContext';
import styles from './Navbar.module.css';

interface NavbarProps {
  onMenuClick: () => void;
  sidebarCollapsed: boolean;
}

const Navbar: FC<NavbarProps> = ({ onMenuClick, sidebarCollapsed }) => {
  const { user } = useAuth();

  return (
    <header className={styles.navbar}>
      <div className={styles.left}>
        <button
          className={styles.menuBtn}
          onClick={onMenuClick}
          aria-label={sidebarCollapsed ? 'Expand sidebar' : 'Collapse sidebar'}
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
        <div className={styles.user}>
          <UserRound className={styles.profileIcon} size={20} strokeWidth={1.8} aria-hidden="true" />
          <div className={styles.userMeta}>
            <span className={styles.userName}>{user?.name}</span>
          </div>
        </div>
      </div>
    </header>
  );
};

export default Navbar;
