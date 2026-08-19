import { FC } from 'react';
import { NavLink, useLocation } from 'react-router-dom';
import { useAuth } from '@/context/AuthContext';
import citySeal from '@/assets/icons/Marikina_City_Seal.svg (1).webp';
import styles from './Sidebar.module.css';

interface NavItem {
  to: string;
  label: string;
  icon: JSX.Element;
  allowedRoles: ('Admin' | 'Enforcer' | 'Vendor')[];
}

const HouseIcon = (
  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
    <polyline points="9 22 9 12 15 12 15 22" />
  </svg>
);

const DocumentIcon = (
  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
    <polyline points="14 2 14 8 20 8" />
    <line x1="16" y1="13" x2="8" y2="13" />
    <line x1="16" y1="17" x2="8" y2="17" />
  </svg>
);

const TicketIcon = (
  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M2 9a3 3 0 0 1 0 6v2a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-2a3 3 0 0 1 0-6V7a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2z" />
    <path d="M9 12h6" />
  </svg>
);

const BarChartIcon = (
  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <line x1="12" y1="20" x2="12" y2="10" />
    <line x1="18" y1="20" x2="18" y2="4" />
    <line x1="6" y1="20" x2="6" y2="16" />
  </svg>
);

const ChartIcon = (
  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <line x1="18" y1="20" x2="18" y2="10" />
    <line x1="12" y1="20" x2="12" y2="4" />
    <line x1="6" y1="20" x2="6" y2="14" />
  </svg>
);

const NAV_ITEMS: NavItem[] = [
  { to: '/dashboard', label: 'Dashboard', icon: HouseIcon, allowedRoles: ['Admin', 'Enforcer'] },
  { to: '/inspections', label: 'Inspections', icon: DocumentIcon, allowedRoles: ['Admin', 'Enforcer'] },
  { to: '/tickets', label: 'Tickets', icon: TicketIcon, allowedRoles: ['Admin', 'Enforcer'] },
  { to: '/analytics', label: 'Analytics', icon: BarChartIcon, allowedRoles: ['Admin', 'Enforcer'] },
  { to: '/performance', label: 'Performance', icon: ChartIcon, allowedRoles: ['Admin', 'Enforcer'] },
];

interface SidebarProps {
  open: boolean;
  collapsed: boolean;
  onClose: () => void;
}

const Sidebar: FC<SidebarProps> = ({ open, collapsed, onClose }) => {
  const { user, logout } = useAuth();
  const location = useLocation();

  const visibleItems = NAV_ITEMS.filter(
    (item) => user && item.allowedRoles.includes(user.role),
  );

  return (
    <>
      {open && <div className={styles.backdrop} onClick={onClose} />}
      <aside className={`${styles.sidebar} ${open ? styles.open : ''} ${collapsed ? styles.collapsed : ''}`}>
        {/* Brand / seal */}
        <div>
          <div className={styles.brand}>
            <img className={styles.seal} src={citySeal} alt="Marikina City seal" />
            <div>
              <div className={styles.brandText}>Marikina Public Market Inspection System</div>
              <div className={styles.brandSub}>Admin Access</div>
            </div>
          </div>

          {/* Navigation */}
          <div className={styles.section}>
            <nav className={styles.nav}>
              {visibleItems.map((item) => {
                const isActive = location.pathname === item.to;
                return (
                  <NavLink
                    key={item.to}
                    to={item.to}
                    className={`${styles.link} ${isActive ? styles.active : ''}`}
                    onClick={onClose}
                    title={item.label}
                  >
                    <span className={styles.linkIcon}>{item.icon}</span>
                    <span className={styles.linkLabel}>{item.label}</span>
                  </NavLink>
                );
              })}
            </nav>
          </div>
        </div>

        {/* Footer — user pill + log out */}
        <div className={styles.footer}>
          <div className={styles.userPill}>
            <div className={styles.userAvatar}>
              {user?.name?.split(' ').map((n) => n[0]).slice(0, 2).join('').toUpperCase() ?? 'U'}
            </div>
            <span className={styles.userName}>{user?.name ?? 'User'}</span>
          </div>
          <button
            className={styles.logoutBtn}
            onClick={logout}
          >
            Log Out
          </button>
        </div>
      </aside>
    </>
  );
};

export default Sidebar;
