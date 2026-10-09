import { Search } from "lucide-react";
import Pagination from "@/components/ui/Pagination";
import type { AccountsModel } from "../hooks/useAccounts";
import { ACCOUNT_TABS } from "../accounts.constants";
import AccountRow from "./AccountRow";
import AccountRowsSkeleton from "./AccountRowsSkeleton";
import AccountMessage from "./AccountMessage";
import styles from "./AccountDirectory.module.css";

export default function AccountDirectory({ model }: { model: AccountsModel }) {
  return (
    <section
      className={styles.directory}
      aria-labelledby="account-directory-title"
    >
      <header className={styles.header}>
        <h2 id="account-directory-title">Account Directory</h2>
        <p>Staff access and vendor identities in one controlled register</p>
      </header>
      <div className={styles.controls}>
        <div className={styles.tabs} role="group" aria-label="Filter by role">
          {ACCOUNT_TABS.map((tab) => (
            <button
              type="button"
              key={tab.role}
              className={model.role === tab.role ? styles.selected : ""}
              aria-pressed={model.role === tab.role}
              onClick={() => model.changeRole(tab.role)}
            >
              {tab.label}
            </button>
          ))}
        </div>
        <label className={styles.search}>
          <Search size={16} aria-hidden="true" />
          <input
            type="search"
            aria-label="Search account directory"
            placeholder="Search account directory…"
            maxLength={200}
            value={model.search}
            onChange={(event) => model.changeSearch(event.target.value)}
          />
        </label>
      </div>
      <div
        className={styles.tableScroll}
        tabIndex={0}
        role="region"
        aria-label="Account summaries"
        aria-busy={model.isLoading}
      >
        <table className={styles.table}>
          <thead>
            <tr>
              {["Account", "Role", "Contact", "Status", "Action"].map(
                (label) => (
                  <th key={label} scope="col">
                    {label}
                  </th>
                ),
              )}
            </tr>
          </thead>
          <tbody>
            {model.isLoading ? (
              <AccountRowsSkeleton />
            ) : model.error ? (
              <tr>
                <td colSpan={5}>
                  <AccountMessage message={model.error} onRetry={model.retry} />
                </td>
              </tr>
            ) : model.items.length === 0 ? (
              <tr>
                <td colSpan={5}>
                  <AccountMessage
                    message={
                      model.search || model.role !== "all"
                        ? "No accounts match your search or role filter."
                        : "No accounts have been registered yet."
                    }
                  />
                </td>
              </tr>
            ) : (
              model.items.map((account) => (
                <AccountRow key={account.id} account={account} />
              ))
            )}
          </tbody>
        </table>
      </div>
      <footer className={styles.footer}>
        <p role="status">
          {model.error && !model.isLoading
            ? "Account directory unavailable"
            : model.rangeLabel}
        </p>
        <fieldset disabled={model.isFetching} aria-label="Account pages">
          <Pagination
            compact
            showSinglePage
            className={styles.pagination}
            page={model.page}
            totalPages={model.totalPages}
            canGoNext={!model.canNext}
            onChange={model.changePage}
          />
        </fieldset>
      </footer>
    </section>
  );
}
