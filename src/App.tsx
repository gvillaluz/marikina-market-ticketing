import AppRoutes from './routes/AppRoutes';
import ErrorBoundary from './components/feedback/ErrorBoundary';
import { useAuth } from './context/AuthContext';
import { useAdminPushNotifications } from './features/notifications/hooks/useAdminPushNotifications';

export default function App() {
  const { user, isAuthenticated, isAuthReady } = useAuth();
  useAdminPushNotifications({ user, isAuthenticated, isAuthReady });

  return (
    <ErrorBoundary>
      <AppRoutes />
    </ErrorBoundary>
  );
}
