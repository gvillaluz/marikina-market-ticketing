import AppRoutes from './routes/AppRoutes';
import ErrorBoundary from './components/feedback/ErrorBoundary';

export default function App() {
  return (
    <ErrorBoundary>
      <AppRoutes />
    </ErrorBoundary>
  );
}
