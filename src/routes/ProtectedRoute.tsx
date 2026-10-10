import { FC, ReactNode } from "react";
import { Navigate, useLocation } from "react-router-dom";
import { useAuth } from "@/context/AuthContext";
import { ROUTES } from "./routePaths";
import type { UserRole } from "@/api/types/common.types";
import { USER_ROLES, STAFF_ROLES } from "@/api/types/common.types";
import { roleHomePath } from "@/utils/roles";
import styles from "./ProtectedRoute.module.css";

interface ProtectedRouteProps {
  children: ReactNode;
  roles?: readonly UserRole[];
  redirectTo?: string;
}

const ProtectedRoute: FC<ProtectedRouteProps> = ({
  children,
  roles,
  redirectTo,
}) => {
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
    return (
      <Navigate to={ROUTES.adminLogin} state={{ from: location }} replace />
    );
  }

  if (!user?.role || !USER_ROLES.includes(user.role)) {
    return <Navigate to={ROUTES.adminLogin} replace />;
  }

  const onChangePasswordPage = location.pathname === ROUTES.changePassword;

  if (
    STAFF_ROLES.includes(user.role) &&
    mustChangePassword &&
    !onChangePasswordPage
  ) {
    return <Navigate to={ROUTES.changePassword} replace />;
  }
  if (roles && user.role !== "HeadAdmin" && !roles.includes(user.role)) {
    return <Navigate to={redirectTo ?? roleHomePath(user.role)} replace />;
  }

  return <>{children}</>;
};

export default ProtectedRoute;
