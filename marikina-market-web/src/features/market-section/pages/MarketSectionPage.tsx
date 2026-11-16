import Breadcrumb from "@/components/ui/Breadcrumb";
import styles from "./MarketSectionPage.module.css";
import { Plus, Search, ShieldCheck } from "lucide-react";

import { ROUTES } from "@/routes/routePaths";
import PageHeader from "@/components/ui/PageHeader";
import RegistryTable from "@/components/ui/RegistryTable";
import MarketSectionRow from "../components/MarketSectionRow";
import { useMarketSections } from "../hooks/useMarketSections";
import { useMarketSectionEditor } from "../hooks/useMarketSectionEditor";
import MarketSectionModal from "../components/MarketSectionModal";

export default function MarketSectionPage() {
  const directory = useMarketSections();
  const editor = useMarketSectionEditor();

  return (
    <div className={styles.page}>
      <Breadcrumb
        items={[
          {
            label: "System Configuration",
            to: editor.canOpenConfiguration
              ? ROUTES.systemConfiguration
              : undefined,
          },
          { label: "Market Streets" },
        ]}
      />

      <PageHeader
        className={styles.header}
        title="Market Streets"
        subtitle="Manage market streets used for vendor profiles, registration, and tickets."
        actions={
          <button
            type="button"
            className={styles.addButton}
            disabled={
              !editor.canManage ||
              !directory.hasData ||
              editor.pendingId !== null ||
              editor.isSaving ||
              editor.open
            }
            onClick={() => editor.launch()}
          >
            <Plus size={16} aria-hidden="true" />
            Add Street
          </button>
        }
      />

      <section
        className={styles.directory}
        aria-labelledby="section-directory-title"
      >
        <div className={styles.directoryHeader}>
          <div>
            <h2 id="section-directory-title" className={styles.directoryTitle}>
              Street Directory
            </h2>
            <p className={styles.directoryDescription}>
              {directory.hasData
                ? `${directory.total} ${directory.total === 1 ? "street" : "streets"} configured`
                : directory.isLoading
                  ? "Loading streets…"
                  : "Streets unavailable"}
            </p>
          </div>
          <div className={styles.search}>
            <Search
              className={styles.searchIcon}
              size={14}
              strokeWidth={1.8}
              aria-hidden="true"
            />
            <input
              type="search"
              className={styles.searchInput}
              aria-label="Search market streets"
              placeholder="Search streets..."
              value={directory.search}
              onChange={(event) => directory.setSearch(event.target.value)}
            />
          </div>
        </div>

        {directory.isError && (
          <div className={styles.error} role="alert">
            <p>{directory.errorMessage}</p>
            <button
              type="button"
              className={styles.retryButton}
              onClick={directory.retry}
              disabled={directory.isFetching}
            >
              {directory.isFetching ? "Retrying…" : "Try again"}
            </button>
          </div>
        )}

        <RegistryTable
          className={styles.table}
          ariaLabel="Market streets table"
          labelledBy="section-directory-title"
          busy={directory.isFetching}
          columns={[
            { label: "Street Name", className: styles.nameColumn },
            { label: "Vendors", className: styles.vendorColumn },
            { label: "Status", className: styles.statusColumn },
            { label: "Actions", className: styles.actionsColumn },
          ]}
        >
          {directory.isLoading ? (
            <tr>
              <td colSpan={4} className={styles.message}>
                <span role="status">Loading market streets…</span>
              </td>
            </tr>
          ) : directory.hasData && directory.sections.length === 0 ? (
            <tr>
              <td colSpan={4} className={styles.message}>
                {directory.total === 0
                  ? "No market streets configured yet."
                  : "No streets match your search."}
              </td>
            </tr>
          ) : (
            directory.sections.map((section) => (
              <MarketSectionRow
                key={section.id}
                section={section}
                search={directory.search}
                disabled={
                  !editor.canManage ||
                  editor.pendingId !== null ||
                  editor.isSaving ||
                  editor.open
                }
                pending={editor.pendingId === section.id}
                onEdit={() => editor.launch(section)}
                onToggle={() => editor.toggle(section)}
              />
            ))
          )}
        </RegistryTable>
        {directory.hasData && (
          <p className={styles.footer} role="status">
            Showing {directory.sections.length} of {directory.total}{" "}
            {directory.total === 1 ? "street" : "streets"}
          </p>
        )}
      </section>

      <aside className={styles.notice}>
        <ShieldCheck
          className={styles.noticeIcon}
          size={18}
          aria-hidden="true"
        />
        <p>
          Streets assigned to vendor profiles cannot be deleted. Mark unused
          streets inactive to preserve historical records.
        </p>
      </aside>
      <MarketSectionModal editor={editor} />
    </div>
  );
}
