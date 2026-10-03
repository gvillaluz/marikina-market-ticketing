import { FC, ReactNode } from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '@/context/AuthContext';
import { ROUTES } from './routePaths';
import type { UserRole } from '@/api/types/common.types';
import styles from './ProtectedRoute.module.css';

interface ProtectedRouteProps {
  children: ReactNode;
  roles?: UserRole[];
}

const ProtectedRoute: FC<ProtectedRouteProps> = ({ children, roles }) => {
  const { isAuthenticated, isAuthReady, user, mustChangePassword } = useAuth();
  const location = useLocation();

  if (!isAuthReady) {
    return (
      <div role="status" aria-live="polite" className={styles.loading}>
        Restoring your session...
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to={ROUTES.adminLogin} state={{ from: location }} replace />;
  }

  if (roles && (!user?.role || !roles.includes(user.role))) {
    return <Navigate to={ROUTES.adminLogin} replace />;
  }

  const isAdmin = user?.role === 'Admin';
  const onChangePasswordPage = location.pathname === ROUTES.changePassword;

  if (isAdmin && mustChangePassword && !onChangePasswordPage) {
    return <Navigate to={ROUTES.changePassword} replace />;
  }

  return <>{children}</>;
};

export default ProtectedRoute;