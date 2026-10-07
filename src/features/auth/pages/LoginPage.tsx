import { FC } from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '@/context/AuthContext';
import AuthLayout from '@/features/auth/components/AuthLayout';
import LoginForm from '@/features/auth/components/LoginForm';
import { useLogin } from '@/features/auth/hooks/useLogin';

const LoginPage: FC = () => {
  const { isAuthenticated } = useAuth();
  const login = useLogin({ role: 'Vendor' });
  if (isAuthenticated) return <Navigate to="/dashboard" replace />;

  return (
    <AuthLayout subtext="Vendor Access" showBackHome>
      <LoginForm {...login} />
    </AuthLayout>
  );
};

export default LoginPage;
