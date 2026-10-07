import { ChevronRight, Plus, Search, ShieldCheck } from "lucide-react";
import { Link } from "react-router-dom";
import { ROUTES } from "@/routes/routePaths";
import MarketSectionRow from "../components/MarketSectionRow";
import { useMarketSections } from "../hooks/useMarketSections";

export default function MarketSectionPage() {
  const directory = useMarketSections();

  return (
    <div className="flex min-w-0 flex-col gap-3.5 pb-2!">
      <nav className="mb-4.5! flex items-center gap-1.75 text-xs leading-normal text-ui-body compact:mb-2!" aria-label="Breadcrumb">
        <Link to={ROUTES.systemConfiguration} className="control-focus text-ui-info! hover:underline">System Configuration</Link>
        <ChevronRight size={12} aria-hidden="true" />
        <span aria-current="page">Market Sections</span>
      </nav>

      <header className="mb-2.5! flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="text-page-title! leading-tight tracking-tight compact:text-2xl!">Market Sections</h1>
          <p className="mt-1.5! text-sm leading-normal text-ui-body compact:text-compact">Manage market areas used for vendor profiles, registration, and tickets.</p>
        </div>
        <button
          type="button"
          className="control-focus inline-flex min-h-9.5 items-center justify-center gap-2 rounded-button border-0 bg-ui-info px-4! py-2.25! text-xs font-medium leading-normal text-ui-on-primary disabled:cursor-not-allowed!"
          disabled
          title="Adding sections is currently unavailable"
          aria-describedby="market-section-actions-note"
        >
          <Plus size={16} aria-hidden="true" />
          Add Section
        </button>
      </header>

      <section className="min-w-0 overflow-hidden rounded-t-ui-sm border border-ui-border bg-ui-surface" aria-labelledby="section-directory-title">
        <div className="flex flex-wrap items-center justify-between gap-4 px-4.5! py-3.75!">
          <div>
            <h2 id="section-directory-title" className="text-base! font-medium! leading-tight">Section Directory</h2>
            <p className="mt-1! text-caption leading-normal text-ui-body">
              {directory.hasData
                ? `${directory.total} ${directory.total === 1 ? "section" : "sections"} configured`
                : directory.isLoading ? "Loading sections…" : "Sections unavailable"}
            </p>
          </div>
          <div className="relative flex w-90 min-w-55 max-w-full flex-initial items-center rounded-search border border-ui-border bg-ui-surface shadow-search transition duration-150 ease-search focus-within:border-search-focus focus-within:shadow-search-focus compact:w-full">
            <Search className="pointer-events-none absolute top-1/2 left-3 -translate-y-1/2 text-search-icon" size={14} strokeWidth={1.8} aria-hidden="true" />
            <input
              type="search"
              className="h-9.5 w-full min-w-0 rounded-search border-0 bg-transparent py-1.5! pr-3! pl-9! text-compact! leading-normal text-search-text outline-none"
              aria-label="Search market sections"
              placeholder="Search sections..."
              value={directory.search}
              onChange={(event) => directory.setSearch(event.target.value)}
            />
          </div>
        </div>

        {directory.isError && (
          <div className="flex flex-wrap items-center justify-between gap-3 border-t border-ui-border px-4.5! py-4! text-sm leading-normal text-ui-danger" role="alert">
            <p>{directory.errorMessage}</p>
            <button
              type="button"
              className="control-focus rounded-ui-sm border border-ui-border bg-ui-surface px-3! py-1.5! text-ui-heading disabled:cursor-wait!"
              onClick={directory.retry}
              disabled={directory.isFetching}
            >
              {directory.isFetching ? "Retrying…" : "Try again"}
            </button>
          </div>
        )}

        <div className="control-focus overflow-x-auto" role="region" aria-label="Market sections table" tabIndex={0} aria-busy={directory.isFetching}>
          <table className="w-full min-w-180 table-fixed border-collapse text-ui-body" aria-labelledby="section-directory-title">
            <thead className="bg-ui-table">
              <tr>
                <th scope="col" className="directory-column w-17/100 pl-4.5!">Section Name</th>
                <th scope="col" className="directory-column w-42/100">Description</th>
                <th scope="col" className="directory-column w-12/100">Vendors</th>
                <th scope="col" className="directory-column w-17/100">Status</th>
                <th scope="col" className="directory-column w-27.5"><span className="sr-only">Actions</span></th>
              </tr>
            </thead>
            <tbody>
              {directory.isLoading ? (
                <tr><td colSpan={5} className="directory-message"><span role="status">Loading market sections…</span></td></tr>
              ) : directory.hasData && directory.sections.length === 0 ? (
                <tr>
                  <td colSpan={5} className="directory-message">
                    {directory.total === 0 ? "No market sections configured yet." : "No sections match your search."}
                  </td>
                </tr>
              ) : directory.sections.map((section) => (
                <MarketSectionRow key={section.id} section={section} />
              ))}
            </tbody>
          </table>
        </div>
        {directory.hasData && (
          <p className="bg-ui-table-footer px-4.5! py-3.25! text-micro leading-normal text-ui-body" role="status">
            Showing {directory.sections.length} of {directory.total} {directory.total === 1 ? "section" : "sections"}
          </p>
        )}
      </section>

      <aside className="flex items-center gap-3 rounded-notice border border-ui-info-border bg-ui-info-subtle px-4.5! py-3.5! text-caption leading-detail text-ui-primary compact:items-start">
        <ShieldCheck className="shrink-0" size={18} aria-hidden="true" />
        <p>Sections assigned to vendor profiles cannot be deleted. Mark unused sections inactive to preserve historical records.</p>
      </aside>
      <p id="market-section-actions-note" className="text-caption leading-normal text-ui-body">
        Adding, editing, and changing section status are currently unavailable.
      </p>
    </div>
  );
}
