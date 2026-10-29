import { useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { personsApi } from "@/api/endpoints/persons.api";
import { getApiErrorMessage } from "@/utils/apiErrors";

export function usePersonsPage() {
  const [search, setSearchValue] = useState("");
  const [page, setPage] = useState(1);
  const [open, setOpen] = useState(false);
  const [personId, setPersonId] = useState<number | null>(null);
  const client = useQueryClient();
  const query = useQuery({
    queryKey: ["persons", search, page],
    queryFn: () => personsApi.list(search, (page - 1) * 10),
  });
  const showForm = (id: number | null) => { setPersonId(id); setOpen(true); };
  return {
    search, page, setPage, open, personId, showForm, close: () => setOpen(false),
    setSearch: (value: string) => { setSearchValue(value); setPage(1); },
    persons: query.data?.items ?? [], total: query.data?.total ?? 0,
    hasMore: query.data?.hasMore ?? false,
    loading: query.isPending, fetching: query.isFetching,
    error: query.isError ? getApiErrorMessage(query.error, "Unable to load people.") : "",
    retry: () => { void query.refetch(); },
    onSaved: async () => { await client.invalidateQueries({ queryKey: ["persons"] }); },
  };
}
