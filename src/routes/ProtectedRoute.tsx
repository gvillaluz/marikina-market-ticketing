import { FC, ReactNode } from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '@/context/AuthContext';
import { ROUTES } from './routePaths';
import type { UserRole } from '@/api/types/common.types';

interface ProtectedRouteProps {
  children: ReactNode;
  roles?: UserRole[];
}

const ProtectedRoute: FC<ProtectedRouteProps> = ({ children, roles }) => {
  const { isAuthenticated, user } = useAuth();
  const location = useLocation();

  if (!isAuthenticated) {
    return <Navigate to={ROUTES.adminLogin} state={{ from: location }} replace />;
  }

  if (roles && user && !roles.includes(user.role)) {
    
    return <Navigate to={ROUTES.adminLogin} replace />;
  }

  return <>{children}</>;
};

export default ProtectedRoute;
