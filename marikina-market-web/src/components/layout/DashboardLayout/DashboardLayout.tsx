import { FC, useState } from 'react';
import { Outlet, useLocation } from 'react-router-dom';
import Navbar from '@/components/layout/Navbar';
import Sidebar from '@/components/layout/Sidebar';
import styles from './DashboardLayout.module.css';

const DashboardLayout: FC = () => {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);
  const location = useLocation();

  return (
    <div className={styles.layout}>
      <Sidebar
        open={sidebarOpen}
        collapsed={sidebarCollapsed}
        onClose={() => setSidebarOpen(false)}
      />
      <div className={styles.main}>
        <Navbar
          onMenuClick={() => {
            if (window.innerWidth <= 768) {
              setSidebarOpen((v) => !v);
            } else {
              setSidebarCollapsed((v) => !v);
            }
          }}
          sidebarCollapsed={sidebarCollapsed}
        />
        <main className={styles.content}>
          <div key={location.pathname} className="route-motion">
            <Outlet />
          </div>
        </main>
      </div>
    </div>
  );
};

export default DashboardLayout;
