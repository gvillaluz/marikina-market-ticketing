import { useEffect, useRef, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useAuthStore } from "@/store/store";
import { useToast } from "@/components/ui/Toast/useToast";
import { ordinanceApi } from "@/api/endpoints/ordinance.api";
import type { SaveOrdinanceRequest } from "@/api/types/ordinance.types";
import {
  ordinanceCountKey,
  ordinanceDetailKey,
  ordinancesListKey,
} from "../ordinances.constants";
import {
  buildOrdinanceRequest,
  cloneDraft,
  emptyOrdinanceFields,
  hasDraftChanges,
  isCategory,
  isSeverity,
  normalizeOrdinance,
  normalizeOrdinanceDetails,
  ordinanceError,
  parsePenaltyAmount,
  validateOrdinance,
} from "../ordinances.utils";
import type {
  DraftPenaltyTier,
  OrdinanceDraft,
  OrdinanceFieldName,
  OrdinanceFields,
  OrdinanceSummary,
  TierFieldName,
} from "../ordinances.types";

function fieldsFrom(item: OrdinanceSummary): OrdinanceFields {
  return {
    ordinanceNumber: item.ordinanceNo,
    series: item.series,
    marketCode: item.marketCode,
    title: item.title,
    description: item.description,
    category: item.category,
  };
}

export function useOrdinanceEditor() {
  const client = useQueryClient();
  const { showToast } = useToast();
  const canManage = useAuthStore((state) => state.user?.role === "HeadAdmin");
  const [open, setOpen] = useState(false);
  const [selected, setSelected] = useState<OrdinanceSummary | null>(null);
  const [fields, setFields] = useState<OrdinanceFields>(emptyOrdinanceFields);
  const [tiers, setTiers] = useState<DraftPenaltyTier[]>([]);
  const [touched, setTouched] = useState<
    Partial<Record<OrdinanceFieldName, boolean>>
  >({});
  const [tierTouched, setTierTouched] = useState<
    Record<string, Partial<Record<TierFieldName, boolean>>>
  >({});
  const [error, setError] = useState("");
  const [session, setSession] = useState(0);
  const currentSession = useRef(0);
  const hydratedSession = useRef(-1);
  const saving = useRef(false);
  const baseline = useRef<OrdinanceDraft | null>(null);
  const detailKey = [...ordinanceDetailKey(selected?.id ?? 0), session];
  const details = useQuery({
    queryKey: detailKey,
    queryFn: async ({ signal }) => {
      const item = await ordinanceApi.getById(selected?.id ?? 0, signal);
      if (item.id !== selected?.id)
        throw new Error("Invalid ordinance detail response.");
      return normalizeOrdinanceDetails(item);
    },
    enabled: open && selected !== null && canManage,
    staleTime: Infinity,
    gcTime: 0,
    retry: false,
    refetchOnWindowFocus: false,
    refetchOnReconnect: false,
  });

  useEffect(() => {
    if (
      !open ||
      !selected ||
      session !== currentSession.current ||
      !details.isSuccess ||
      details.isFetching ||
      hydratedSession.current === session
    )
      return;
    const loaded: OrdinanceDraft = {
      fields: fieldsFrom(details.data),
      tiers: [...details.data.penaltyTiers]
        .sort((a, b) => a.offenseNumber - b.offenseNumber)
        .map((item) => ({
          key: crypto.randomUUID(),
          severity: item.severity,
          amount: String(item.penaltyAmount),
        })),
    };
    baseline.current = cloneDraft(loaded);
    setFields(loaded.fields);
    setTiers(loaded.tiers);
    hydratedSession.current = session;
  }, [
    open,
    selected,
    session,
    details.data,
    details.isSuccess,
    details.isFetching,
  ]);

  const ready =
    !selected ||
    (details.isSuccess &&
      !details.isFetching &&
      hydratedSession.current === session);
  const validation = validateOrdinance(fields, tiers);
  const hasChanges =
    selected !== null &&
    baseline.current !== null &&
    hasDraftChanges({ fields, tiers }, baseline.current);
  const highestFee = tiers.reduce(
    (maximum, tier) => Math.max(maximum, parsePenaltyAmount(tier.amount) ?? 0),
    0,
  );
  const save = useMutation({
    mutationFn: ({
      id,
      request,
    }: {
      id: number | null;
      request: SaveOrdinanceRequest;
    }) =>
      id === null
        ? ordinanceApi.create(request)
        : ordinanceApi.update(id, request),
    onSuccess: async (response, variables) => {
      const item = normalizeOrdinance(response);
      await client.cancelQueries({ queryKey: ordinancesListKey });
      client.setQueryData<OrdinanceSummary[]>(
        ordinancesListKey,
        (items = []) => {
          const exists = items.some((entry) => entry.id === item.id);
          return exists
            ? items.map((entry) => (entry.id === item.id ? item : entry))
            : [...items, item];
        },
      );
      setOpen(false);
      currentSession.current += 1;
      baseline.current = null;
      showToast({
        variant: "success",
        title:
          variables.id === null ? "Ordinance created" : "Ordinance updated",
      });
      await Promise.all([
        client.invalidateQueries({ queryKey: ordinancesListKey }),
        client.invalidateQueries({
          queryKey: ordinanceDetailKey(item.id),
          refetchType: "none",
        }),
        client.invalidateQueries({ queryKey: ordinanceCountKey }),
      ]);
    },
    onError: (cause) =>
      setError(
        ordinanceError(
          cause,
          "Unable to save the ordinance. Please try again.",
        ),
      ),
    onSettled: () => {
      saving.current = false;
    },
  });
  const disabled = !canManage || !ready || save.isPending;

  return {
    open,
    selected,
    fields,
    tiers,
    touched,
    tierTouched,
    ...validation,
    highestFee,
    hasChanges,
    error,
    canManage,
    disabled,
    isSaving: save.isPending,
    canSave:
      open &&
      canManage &&
      ready &&
      validation.isValid &&
      (!selected || hasChanges) &&
      !save.isPending,
    canUndo: open && canManage && ready && hasChanges && !save.isPending,
    isLoadingDetails: selected !== null && !details.isError && !ready,
    isDetailError: selected !== null && details.isError,
    detailError: ordinanceError(
      details.error,
      "Unable to load penalty tiers. Please try again.",
    ),
    isRetryingDetails: details.isFetching,
    retryDetails() {
      void details.refetch();
    },
    launch(item: OrdinanceSummary | null = null) {
      if (!canManage || saving.current) return;
      if (item && (!Number.isSafeInteger(item.id) || item.id <= 0)) return;
      void client.cancelQueries({ queryKey: detailKey, exact: true });
      const nextSession = ++currentSession.current;
      hydratedSession.current = -1;
      baseline.current = null;
      setSession(nextSession);
      setSelected(item);
      setOpen(true);
      setFields(item ? fieldsFrom(item) : emptyOrdinanceFields());
      setTiers([]);
      setTouched({});
      setTierTouched({});
      setError("");
      save.reset();
    },
    close() {
      if (saving.current) return;
      currentSession.current += 1;
      baseline.current = null;
      void client.cancelQueries({ queryKey: detailKey, exact: true });
      setOpen(false);
    },
    undo() {
      if (disabled || saving.current || !selected || !baseline.current) return;
      const restored = cloneDraft(baseline.current);
      setFields(restored.fields);
      setTiers(restored.tiers);
      setTouched({});
      setTierTouched({});
      setError("");
      save.reset();
    },
    changeField(name: OrdinanceFieldName, value: string) {
      if (disabled) return;
      setFields((current) =>
        name === "category"
          ? { ...current, category: isCategory(value) ? value : "" }
          : { ...current, [name]: value },
      );
      setError("");
    },
    touchField(name: OrdinanceFieldName) {
      setTouched((current) => ({ ...current, [name]: true }));
    },
    addTier() {
      if (disabled) return;
      setTiers((current) => [
        ...current,
        { key: crypto.randomUUID(), severity: "Minor", amount: "" },
      ]);
      setError("");
    },
    removeTier(key: string) {
      if (disabled) return;
      setTiers((current) => current.filter((item) => item.key !== key));
      setTierTouched((current) => {
        const next = { ...current };
        delete next[key];
        return next;
      });
      setError("");
    },
    changeTier(key: string, name: TierFieldName, value: string) {
      if (disabled) return;
      setTiers((current) =>
        current.map((item) =>
          item.key !== key
            ? item
            : name === "severity"
              ? { ...item, severity: isSeverity(value) ? value : "" }
              : { ...item, amount: value },
        ),
      );
      setError("");
    },
    touchTier(key: string, name: TierFieldName) {
      setTierTouched((current) => ({
        ...current,
        [key]: { ...current[key], [name]: true },
      }));
    },
    submit() {
      if (
        !open ||
        disabled ||
        saving.current ||
        (selected !== null && !hasChanges)
      )
        return;
      const request = buildOrdinanceRequest(fields, tiers);
      if (!request) {
        setError(
          "Complete the ordinance details and at least one valid penalty tier.",
        );
        return;
      }
      saving.current = true;
      setError("");
      save.mutate({ id: selected?.id ?? null, request });
    },
  };
}
