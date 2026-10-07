import { FC } from "react";
import { Link, useNavigate } from "react-router-dom";
import { LayoutGrid, FileText, Database, ChevronRight } from "lucide-react";
import PageHeader from "@/components/ui/PageHeader";
import ConfigModuleCard from "../components/ConfigModuleCard";
import RecentChangeItem from "../components/RecentChangeItem";
import styles from "./SystemConfigurationPage.module.css";
import { useMarketSectionCount } from "../hooks/useMarketSectionCount";
import { useOrdinanceCount } from "../hooks/useOrdinanceCount";
import StatCard from "@/components/ui/Card/StatCard/StatCard";
import { ROUTES } from "@/routes/routePaths";
import { useAuthStore } from "@/store/store";

// STATIC DATA — replace with useSystemStats() once the endpoint exists.
const STATS = {
  marketSections: 5,
  marketSectionsNote: "4 currently active",
  activeOrdinances: 24,
  activeOrdinancesNote: "1 draft for review",
  lastBackup: "Today",
  lastBackupNote: "Completed at 2:00 AM",
};

// STATIC DATA — configuration module entries
const CONFIG_MODULES = [
  {
    id: "market-sections",
    icon: LayoutGrid,
    iconColor: "#0B57D0",
    iconBg: "#E6F1FB",
    title: "Market Sections",
    description: "Organize vendor areas and stall classifications.",
    href: ROUTES.marketSection,
  },
  {
    id: "ordinances-penalties",
    icon: FileText,
    iconColor: "#B88A1D",
    iconBg: "#FAEEDA",
    title: "Ordinances & Penalties",
    description: "Maintain ordinance details and penalty tiers.",
    href: ROUTES.ordinance,
  },
  {
    id: "data-backups",
    icon: Database,
    iconColor: "#534AB7",
    iconBg: "#EEEDFE",
    title: "Data & Backups",
    description: "Schedule backups and manage data retention.",
    href: ROUTES.backups,
  },
];

// STATIC DATA — recent configuration activity feed
const RECENT_CHANGES = [
  {
    id: "1",
    icon: FileText,
    title: "Penalty tier updated",
    detail: "ORD-2024-018 was updated by Juan Dela Cruz.",
    timestamp: "Today, 9:42 AM",
  },
  {
    id: "2",
    icon: Database,
    title: "Automatic backup completed",
    detail: "All system records were backed up successfully.",
    timestamp: "Today, 2:00 AM",
  },
  {
    id: "3",
    icon: LayoutGrid,
    title: "Market section status changed",
    detail: "Food Court was marked inactive by Maria Santos.",
    timestamp: "Oct 27, 3:16 PM",
  },
];

const SystemConfigurationPage: FC = () => {
  const marketSectionSummary = useMarketSectionCount();
  const ordinanceSummary = useOrdinanceCount();
  const navigate = useNavigate();
  const canManageOrdinances = useAuthStore(
    (state) => state.user?.role === "Admin",
  );

  return (
    <div className={styles.page}>
      <PageHeader
        title="System Configuration"
        subtitle="Manage core market rules, records, and administrative preferences."
      />

      <div className={styles.statsRow}>
        <StatCard
          icon={LayoutGrid}
          iconColor="#0B57D0"
          iconBg="#E6F1FB"
          value={marketSectionSummary.count || 0}
          label="Market sections"
          note={STATS.marketSectionsNote}
        />
        <StatCard
          icon={FileText}
          iconColor="#1E8E3E"
          iconBg="#E6F4EA"
          value={ordinanceSummary.count || 0}
          label="Active ordinances"
          note={STATS.activeOrdinancesNote}
        />
        <StatCard
          icon={Database}
          iconColor="#534AB7"
          iconBg="#EEEDFE"
          value={STATS.lastBackup}
          label="Last data backup"
          note={STATS.lastBackupNote}
        />
      </div>

      <section className={styles.modulesSection}>
        <h3 className={styles.sectionTitle}>Configuration Modules</h3>
        <p className={styles.sectionSubtitle}>
          Select a module to review or update its settings.
        </p>

        <div className={styles.moduleGrid}>
          {CONFIG_MODULES.filter(
            (module) =>
              module.id !== "ordinances-penalties" || canManageOrdinances,
          ).map((module) => (
            <ConfigModuleCard key={module.id} {...module} />
          ))}
        </div>
      </section>

      <section className={styles.recentSection}>
        <div className={styles.recentHeader}>
          <div>
            <h3 className={styles.sectionTitle}>Recent Changes</h3>
            <p className={styles.sectionSubtitle}>
              Latest administrative configuration activity.
            </p>
          </div>
          <Link to="/configuration/audit-log" className={styles.auditLogLink}>
            View audit log
            <ChevronRight size={14} strokeWidth={2.5} />
          </Link>
        </div>

        <div className={styles.recentList}>
          {RECENT_CHANGES.map((change) => (
            <RecentChangeItem key={change.id} {...change} />
          ))}
        </div>
      </section>
    </div>
  );
};

export default SystemConfigurationPage;
