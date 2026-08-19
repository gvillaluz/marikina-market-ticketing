import { FC, useEffect, useState } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import Loader from '@/components/feedback/Loader/Loader';
import Button from '@/components/ui/Button';
import { vendorApi } from '@/api/endpoints/vendor.api';
import VendorProfile from '@/features/vendors/components/VendorProfile';
import VendorQRCode from '@/features/vendors/components/VendorQRCode';
import { useAuth } from '@/context/AuthContext';
import type { Vendor } from '@/api/types/vendor.types';
import styles from './VendorDetailPage.module.css';

const VendorDetailPage: FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { isAdmin } = useAuth();
  const [vendor, setVendor] = useState<Vendor | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!id) return;
    (async () => {
      try {
        const data = await vendorApi.getById(id);
        setVendor(data);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to load vendor.');
      } finally {
        setLoading(false);
      }
    })();
  }, [id]);

  if (loading) return <Loader fullPage label="Loading vendor…" />;

  if (error || !vendor) {
    return (
      <div className={styles.errorState}>
        <span style={{ fontSize: '2.5rem' }}>🏪</span>
        <h2>Vendor not found</h2>
        <p>{error}</p>
        <Button onClick={() => navigate('/vendors')}>Back to Vendors</Button>
      </div>
    );
  }

  return (
    <div>
      <Link to="/vendors" className={styles.back}>← Back to Vendors</Link>

      <div className={styles.layout}>
        <VendorProfile vendor={vendor} />
        <VendorQRCode vendor={vendor} />
      </div>

      {isAdmin && (
        <div className={styles.actions}>
          <Button variant="outline">Suspend</Button>
          <Button variant="secondary">Edit Profile</Button>
        </div>
      )}
    </div>
  );
};

export default VendorDetailPage;
