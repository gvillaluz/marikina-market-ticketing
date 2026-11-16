import Button from "@/components/ui/Button";
import SearchHighlight from "@/components/ui/SearchHighlight";
import Table, { type Column } from "@/components/ui/Table";
import {
  RecordActions,
  RecordsFooter,
  RecordsPanel,
  RecordsState,
  RecordsToolbar,
} from "@/components/ui/Records";
import type { PersonRecord } from "@/api/types/person.types";
import { formatDate } from "@/utils/formatters";
import type { usePersonsPage } from "../hooks/usePersonsPage";
import styles from "./PersonRegistry.module.css";

const PAGE_SIZE = 10;

export default function PersonRegistry(
  state: ReturnType<typeof usePersonsPage>,
) {
  const columns: Column<PersonRecord>[] = [
    {
      key: "fullName",
      header: "Full name",
      width: "22%",
      render: (person) => (
        <SearchHighlight text={person.fullName} search={state.search} />
      ),
    },
    {
      key: "address",
      header: "Address",
      width: "34%",
      render: (person) => (
        <SearchHighlight text={person.address} search={state.search} />
      ),
    },
    {
      key: "phoneNumber",
      header: "Phone",
      width: "15%",
      render: (person) =>
        person.phoneNumber ? (
          <SearchHighlight text={person.phoneNumber} search={state.search} />
        ) : (
          "—"
        ),
    },
    {
      key: "createdAt",
      header: "Date added",
      width: "14%",
      render: (person) => formatDate(person.createdAt),
    },
    {
      key: "action",
      header: "Details",
      align: "center",
      render: (person) => (
        <RecordActions
          label={`person ${person.fullName}`}
          onView={() => state.showForm(person.id)}
        />
      ),
    },
  ];
  return (
    <RecordsPanel
      title="Person registry"
      description="Search, view and edit recorded people"
      count={state.loading || state.error ? undefined : state.total}
      countLabel={state.total === 1 ? "person" : "people"}
      updating={state.fetching && !state.loading}
    >
      <RecordsToolbar
        search={state.search}
        onSearch={state.setSearch}
        searchLabel="Search people"
        placeholder="Name, address or phone"
      >
        <Button type="button" onClick={() => state.showForm(null)}>
          Create person
        </Button>
      </RecordsToolbar>
      {state.error ? (
        <RecordsState
          title="Unable to load people"
          message={state.error}
          onRetry={state.retry}
        />
      ) : (
        <>
          <Table
            responsive
            className={styles.list}
            tableClassName={styles.table}
            columns={columns}
            data={state.persons}
            keyExtractor={(person) => String(person.id)}
            loading={state.loading}
            loadingMessage="Loading people…"
            emptyMessage={
              state.search
                ? "No people match this search."
                : "No people recorded yet. Create a person to begin."
            }
          />
          {!state.loading && (
            <RecordsFooter
              page={state.page}
              pageSize={PAGE_SIZE}
              total={state.total}
              totalPages={Math.max(1, Math.ceil(state.total / PAGE_SIZE))}
              rowCount={state.persons.length}
              label="people"
              busy={state.fetching}
              onPageChange={state.setPage}
            />
          )}
        </>
      )}
    </RecordsPanel>
  );
}
