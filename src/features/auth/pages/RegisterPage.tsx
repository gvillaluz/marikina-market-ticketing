import { FC } from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '@/context/AuthContext';
import RegisterForm from '@/features/auth/components/RegisterForm';
import styles from './AuthPage.module.css';

const RegisterPage: FC = () => {
  const { isAuthenticated } = useAuth();
  if (isAuthenticated) return <Navigate to="/dashboard" replace />;

  return (
    <div className={styles.page}>
      <RegisterForm />
    </div>
  );
};

export default RegisterPage;
