import { FC } from 'react';
import PageHeader from '@/components/ui/PageHeader';

interface AdminPlaceholderPageProps {
  title: string;
}

/**
 * Reusable placeholder for admin-facing modules that are not yet implemented
 * (Inspections, Analytics, Performance). Renders within the DashboardLayout shell.
 */
const AdminPlaceholderPage: FC<AdminPlaceholderPageProps> = ({ title }) => {
  return (
    <div>
      <PageHeader
        title={title}
        subtitle={`The ${title} module is under construction.`}
      />
      <div className="bg-white rounded-lg shadow-sm border border-gray-100 p-10 text-center">
        <p className="text-bodygray text-sm">
          This section will be available soon.
        </p>
      </div>
    </div>
  );
};

export default AdminPlaceholderPage;
