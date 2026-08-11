import { Routes, Route, Navigate } from 'react-router-dom';
import DashboardLayout from '@/components/layout/DashboardLayout';
import ProtectedRoute from './ProtectedRoute';
import { ROUTES } from './routePaths';
import type { UserRole } from '@/api/types/common.types';
import LandingPage from '@/features/landing/pages/LandingPage';
import LoginPage from '@/features/auth/pages/LoginPage';
import AdminLoginPage from '@/features/auth/pages/AdminLoginPage';
import DashboardPage from '@/features/dashboard/pages/DashboardPage';
import AdminPlaceholderPage from '@/features/dashboard/pages/AdminPlaceholderPage';
import TicketsPage from '@/features/tickets/pages/TicketsPage';
import TicketDetailPage from '@/features/tickets/pages/TicketDetailPage';
import VendorsPage from '@/features/vendors/pages/VendorsPage';
import VendorDetailPage from '@/features/vendors/pages/VendorDetailPage';
import VendorRegistrationPage from '@/features/vendors/pages/VendorRegistrationPage';
import PenaltiesPage from '@/features/penalties/pages/PenaltiesPage';
import CompliancePage from '@/features/compliance/pages/CompliancePage';

/** Roles permitted to reach the admin dashboard shell. */
const ADMIN_ENFORCER_ROLES: UserRole[] = ['admin', 'enforcer'];

/** Only admins may view the dashboard itself. */
const ADMIN_ONLY_ROLES: UserRole[] = ['admin'];

const AppRoutes = () => {
  return (
    <Routes>
      {/* Public routes — kept unwrapped so they never require auth */}
      <Route path={ROUTES.home} element={<LandingPage />} />
      <Route path={ROUTES.login} element={<LoginPage />} />
      <Route path={ROUTES.adminLogin} element={<AdminLoginPage />} />
      <Route path={ROUTES.register} element={<VendorRegistrationPage />} />

      {/* Protected admin/enforcer app routes */}
      <Route
        element={
          <ProtectedRoute roles={ADMIN_ENFORCER_ROLES}>
            <DashboardLayout />
          </ProtectedRoute>
        }
      >
        <Route path={ROUTES.dashboard} element={<DashboardPage />} />
        <Route path={ROUTES.inspections} element={<AdminPlaceholderPage title="Inspections" />} />
        <Route path={ROUTES.tickets} element={<TicketsPage />} />
        <Route path={ROUTES.ticketDetail(':id')} element={<TicketDetailPage />} />
        <Route path={ROUTES.analytics} element={<AdminPlaceholderPage title="Analytics" />} />
        <Route path={ROUTES.performance} element={<AdminPlaceholderPage title="Performance" />} />
      </Route>

      {/* Protected routes for other staff (vendors, enforcers, admins) */}
      <Route
        element={
          <ProtectedRoute>
            <DashboardLayout />
          </ProtectedRoute>
        }
      >
        <Route path={ROUTES.vendors} element={<VendorsPage />} />
        <Route path={ROUTES.vendorDetail(':id')} element={<VendorDetailPage />} />
        <Route path={ROUTES.vendorRegister} element={<VendorRegistrationPage />} />
        <Route path={ROUTES.penalties} element={<PenaltiesPage />} />
        <Route path={ROUTES.compliance} element={<CompliancePage />} />
      </Route>

      {/* Fallback */}
      <Route path="*" element={<Navigate to={ROUTES.adminLogin} replace />} />
    </Routes>
  );
};

export default AppRoutes;
