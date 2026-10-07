import { useRef, useState } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { useToast } from "@/components/ui/Toast/useToast";
import { useAuthStore } from "@/store/store";
import { ApiRequestError } from "@/utils/apiErrors";
import { marketSectionApi } from "@/api/endpoints/marketSection.api";
import type { MarketSectionResponse } from "@/api/types/market-section.types";
import { marketSectionsListKey } from "./useMarketSections";

export function useMarketSectionEditor() {
  const client = useQueryClient();
  const { showToast } = useToast();
  const canManage = useAuthStore((state) => state.user?.role === "Admin");
  const [open, setOpen] = useState(false);
  const [selected, setSelected] = useState<MarketSectionResponse | null>(null);
  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const [error, setError] = useState("");
  const lock = useRef(false);
  const [pendingId, setPendingId] = useState<number | null>(null);
  const save = useMutation({
    mutationFn: async () => {
      await client.cancelQueries({ queryKey: marketSectionsListKey });
      const request = { name: name.trim(), description: description.trim() };
      return selected ? marketSectionApi.update(selected.id, request) : marketSectionApi.create(request);
    },
    onSuccess: async (record) => {
      await client.cancelQueries({ queryKey: marketSectionsListKey });
      client.setQueryData<MarketSectionResponse[]>(marketSectionsListKey, (current = []) =>
        selected ? current.map((item) => item.id === selected.id ? record : item) : [...current, record]);
      setOpen(false);
      showToast({ variant: "success", title: selected ? "Market section updated" : "Market section added" });
    },
    onError: (cause) => setError(cause instanceof ApiRequestError && cause.serverMessage
      ? cause.serverMessage : "Unable to save the market section. Please try again."),
    onSettled: () => { lock.current = false; },
  });
  const status = useMutation({
    mutationFn: async (section: MarketSectionResponse) => {
      await client.cancelQueries({ queryKey: marketSectionsListKey });
      await marketSectionApi.updateActive(section.id, !section.isActive);
      return section;
    },
    onSuccess: async (section) => {
      await client.cancelQueries({ queryKey: marketSectionsListKey });
      client.setQueryData<MarketSectionResponse[]>(marketSectionsListKey, (current = []) =>
        current.map((item) => item.id === section.id ? { ...item, isActive: !section.isActive } : item));
      showToast({ variant: "success", title: section.isActive ? "Market section marked inactive" : "Market section marked active" });
    },
    onError: (cause) => showToast({ variant: "error", title: "Status update failed", description:
      cause instanceof ApiRequestError && cause.serverMessage ? cause.serverMessage : "Unable to update section status. Please try again." }),
    onSettled: () => { lock.current = false; setPendingId(null); },
  });
  return {
    open, selected, name, setName, description, setDescription, error,
    canManage, isSaving: save.isPending, pendingId,
    launch(section: MarketSectionResponse | null = null) {
      if (!canManage || lock.current) return;
      setSelected(section); setName(section?.name ?? ""); setDescription(section?.description ?? "");
      setError(""); setOpen(true);
    },
    close() { if (!lock.current) setOpen(false); },
    submit() {
      if (!canManage || lock.current) return;
      if (!name.trim() || !description.trim()) { setError("Section name and description are required."); return; }
      setError(""); lock.current = true; save.mutate();
    },
    toggle(section: MarketSectionResponse) {
      if (!canManage || lock.current) return;
      lock.current = true; setPendingId(section.id); status.mutate(section);
    },
  };
}
