import { Routes, Route, Navigate } from "react-router-dom";
import DashboardLayout from "@/components/layout/DashboardLayout";
import ProtectedRoute from "./ProtectedRoute";
import { ROUTES } from "./routePaths";
import {
  ADMIN_ROLES,
  STAFF_ROLES,
  HEAD_ADMIN_ROLES,
} from "@/api/types/common.types";
import LandingPage from "@/features/landing/pages/LandingPage";
import LoginPage from "@/features/auth/pages/LoginPage";
import AdminLoginPage from "@/features/auth/pages/AdminLoginPage";
import LoginVerificationPage from "@/features/auth/pages/LoginVerificationPage";
import ForgotPasswordPage from "@/features/auth/pages/ForgotPasswordPage";
import ChangePasswordPage from "@/features/auth/pages/ChangePasswordPage";
import { DashboardPage } from "../features/dashboard/pages/DashboardPage";
import TicketsPage from "@/features/tickets/pages/TicketsPage";
import TicketDetailPage from "@/features/tickets/pages/TicketDetailPage";
import VendorsPage from "@/features/vendors/pages/VendorPage";
import VendorDetailPage from "@/features/vendors/pages/VendorDetailPage";
import VendorRegistrationPage from "@/features/vendors/pages/VendorRegistrationPage";
import { InspectionsPage } from "../features/inspections/pages/InspectionsPage";
import EnforcersPage from "@/features/enforcers/pages/EnforcersPage";
import EnforcerPerformancePage from "@/features/enforcers/pages/EnforcerPerformancePage";
import AdminVendorsPage from "@/features/vendors/pages/AdminVendorsPage";
import AdminVendorInspectionPage from "@/features/vendors/pages/AdminVendorInspectionPage";
import AdminVendorRegistrationsPage from "@/features/vendors/pages/AdminVendorRegistrationsPage";
import AdminVendorRegistrationReviewPage from "@/features/vendors/pages/AdminVendorRegistrationReviewPage";
import AdminVendorRegistrationApprovePage from "@/features/vendors/pages/AdminVendorRegistrationApprovePage";
import AdminVendorRegistrationDeclinePage from "@/features/vendors/pages/AdminVendorRegistrationDeclinePage";
import AdminVendorRegistrationInformationPage from "@/features/vendors/pages/AdminVendorRegistrationInformationPage";
import AdminAnalyticsPage from "@/features/analytics/pages/AdminAnalyticsPage";
import SystemConfigurationPage from "@/features/configuration/pages/SystemConfigurationPage";
import MarketSectionPage from "@/features/market-section/pages/MarketSectionPage";
import { OrdinancesPage } from "@/features/ordinances";
import { BackupsPage } from "@/features/backups";
import { AccountsPage } from "@/features/accounts";

const AppRoutes = () => {
  return (
    <Routes>
      {/* Public routes — kept unwrapped so they never require auth */}
      <Route path={ROUTES.home} element={<LandingPage />} />
      <Route path={ROUTES.login} element={<LoginPage />} />
      <Route path={ROUTES.adminLogin} element={<AdminLoginPage />} />
      <Route
        path={ROUTES.loginVerification}
        element={<LoginVerificationPage />}
      />
      <Route
        path={`${ROUTES.forgotPassword("vendor")}/:step?`}
        element={<ForgotPasswordPage />}
      />
      <Route
        path={`${ROUTES.forgotPassword("staff")}/:step?`}
        element={<ForgotPasswordPage />}
      />
      <Route path={ROUTES.register} element={<VendorRegistrationPage />} />

      {/* Standalone change-password route — NOT nested in DashboardLayout,
          so it renders full-screen without the sidebar, like the login pages */}
      <Route
        path={ROUTES.changePassword}
        element={
          <ProtectedRoute roles={STAFF_ROLES}>
            <ChangePasswordPage />
          </ProtectedRoute>
        }
      />

      {/* Admin/Enforcer protected routes */}
      <Route
        element={
          <ProtectedRoute roles={STAFF_ROLES}>
            <DashboardLayout />
          </ProtectedRoute>
        }
      >
        <Route path={ROUTES.dashboard} element={<DashboardPage />} />
        <Route
          path={ROUTES.accounts}
          element={
            <ProtectedRoute roles={HEAD_ADMIN_ROLES}>
              <AccountsPage />
            </ProtectedRoute>
          }
        />
        <Route path={ROUTES.tickets} element={<TicketsPage />} />
        <Route
          path={ROUTES.ticketDetail(":id")}
          element={<TicketDetailPage />}
        />
        <Route path={ROUTES.enforcers} element={<EnforcersPage />} />
        <Route
          path={ROUTES.adminVendors}
          element={
            <ProtectedRoute roles={ADMIN_ROLES}>
              <AdminVendorsPage />
            </ProtectedRoute>
          }
        />
        <Route
          path={ROUTES.adminVendorRegistrations}
          element={
            <ProtectedRoute roles={ADMIN_ROLES}>
              <AdminVendorRegistrationsPage />
            </ProtectedRoute>
          }
        />
        <Route
          path={ROUTES.adminVendorRegistration(":registrationId")}
          element={
            <ProtectedRoute roles={ADMIN_ROLES}>
              <AdminVendorRegistrationReviewPage />
            </ProtectedRoute>
          }
        />
        <Route
          path={ROUTES.adminVendorRegistrationApprove(":registrationId")}
          element={
            <ProtectedRoute roles={ADMIN_ROLES}>
              <AdminVendorRegistrationApprovePage />
            </ProtectedRoute>
          }
        />
        <Route
          path={ROUTES.adminVendorRegistrationDecline(":registrationId")}
          element={
            <ProtectedRoute roles={ADMIN_ROLES}>
              <AdminVendorRegistrationDeclinePage />
            </ProtectedRoute>
          }
        />
        <Route
          path={ROUTES.adminVendorRegistrationInformation(":registrationId")}
          element={
            <ProtectedRoute roles={ADMIN_ROLES}>
              <AdminVendorRegistrationInformationPage />
            </ProtectedRoute>
          }
        />
        <Route
          path={ROUTES.adminVendorInspections(":vendorId")}
          element={
            <ProtectedRoute roles={ADMIN_ROLES}>
              <AdminVendorInspectionPage />
            </ProtectedRoute>
          }
        />
        <Route
          path={ROUTES.enforcerPerformancePage(":id")}
          element={<EnforcerPerformancePage />}
        />
        <Route
          path={ROUTES.analytics}
          element={
            <ProtectedRoute roles={ADMIN_ROLES}>
              <AdminAnalyticsPage />
            </ProtectedRoute>
          }
        />
        <Route path={ROUTES.inspections} element={<InspectionsPage />} />
        <Route
          path={ROUTES.systemConfiguration}
          element={
            <ProtectedRoute roles={HEAD_ADMIN_ROLES}>
              <SystemConfigurationPage />
            </ProtectedRoute>
          }
        />
        <Route
          path={ROUTES.marketSection}
          element={
            <ProtectedRoute roles={HEAD_ADMIN_ROLES}>
              <MarketSectionPage />
            </ProtectedRoute>
          }
        />
        <Route
          path={ROUTES.ordinance}
          element={
            <ProtectedRoute roles={HEAD_ADMIN_ROLES}>
              <OrdinancesPage />
            </ProtectedRoute>
          }
        />
        <Route
          path={ROUTES.backups}
          element={
            <ProtectedRoute roles={HEAD_ADMIN_ROLES}>
              <BackupsPage />
            </ProtectedRoute>
          }
        />
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
        <Route
          path={ROUTES.vendorDetail(":id")}
          element={<VendorDetailPage />}
        />
        <Route
          path={ROUTES.vendorRegister}
          element={<VendorRegistrationPage />}
        />
      </Route>

      {/* Catch-all */}
      <Route path="*" element={<Navigate to={ROUTES.adminLogin} replace />} />
    </Routes>
  );
};

export default AppRoutes;
