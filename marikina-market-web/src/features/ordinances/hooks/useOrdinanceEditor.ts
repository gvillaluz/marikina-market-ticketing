import { useEffect, useRef, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useAuthStore } from "@/store/store";
import { ADMIN_ROLES } from "@/api/types/common.types";
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
  isFineKind,
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
    section: item.section ?? "",
    specificCategory: item.specificCategory ?? "",
    title: item.title,
    category: isCategory(item.category) ? item.category : "",
    severity: item.severity ?? "",
    warningEligible: item.warningEligible,
  };
}

export function useOrdinanceEditor() {
  const client = useQueryClient();
  const { showToast } = useToast();
  const role = useAuthStore((state) => state.user?.role);
  const canManage =
    role !== undefined && role !== null && ADMIN_ROLES.includes(role);
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
          fineKind: item.fineKind,
          amount: item.penaltyAmount == null ? "" : String(item.penaltyAmount),
          maximumFine: item.maximumFine == null ? "" : String(item.maximumFine),
          penaltyTerms: item.penaltyTerms ?? "",
          allowBloodDonation: item.allowBloodDonation,
          allowCommunityService: item.allowCommunityService,
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
  const configuredAmounts = tiers.flatMap((tier) => {
    const value = tier.fineKind === "Fixed" ? tier.amount
      : tier.fineKind === "UpTo" ? tier.maximumFine : "";
    const amount = parsePenaltyAmount(value);
    return amount === null ? [] : [amount];
  });
  const highestFee = configuredAmounts.length ? Math.max(...configuredAmounts) : null;
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
    canOpenConfiguration: role === "HeadAdmin",
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
    changeField(name: OrdinanceFieldName, value: string | boolean) {
      if (disabled) return;
      setFields((current) => {
        if (name === "warningEligible") return { ...current, warningEligible: value === true };
        if (typeof value !== "string") return current;
        if (name === "severity") return { ...current, severity: isSeverity(value) ? value : "" };
        return name === "category" ? {
          ...current,
          category: isCategory(value) ? value : "",
          specificCategory: value === "Others" ? current.specificCategory : "",
        }
          : { ...current, [name]: value };
      });
      setError("");
    },
    touchField(name: OrdinanceFieldName) {
      setTouched((current) => ({ ...current, [name]: true }));
    },
    addTier() {
      if (disabled) return;
      setTiers((current) => [
        ...current,
        {
          key: crypto.randomUUID(), fineKind: "Fixed", amount: "", maximumFine: "", penaltyTerms: "",
          allowBloodDonation: false, allowCommunityService: false
        },
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
    changeTier(key: string, name: TierFieldName, value: string | boolean) {
      if (disabled) return;
      setTiers((current) =>
        current.map((item, index) => {
          if (item.key !== key) return item;
          if (name === "allowBloodDonation" || name === "allowCommunityService")
            return { ...item, [name]: index === 0 && value === true };
          if (typeof value !== "string") return item;
          if (name === "fineKind") return {
            ...item, fineKind: isFineKind(value) ? value : "", amount: "", maximumFine: "",
          };
          return { ...item, [name]: value };
        }),
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
