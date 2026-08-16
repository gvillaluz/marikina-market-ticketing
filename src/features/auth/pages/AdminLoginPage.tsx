import { FC } from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '@/context/AuthContext';
import AuthLayout from '@/features/auth/components/AuthLayout';
import LoginForm from '@/features/auth/components/LoginForm';

const AdminLoginPage: FC = () => {
  const { isAuthenticated, user } = useAuth();

  if (isAuthenticated && user?.role === 'Admin') {
    return <Navigate to="/dashboard" replace />;
  }

  return (
    <AuthLayout subtext="Admin Access" showBackHome={false}>
      <LoginForm role="Admin" showRegisterLink={false} />
    </AuthLayout>
  );
};

export default AdminLoginPage;
