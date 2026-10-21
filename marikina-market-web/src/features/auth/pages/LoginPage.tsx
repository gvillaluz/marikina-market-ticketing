import { roleHomePath } from "@/utils/roles";
import { FC } from "react";
import { Navigate } from "react-router-dom";
import { useAuth } from "@/context/AuthContext";
import AuthLayout from "@/features/auth/components/AuthLayout";
import LoginForm from "@/features/auth/components/LoginForm";
import { useLogin } from "@/features/auth/hooks/useLogin";

const LoginPage: FC = () => {
  const { isAuthenticated, user } = useAuth();
  const login = useLogin();
  if (isAuthenticated && user?.role)
    return <Navigate to={roleHomePath(user.role)} replace />;

  return (
    <AuthLayout subtext="Vendor Access" showBackHome>
      <LoginForm {...login} />
    </AuthLayout>
  );
};

export default LoginPage;
