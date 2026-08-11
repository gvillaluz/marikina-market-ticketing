import { FC } from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '@/context/AuthContext';
import AuthLayout from '@/features/auth/components/AuthLayout';
import LoginForm from '@/features/auth/components/LoginForm';

const AdminLoginPage: FC = () => {
  const { isAuthenticated, user } = useAuth();
  // If already signed in as an admin, go straight to the dashboard.
  if (isAuthenticated && user?.role === 'admin') {
    return <Navigate to="/dashboard" replace />;
  }

  return (
    <AuthLayout subtext="Admin Access" showBackHome={false}>
      <LoginForm role="admin" showRegisterLink={false} />
    </AuthLayout>
  );
};

export default AdminLoginPage;
