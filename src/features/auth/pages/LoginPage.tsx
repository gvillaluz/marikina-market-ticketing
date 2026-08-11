import { FC } from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '@/context/AuthContext';
import AuthLayout from '@/features/auth/components/AuthLayout';
import LoginForm from '@/features/auth/components/LoginForm';

const LoginPage: FC = () => {
  const { isAuthenticated } = useAuth();
  if (isAuthenticated) return <Navigate to="/dashboard" replace />;

  return (
    <AuthLayout subtext="Vendor Access" showBackHome>
      <LoginForm />
    </AuthLayout>
  );
};

export default LoginPage;
