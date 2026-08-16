import { FC } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '@/context/AuthContext';
import { useTheme } from '@/context/ThemeContext';
import styles from './Navbar.module.css';

interface NavbarProps {
  onMenuClick: () => void;
}

const Navbar: FC<NavbarProps> = ({ onMenuClick }) => {
  const { user, logout } = useAuth();
  const { theme, toggleTheme } = useTheme();

  return (
    <header className={styles.navbar}>
      <div className={styles.left}>
        <button className={styles.menuBtn} onClick={onMenuClick} aria-label="Toggle sidebar">
          <span className={styles.hamburger} />
        </button>
        <div className={styles.brand}>
          <span className={styles.brandMark}>MK</span>
          <span className={styles.brandText}>Marikina<br />Ticketing</span>
        </div>
      </div>

      <div className={styles.right}>
        <button className={styles.iconBtn} onClick={toggleTheme} aria-label="Toggle theme">
          {theme === 'light' ? '🌙' : '☀️'}
        </button>
        <Link to="/" className={styles.iconBtn} aria-label="Notifications">
          🔔
        </Link>
        <div className={styles.divider} />
        <div className={styles.user}>
          <div className={styles.avatar}>{user?.avatar ?? user?.name?.charAt(0) ?? 'U'}</div>
          <div className={styles.userMeta}>
            <span className={styles.userName}>{user?.name}</span>
            <span className={styles.userRole}>{user?.role === 'Admin' ? 'Administrator' : 'Vendor'}</span>
          </div>
        </div>
        <button className={styles.logoutBtn} onClick={logout} title="Sign out">
          ⎋
        </button>
      </div>
    </header>
  );
};

export default Navbar;
