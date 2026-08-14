import { FC } from 'react';
import PageHeader from '@/components/ui/PageHeader';
import { useAuth } from '@/context/AuthContext';

const DashboardPage: FC = () => {
  const { user, isAdmin } = useAuth();

  return (
    <div>
      <PageHeader
        title={`Welcome back, ${user?.name?.split(' ')[0] ?? 'User'}`}
        subtitle={isAdmin ? 'City-wide ticketing overview and analytics.' : 'Your business compliance and ticket summary.'}
      />
    </div>
  );
};

export default DashboardPage;