import { Routes, Route, Navigate } from 'react-router-dom';
import DashboardLayout from '@/components/layout/DashboardLayout';
import ProtectedRoute from './ProtectedRoute';
import { ROUTES } from './routePaths';
import type { UserRole } from '@/api/types/common.types';
import LandingPage from '@/features/landing/pages/LandingPage';
import LoginPage from '@/features/auth/pages/LoginPage';
import AdminLoginPage from '@/features/auth/pages/AdminLoginPage';
import ChangePasswordPage from '@/features/auth/pages/ChangePasswordPage';
import { DashboardPage } from '../features/dashboard/pages/DashboardPage';import AdminPlaceholderPage from '@/features/dashboard/pages/AdminPlaceholderPage';
import TicketsPage from '@/features/tickets/pages/TicketsPage';
import TicketDetailPage from '@/features/tickets/pages/TicketDetailPage';
import VendorsPage from '@/features/vendors/pages/VendorPage';
import VendorDetailPage from '@/features/vendors/pages/VendorDetailPage';
import VendorRegistrationPage from '@/features/vendors/pages/VendorRegistrationPage';
import PenaltiesPage from '@/features/penalties/pages/PenaltiesPage';
import CompliancePage from '@/features/compliance/pages/CompliancePage';
import { InspectionsPage } from '../features/inspections/pages/InspectionsPage';

const ADMIN_ENFORCER_ROLES: UserRole[] = ['Admin', 'Enforcer'];
const ADMIN_ONLY_ROLES: UserRole[] = ['Admin'];

const AppRoutes = () => {
  return (
    <Routes>
      {/* Public routes — kept unwrapped so they never require auth */}
      <Route path={ROUTES.home} element={<LandingPage />} />
      <Route path={ROUTES.login} element={<LoginPage />} />
      <Route path={ROUTES.adminLogin} element={<AdminLoginPage />} />
      <Route path={ROUTES.register} element={<VendorRegistrationPage />} />

      {/* Standalone change-password route — NOT nested in DashboardLayout,
          so it renders full-screen without the sidebar, like the login pages */}
      <Route
        path={ROUTES.changePassword}
        element={
          <ProtectedRoute roles={ADMIN_ENFORCER_ROLES}>
            <ChangePasswordPage />
          </ProtectedRoute>
        }
      />

      {/* Admin/Enforcer protected routes */}
      <Route
        element={
          <ProtectedRoute roles={ADMIN_ENFORCER_ROLES}>
            <DashboardLayout />
          </ProtectedRoute>
        }
      >
     <Route path={ROUTES.dashboard} element={<DashboardPage />} />
    <Route path={ROUTES.tickets} element={<TicketsPage />} />
    <Route path={ROUTES.ticketDetail(':id')} element={<TicketDetailPage />} />
        <Route path={ROUTES.analytics} element={<AdminPlaceholderPage title="Analytics" />} />
        <Route path={ROUTES.inspections} element={<InspectionsPage />} />
        <Route path={ROUTES.performance} element={<AdminPlaceholderPage title="Performance" />} />
      </Route>

      {/* General authenticated routes (any role) */}
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

      {/* Catch-all */}
      <Route path="*" element={<Navigate to={ROUTES.adminLogin} replace />} />
    </Routes>
  );
};

export default AppRoutes;