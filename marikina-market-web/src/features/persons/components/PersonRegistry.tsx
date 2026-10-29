import Button from "@/components/ui/Button";
import Table, { type Column } from "@/components/ui/Table";
import Pagination from "@/components/ui/Pagination";
import type { PersonRecord } from "@/api/types/person.types";
import type { usePersonsPage } from "../hooks/usePersonsPage";
import controls from "@/styles/FormControls.module.css";
import styles from "./PersonRegistry.module.css";

export default function PersonRegistry(state: ReturnType<typeof usePersonsPage>) {
  const columns: Column<PersonRecord>[] = [
    { key: "fullName", header: "Full name", width: "25%" },
    { key: "address", header: "Address", width: "40%" },
    { key: "phoneNumber", header: "Phone", render: person => person.phoneNumber || "—" },
    { key: "action", header: "Details", render: person => <Button type="button" variant="secondary" onClick={() => state.showForm(person.id)}>View / edit</Button> },
  ];
  return (
    <section className={styles.registry} aria-label="Person registry">
      <div className={styles.toolbar}>
        <label className={styles.search}>Search people
          <input className={controls.input} type="search" maxLength={500} value={state.search} onChange={event => state.setSearch(event.target.value)} placeholder="Name, address or phone" />
        </label>
        <Button type="button" onClick={() => state.showForm(null)}>Create person</Button>
      </div>
      {state.error ? <div className={styles.message} role="alert"><p>{state.error}</p><Button type="button" variant="secondary" onClick={state.retry}>Try again</Button></div> : <>
        <Table columns={columns} data={state.persons} keyExtractor={person => String(person.id)} loading={state.loading} loadingMessage="Loading people…" emptyMessage={state.search ? "No people match this search." : "No people recorded yet. Create a person to begin."} tableClassName={styles.table} responsive />
        <div className={styles.footer}>
          <span role="status">{state.fetching ? "Updating people…" : `${state.total} ${state.total === 1 ? "person" : "people"}`}</span>
          <Pagination page={state.page} totalPages={Math.max(1, Math.ceil(state.total / 10))} canGoNext={state.hasMore} onChange={state.setPage} disabled={state.fetching} />
        </div>
      </>}
    </section>
  );
}
