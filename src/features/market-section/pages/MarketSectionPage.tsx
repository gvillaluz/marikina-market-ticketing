import styles from './MarketSectionPage.module.css';
import { ChevronRight, Plus, Search, ShieldCheck } from "lucide-react";
import { Link } from "react-router-dom";
import { ROUTES } from "@/routes/routePaths";
import MarketSectionRow from "../components/MarketSectionRow";
import { useMarketSections } from "../hooks/useMarketSections";
import { useMarketSectionEditor } from "../hooks/useMarketSectionEditor";
import MarketSectionModal from "../components/MarketSectionModal";

export default function MarketSectionPage() {
  const directory = useMarketSections();
  const editor = useMarketSectionEditor();

  return (
    <div className={styles.page}>
      <nav className={styles.breadcrumb} aria-label="Breadcrumb">
        <Link to={ROUTES.systemConfiguration} className={styles.breadcrumbLink}>System Configuration</Link>
        <ChevronRight size={12} aria-hidden="true" />
        <span aria-current="page">Market Sections</span>
      </nav>

      <header className={styles.header}>
        <div>
          <h1 className={styles.title}>Market Sections</h1>
          <p className={styles.subtitle}>Manage market areas used for vendor profiles, registration, and tickets.</p>
        </div>
        <button
          type="button"
          className={styles.addButton}
          disabled={!editor.canManage || !directory.hasData || editor.pendingId !== null}
          onClick={() => editor.launch()}
        >
          <Plus size={16} aria-hidden="true" />
          Add Section
        </button>
      </header>

      <section className={styles.directory} aria-labelledby="section-directory-title">
        <div className={styles.directoryHeader}>
          <div>
            <h2 id="section-directory-title" className={styles.directoryTitle}>Section Directory</h2>
            <p className={styles.directoryDescription}>
              {directory.hasData
                ? `${directory.total} ${directory.total === 1 ? "section" : "sections"} configured`
                : directory.isLoading ? "Loading sections…" : "Sections unavailable"}
            </p>
          </div>
          <div className={styles.search}>
            <Search className={styles.searchIcon} size={14} strokeWidth={1.8} aria-hidden="true" />
            <input
              type="search"
              className={styles.searchInput}
              aria-label="Search market sections"
              placeholder="Search sections..."
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

        <div className={styles.tableRegion} role="region" aria-label="Market sections table" tabIndex={0} aria-busy={directory.isFetching}>
          <table className={styles.table} aria-labelledby="section-directory-title">
            <thead className={styles.tableHeader}>
              <tr>
                <th scope="col" className={styles.nameColumn}>Section Name</th>
                <th scope="col" className={styles.descriptionColumn}>Description</th>
                <th scope="col" className={styles.vendorColumn}>Vendors</th>
                <th scope="col" className={styles.statusColumn}>Status</th>
                <th scope="col" className={styles.actionsColumn}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {directory.isLoading ? (
                <tr><td colSpan={5} className={styles.message}><span role="status">Loading market sections…</span></td></tr>
              ) : directory.hasData && directory.sections.length === 0 ? (
                <tr>
                  <td colSpan={5} className={styles.message}>
                    {directory.total === 0 ? "No market sections configured yet." : "No sections match your search."}
                  </td>
                </tr>
              ) : directory.sections.map((section) => (
                <MarketSectionRow key={section.id} section={section}
                  disabled={!editor.canManage || editor.pendingId !== null}
                  pending={editor.pendingId === section.id}
                  onEdit={() => editor.launch(section)} onToggle={() => editor.toggle(section)} />
              ))}
            </tbody>
          </table>
        </div>
        {directory.hasData && (
          <p className={styles.footer} role="status">
            Showing {directory.sections.length} of {directory.total} {directory.total === 1 ? "section" : "sections"}
          </p>
        )}
      </section>

      <aside className={styles.notice}>
        <ShieldCheck className={styles.noticeIcon} size={18} aria-hidden="true" />
        <p>Sections assigned to vendor profiles cannot be deleted. Mark unused sections inactive to preserve historical records.</p>
      </aside>
      <MarketSectionModal editor={editor} />
    </div>
  );
}
