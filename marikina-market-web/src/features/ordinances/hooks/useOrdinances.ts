import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { ordinanceApi } from '@/api/endpoints/ordinance.api';
import { exactMatchesFirst } from '@/utils/searchMatch';
import { ordinancesListKey } from '../ordinances.constants';
import { normalizeOrdinance, ordinanceError } from '../ordinances.utils';
import type { OrdinanceSummary } from '../ordinances.types';

const searchedValues = (item: OrdinanceSummary) => [item.ordinanceNo, item.title, item.section ?? ''];

export function useOrdinances() {
  const [search, setSearch] = useState('');
  const query = useQuery({ queryKey: ordinancesListKey, queryFn: async ({ signal }) => (await ordinanceApi.getAll(signal)).map(normalizeOrdinance) });
  const all = query.data ?? [];
  const term = search.trim().toLocaleLowerCase();
  const matches = all.filter(item => searchedValues(item).some(value => value.toLocaleLowerCase().includes(term)));
  return {
    search, setSearch,
    ordinances: exactMatchesFirst(matches, search, searchedValues),
    total: all.length, hasData: query.data !== undefined,
    isLoading: query.isPending, isFetching: query.isFetching, isError: query.isError,
    errorMessage: ordinanceError(query.error, 'Unable to load ordinances. Please try again.'),
    retry: () => { void query.refetch(); },
  };
}
