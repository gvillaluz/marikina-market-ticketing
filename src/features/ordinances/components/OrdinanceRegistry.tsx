import { Search } from "lucide-react";
import type { useOrdinances } from "../hooks/useOrdinances";
import type { OrdinanceSummary } from "../ordinances.types";
import OrdinanceRegistryRow from "./OrdinanceRegistryRow";
import OrdinanceRegistryMessage from "./OrdinanceRegistryMessage";
import controls from "./OrdinanceControls.module.css";
import styles from "./OrdinanceRegistry.module.css";

interface Props {
  directory: ReturnType<typeof useOrdinances>;
  disabled: boolean;
  onManage: (item: OrdinanceSummary) => void;
}

export default function OrdinanceRegistry({
  directory,
  disabled,
  onManage,
}: Props) {
  const message = directory.isLoading
    ? "Loading ordinances…"
    : !directory.hasData
      ? "Ordinances are unavailable."
      : directory.ordinances.length === 0
        ? directory.total === 0
          ? "No ordinances configured yet."
          : "No ordinances match your search."
        : null;
  return (
    <section
      className={styles.registry}
      aria-labelledby="ordinance-registry-heading"
    >
      <header className={styles.header}>
        <div>
          <h2 id="ordinance-registry-heading">Ordinance Registry</h2>
          <p>Rules available when issuing tickets and warnings</p>
        </div>
        <div className={styles.search}>
          <Search size={14} aria-hidden="true" />
          <input
            type="search"
            value={directory.search}
            onChange={(event) => directory.setSearch(event.target.value)}
            placeholder="Search code or title…"
            aria-label="Search ordinances by code or title"
          />
        </div>
      </header>
      {directory.isError && (
        <div className={styles.error} role="alert">
          <p>{directory.errorMessage}</p>
          <button
            type="button"
            className={`${controls.button} ${controls.outline}`}
            onClick={directory.retry}
            disabled={directory.isFetching}
          >
            {directory.isFetching ? "Retrying…" : "Try again"}
          </button>
        </div>
      )}
      <div
        className={styles.region}
        role="region"
        aria-label="Ordinance registry table"
        tabIndex={0}
        aria-busy={directory.isFetching}
      >
        <table className={styles.table}>
          <thead>
            <tr>
              <th scope="col">Ordinance</th>
              <th scope="col">Category</th>
              <th scope="col">Penalty Tiers</th>
              <th scope="col">Last Updated</th>
              <th scope="col">Status</th>
              <th scope="col">Actions</th>
            </tr>
          </thead>
          <tbody>
            {message ? (
              <OrdinanceRegistryMessage
                message={message}
                loading={directory.isLoading}
              />
            ) : (
              directory.ordinances.map((item) => (
                <OrdinanceRegistryRow
                  key={item.id}
                  ordinance={item}
                  disabled={disabled}
                  onManage={() => onManage(item)}
                />
              ))
            )}
          </tbody>
        </table>
      </div>
      {directory.hasData && (
        <p className={styles.footer} role="status">
          Showing {directory.ordinances.length} of {directory.total}{" "}
          {directory.total === 1 ? "ordinance" : "ordinances"}
        </p>
      )}
    </section>
  );
}
