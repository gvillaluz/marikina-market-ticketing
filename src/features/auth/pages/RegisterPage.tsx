import { FC } from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '@/context/AuthContext';
import RegisterForm from '@/features/auth/components/RegisterForm';
import styles from './AuthPage.module.css';
import useRegister from '@/features/auth/hooks/useRegister';

const RegisterPage: FC = () => {
  const { isAuthenticated } = useAuth();
  const registration = useRegister();
  if (isAuthenticated) return <Navigate to="/dashboard" replace />;

  return (
    <div className={styles.page}>
      <RegisterForm {...registration} />
    </div>
  );
};

export default RegisterPage;
