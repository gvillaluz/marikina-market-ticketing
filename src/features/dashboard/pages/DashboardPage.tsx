import { FC } from 'react';
import PageHeader from '@/components/ui/PageHeader';
import StatCard from '@/features/dashboard/components/StatCard';
import MonthlyTrendChart from '@/features/dashboard/components/MonthlyTrendChart';
import TicketTypeChart from '@/features/dashboard/components/TicketTypeChart';
import { useAuth } from '@/context/AuthContext';
import { mockAnalytics } from '@/api/mock/mockData';
import { formatCurrency } from '@/utils/formatters';
import styles from './DashboardPage.module.css';

const DashboardPage: FC = () => {
  const { user, isAdmin } = useAuth();

  return (
    <div>
      <PageHeader
        title={`Welcome back, ${user?.name?.split(' ')[0] ?? 'User'}`}
        subtitle={isAdmin ? 'City-wide ticketing overview and analytics.' : 'Your business compliance and ticket summary.'}
      />

      <div className={styles.statsGrid}>
        <StatCard label="Total Tickets" value={mockAnalytics.stats.totalTickets} icon="🎫" trend="+8.2%" trendUp tone="primary" />
        <StatCard label="Open Tickets" value={mockAnalytics.stats.openTickets} icon="📌" tone="warning" />
        <StatCard label="Active Vendors" value={mockAnalytics.stats.activeVendors} icon="🏪" trend="+4.1%" trendUp tone="success" />
        <StatCard label="Collected Fines" value={formatCurrency(mockAnalytics.stats.totalCollected)} icon="💰" tone="info" />
      </div>

      <div className={styles.chartsGrid}>
        <div className={styles.card}>
          <h3 className={styles.cardTitle}>Monthly Ticket Trend</h3>
          <MonthlyTrendChart data={mockAnalytics.monthlyTrend} />
        </div>
        <div className={styles.card}>
          <h3 className={styles.cardTitle}>Tickets by Type</h3>
          <TicketTypeChart data={mockAnalytics.ticketsByType} />
        </div>
      </div>

      <div className={styles.statsGrid}>
        <StatCard label="Pending Approvals" value={mockAnalytics.stats.pendingApprovals} icon="⏳" tone="warning" />
        <StatCard label="Avg. Resolution (days)" value={mockAnalytics.stats.avgResolutionDays} icon="📅" tone="info" />
        <StatCard label="Compliance Rate" value={`${mockAnalytics.stats.complianceRate}%`} icon="✅" trend="+2.3%" trendUp tone="success" />
        <StatCard label="Resolved Tickets" value={mockAnalytics.stats.resolvedTickets} icon="✔️" tone="success" />
      </div>
    </div>
  );
};

export default DashboardPage;
