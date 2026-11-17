import { roleHomePath } from "@/utils/roles";
import { FC } from "react";
import { Navigate } from "react-router-dom";
import { useAuth } from "@/context/AuthContext";
import LoginForm from "@/features/auth/components/LoginForm";
import { useLogin } from "@/features/auth/hooks/useLogin";

const AdminLoginPage: FC = () => {
  const { isAuthenticated, user } = useAuth();
  const login = useLogin();

  if (isAuthenticated && user?.role) {
    return <Navigate to={roleHomePath(user.role)} replace />;
  }

  return <LoginForm {...login} />;
};

export default AdminLoginPage;
