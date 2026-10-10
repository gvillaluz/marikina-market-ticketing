import {
  Activity,
  ClipboardCheck,
  FileClock,
  History,
  Settings,
  ShieldCheck,
  Store,
  Ticket,
  UsersRound,
} from "lucide-react";
import type { LucideIcon } from "lucide-react";
import {
  ADMIN_ROLES,
  HEAD_ADMIN_ROLES,
  type UserRole,
} from "@/api/types/common.types";
import type { DashboardMetrics } from "@/api/types/dashboard.types";
import Button from "@/components/ui/Button/Button";
import PageHeader from "@/components/ui/PageHeader/PageHeader";
import { useAuth } from "@/context/AuthContext";
import { ROUTES } from "@/routes/routePaths";
import DashboardActivityItem from "../components/DashboardActivityItem";
import DashboardAttentionItem from "../components/DashboardAttentionItem";
import DashboardEmptyPanel from "../components/DashboardEmptyPanel";
import DashboardMetricCard from "../components/DashboardMetricCard";
import DashboardQuickLink from "../components/DashboardQuickLink";
import DashboardRegistrationPipeline from "../components/DashboardRegistrationPipeline";
import { formatDashboardUpdatedAt } from "../dashboard.utils";
import { useDashboardRegistrationStatus } from "../hooks/useDashboardRegistrationStatus";
import { useDashboardSummary } from "../hooks/useDashboardSummary";
import styles from "./DashboardPage.module.css";

interface QuickLink {
  label: string;
  description: string;
  to: string;
  icon: LucideIcon;
  roles: readonly UserRole[];
}

const QUICK_LINKS: QuickLink[] = [
  {
    label: "Inspections",
    description: "Review field activity",
    to: ROUTES.inspections,
    icon: ClipboardCheck,
    roles: ADMIN_ROLES,
  },
  {
    label: "Tickets",
    description: "Manage reported issues",
    to: ROUTES.tickets,
    icon: Ticket,
    roles: ADMIN_ROLES,
  },
  {
    label: "Vendor registrations",
    description: "Review applications",
    to: ROUTES.adminVendorRegistrations,
    icon: Store,
    roles: ADMIN_ROLES,
  },
  {
    label: "Vendor directory",
    description: "View registered vendors",
    to: ROUTES.adminVendors,
    icon: Store,
    roles: ADMIN_ROLES,
  },
  {
    label: "Enforcers",
    description: "View field staff",
    to: ROUTES.enforcers,
    icon: UsersRound,
    roles: ADMIN_ROLES,
  },
  {
    label: "Audit logs",
    description: "Review system activity",
    to: ROUTES.auditLogs,
    icon: History,
    roles: ADMIN_ROLES,
  },
  {
    label: "Staff accounts",
    description: "Manage system access",
    to: ROUTES.accounts,
    icon: UsersRound,
    roles: HEAD_ADMIN_ROLES,
  },
  {
    label: "Configurations",
    description: "Manage system settings",
    to: ROUTES.systemConfiguration,
    icon: Settings,
    roles: HEAD_ADMIN_ROLES,
  },
];

const METRICS = [
  {
    key: "inspectionsToday",
    label: "Inspections today",
    description: "Field activity recorded today",
    icon: ClipboardCheck,
    tone: "primary",
  },
  {
    key: "openTickets",
    label: "Open tickets",
    description: "Cases awaiting resolution",
    icon: Ticket,
    tone: "warning",
  },
  {
    key: "activeVendors",
    label: "Active vendors",
    description: "Vendors currently registered",
    icon: Store,
    tone: "success",
  },
  {
    key: "pendingRegistrations",
    label: "Pending applications",
    description: "Registrations awaiting review",
    icon: FileClock,
    tone: "info",
  },
] as const;

export function DashboardPage() {
  const { user } = useAuth();
  const { summary, isLoading, error, retry } = useDashboardSummary();
  const registrationStatus = useDashboardRegistrationStatus();
  const firstName = user?.firstName?.trim();
  const quickLinks = QUICK_LINKS.filter((link) =>
    user?.role ? link.roles.includes(user.role) : false,
  );

  return (
    <div className={styles.page}>
      <PageHeader
        title={firstName ? `Welcome back, ${firstName}` : "Dashboard"}
        subtitle="A clear view of activity and shortcuts across your market system."
      />

      <section
        className={styles.connectionNotice}
        aria-label="Dashboard data status"
        aria-busy={isLoading}
      >
        <span className={styles.noticeIcon} aria-hidden="true">
          <Activity size={18} />
        </span>
        <div>
          <h2>System overview</h2>
          <p>
            {error ??
              (isLoading
                ? "Loading the latest system activity and queues."
                : summary
                  ? `Updated ${formatDashboardUpdatedAt(summary.asOf)} (Manila time).`
                  : "Dashboard data is unavailable.")}
          </p>
        </div>
        {error ? (
          <Button type="button" variant="outline" size="sm" onClick={retry}>
            Try again
          </Button>
        ) : (
          <span
            className={`${styles.status} ${summary ? styles.statusReady : ""}`}
          >
            {isLoading ? "Loading" : summary ? "Data loaded" : "Unavailable"}
          </span>
        )}
      </section>

      <section className={styles.metrics} aria-label="System summary">
        {METRICS.map(({ key, ...metric }) => (
          <DashboardMetricCard
            key={key}
            {...metric}
            value={summary?.metrics[key as keyof DashboardMetrics] ?? null}
            isLoading={isLoading}
          />
        ))}
      </section>

      <section className={styles.dashboardColumns} aria-label="Activity summary">
        <div className={styles.recentPanel}>
          <DashboardEmptyPanel
            title="Recent activity"
            description="Recent system events will appear here."
            icon={History}
            iconLabel="No recent activity"
            tone="primary"
            isLoading={isLoading}
            error={error}
            onRetry={retry}
          >
            {summary?.recentActivity.map((activity) => (
              <DashboardActivityItem key={activity.id} activity={activity} />
            ))}
          </DashboardEmptyPanel>
        </div>

        <div className={styles.rightColumn}>
          <div className={styles.attentionPanel}>
            <DashboardEmptyPanel
              title="Needs attention"
              description="There are no open queues that need review."
              icon={ShieldCheck}
              iconLabel="You're all caught up"
              tone={summary?.attentionItems.length ? "warning" : "success"}
              isLoading={isLoading}
              error={error}
              onRetry={retry}
            >
              {summary?.attentionItems.map((item) => (
                <DashboardAttentionItem key={item.id} item={item} />
              ))}
            </DashboardEmptyPanel>
          </div>
          <DashboardRegistrationPipeline
            counts={registrationStatus.counts}
            isLoading={registrationStatus.isLoading}
            error={registrationStatus.error}
            onRetry={registrationStatus.retry}
          />
        </div>
      </section>

      <section
        className={styles.quickAccess}
        aria-labelledby="quick-access-title"
      >
        <div className={styles.sectionHeading}>
          <div>
            <h2 id="quick-access-title">Quick access</h2>
            <p>Jump into everyday work and system settings.</p>
          </div>
          <span aria-hidden="true">{quickLinks.length} sections</span>
        </div>
        <div className={styles.quickLinks}>
          {quickLinks.map((link) => (
            <DashboardQuickLink key={link.to} {...link} />
          ))}
        </div>
      </section>
    </div>
  );
}
