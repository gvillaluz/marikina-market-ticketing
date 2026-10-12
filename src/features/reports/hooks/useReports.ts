import { useRef, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { reportsApi } from "@/api/endpoints/reports.api";
import { ApiRequestError } from "@/utils/apiErrors";
import type {
  GenerateReportInput,
  ReportType,
} from "@/api/types/reports.types";
import {
  manilaToday,
  reportPreset,
  validateReportRange,
  type ReportPreset,
} from "../reports.utils";
import { useReportHistory } from "./useReportHistory";

export function useReports() {
  const client = useQueryClient();
  const [input, setInput] = useState<GenerateReportInput>({
    from: "",
    to: "",
    type: "Warning & Ticket",
  });
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [validation, setValidation] = useState("");
  const generating = useRef(false);
  const previewRef = useRef<HTMLElement>(null);
  const today = manilaToday();
  const history = useReportHistory();
  const previewEnabled =
    selectedId === null &&
    input.from === input.to &&
    !validateReportRange(input, today);
  const preview = useQuery({
    retry: false,
    queryKey: ["reports", "preview", input.from, input.type],
    queryFn: ({ signal }) => reportsApi.preview(input.from, input.type, signal),
    enabled: previewEnabled,
  });
  const detail = useQuery({
    retry: false,
    queryKey: ["reports", "detail", selectedId],
    queryFn: ({ signal }) => reportsApi.detail(selectedId!, signal),
    enabled: selectedId !== null,
  });
  const generation = useMutation({
    mutationFn: reportsApi.generate,
    retry: false,
    onSuccess(report) {
      client.setQueryData(["reports", "detail", report.id], report);
      setSelectedId(report.id);
      history.changeSearch("");
      history.changeType("all");
      void client.invalidateQueries({ queryKey: ["reports", "history"] });
    },
    onSettled() {
      generating.current = false;
    },
  });
  const query = selectedId !== null ? detail : previewEnabled ? preview : null;
  function update(next: GenerateReportInput) {
    if (generation.isPending) return;
    setInput(next);
    setSelectedId(null);
    setValidation("");
    generation.reset();
  }
  return {
    input,
    today,
    history,
    previewRef,
    report: query?.data,
    loading: query?.isPending ?? false,
    generating: generation.isPending,
    validation,
    error: query?.isError
      ? query.error instanceof ApiRequestError && query.error.serverMessage
        ? query.error.serverMessage
        : "Unable to load this report. Please try again."
      : "",
    generationError: generation.isError
      ? generation.error instanceof ApiRequestError &&
        generation.error.serverMessage
        ? generation.error.serverMessage
        : "Unable to generate the report. Please try again."
      : "",
    updateFrom(from: string) {
      update({ ...input, from, to: input.to || from });
    },
    updateTo(to: string) {
      update({ ...input, to });
    },
    updateType(type: ReportType) {
      update({ ...input, type });
    },
    preset(preset: ReportPreset) {
      update({ ...input, ...reportPreset(preset, today) });
    },
    generate() {
      if (generating.current || generation.isPending) return;
      const error = validateReportRange(input, today);
      setValidation(error);
      if (error) return;
      generating.current = true;
      generation.mutate(input);
    },
    view(id: number) {
      if (generation.isPending || !Number.isSafeInteger(id) || id <= 0) return;
      const item = history.rows.find((report) => report.id === id);
      if (item) setInput({ ...item.dateRange, type: item.type });
      setSelectedId(id);
      setValidation("");
      generation.reset();
      previewRef.current?.scrollIntoView({
        behavior: window.matchMedia("(prefers-reduced-motion: reduce)").matches
          ? "instant"
          : "smooth",
        block: "start",
      });
    },
    retry() {
      void query?.refetch();
    },
  };
}
export type ReportsModel = ReturnType<typeof useReports>;
