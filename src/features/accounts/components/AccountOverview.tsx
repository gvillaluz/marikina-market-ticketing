import { ShieldCheck } from "lucide-react";
import SkeletonBlock from "@/components/ui/Skeleton/SkeletonBlock";
import type { AccountsModel } from "../hooks/useAccounts";
import styles from "./AccountOverview.module.css";
import AccountMessage from "./AccountMessage";

export default function AccountOverview({ model }: { model: AccountsModel }) {
  const metrics = [
    { label: "Total Users", value: model.counts?.totalStaffUsers },
    { label: "Active", value: model.counts?.totalActiveAccounts },
    { label: "Administrators", value: model.counts?.totalAdministrators },
    { label: "Vendors", value: model.counts?.totalMarketVendorUsers },
  ];
  return (
    <section
      className={styles.overview}
      aria-label="Access overview"
      aria-busy={model.countsLoading}
    >
      <div className={styles.description}>
        <span className={styles.icon}>
          <ShieldCheck size={22} aria-hidden="true" />
        </span>
        <div>
          <h2>Access Overview</h2>
          <p>Current identity and role coverage across the system</p>
        </div>
      </div>
      {model.countsError ? (
        <AccountMessage
          message={model.countsError}
          onRetry={model.retryCounts}
        />
      ) : (
        <dl className={styles.metrics}>
          {metrics.map((metric) => (
            <div key={metric.label}>
              <dd>
                {model.countsLoading ? (
                  <SkeletonBlock width="3rem" height="1.5rem" />
                ) : (
                  metric.value
                )}
              </dd>
              <dt>{metric.label}</dt>
            </div>
          ))}
        </dl>
      )}
    </section>
  );
}
