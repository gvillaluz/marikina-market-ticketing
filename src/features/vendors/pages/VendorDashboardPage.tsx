import { FC } from 'react';
import PageHeader from '@/components/ui/PageHeader';
import StatCard from '@/features/dashboard/components/StatCard';
import VendorProfile from '@/features/vendors/components/VendorProfile';
import VendorQRCode from '@/features/vendors/components/VendorQRCode';
import useVendorProfile from '@/features/vendors/hooks/useVendorProfile';
import Loader from '@/components/feedback/Loader';
import styles from './VendorDashboardPage.module.css';

/** Vendor-facing dashboard with profile and QR code. */
const VendorDashboardPage: FC = () => {
  const { vendor, loading } = useVendorProfile();

  if (loading) return <Loader fullPage label="Loading your profile…" />;

  return (
    <div>
      <PageHeader
        title="Vendor Dashboard"
        subtitle="Your registered business and QR verification code."
      />

      {vendor && (
        <div className={styles.layout}>
          <VendorProfile vendor={vendor} />
          <VendorQRCode vendor={vendor} />
        </div>
      )}

      {vendor && (
        <div className={styles.statsGrid}>
          <StatCard label="Compliance Score" value={`${vendor.complianceScore}%`} icon="✅" tone={vendor.complianceScore >= 75 ? 'success' : 'warning'} />
          <StatCard label="Registration Date" value={vendor.registrationDate.slice(0, 10)} icon="📅" tone="info" />
          <StatCard label="Permit Status" value={vendor.status} icon="📋" tone={vendor.status === 'active' ? 'success' : 'warning'} />
        </div>
      )}
    </div>
  );
};

export default VendorDashboardPage;
