import { FC } from 'react';
import PageHeader from '@/components/ui/PageHeader';
import styles from './AdminPlaceholderPage.module.css';

interface AdminPlaceholderPageProps {
  title: string;
}


const AdminPlaceholderPage: FC<AdminPlaceholderPageProps> = ({ title }) => {
  return (
    <div className={styles.page}>
      <PageHeader
        title={title}
        subtitle={`The ${title} module is under construction.`}
      />
      <div className={styles.card}>
        <p>
          This section will be available soon.
        </p>
      </div>
    </div>
  );
};

export default AdminPlaceholderPage;
