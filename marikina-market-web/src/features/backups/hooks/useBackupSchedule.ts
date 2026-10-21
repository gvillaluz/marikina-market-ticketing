import { useRef, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { backupsApi } from "@/api/endpoints/backups.api";
import type { UpdateBackupScheduleRequest } from "@/api/types/backups.types";
import {
  backupError,
  backupKeys,
  backupWeekdays,
  validateBackupScheduleResponse,
  validateBackupSchedule,
} from "../backups.utils";

export function useBackupSchedule(canManage: boolean) {
  const client = useQueryClient();
  const [draft, setDraft] = useState<UpdateBackupScheduleRequest | null>(null);
  const [error, setError] = useState("");
  const [saved, setSaved] = useState(false);
  const saving = useRef(false);
  const query = useQuery({
    queryKey: backupKeys.schedule,
    queryFn: async ({ signal }) =>
      validateBackupScheduleResponse(await backupsApi.getSchedule(signal)),
    enabled: canManage,
  });
  const fields = draft ?? query.data;
  const mutation = useMutation({
    mutationFn: async (request: UpdateBackupScheduleRequest) =>
      validateBackupScheduleResponse(await backupsApi.updateSchedule(request)),
    retry: false,
    onSuccess: (response) => {
      client.setQueryData(backupKeys.schedule, response);
      setDraft(null);
      setSaved(true);
      void client.invalidateQueries({ queryKey: backupKeys.health });
    },
    onError: (cause) =>
      setError(
        backupError(
          cause,
          "Unable to save the backup schedule. Please try again.",
        ),
      ),
    onSettled: () => {
      saving.current = false;
    },
  });
  const disabled = !canManage || !fields || mutation.isPending;
  const retentionDays = [
    ...new Set([
      7,
      30,
      90,
      ...(fields?.retentionDays ? [fields.retentionDays] : []),
    ]),
  ].sort((a, b) => a - b);
  function change<K extends keyof UpdateBackupScheduleRequest>(
    name: K,
    value: UpdateBackupScheduleRequest[K],
  ) {
    if (disabled || saving.current || !fields) return;
    setDraft({ ...fields, [name]: value });
    setError("");
    setSaved(false);
  }
  return {
    fields,
    disabled,
    isLoading: query.isPending,
    isError: query.isError,
    loadError: backupError(
      query.error,
      "Unable to load the backup schedule. Please try again.",
    ),
    isFetching: query.isFetching,
    isSaving: mutation.isPending,
    error,
    saved,
    timeZoneDisplay: query.data?.timeZoneDisplay || "Philippine Time (UTC+8)",
    frequencyOptions: [
      { value: "Daily", label: "Daily" },
      { value: "Weekly", label: "Weekly" },
    ] as const,
    weekdayOptions: backupWeekdays.map((day) => ({
      value: day,
      label: day,
    })),
    retentionOptions: retentionDays.map((days) => ({
      value: String(days),
      label: `${days} days`,
    })),
    weekdayValue: fields?.dayOfWeek ?? "",
    weekdayLabel: fields?.dayOfWeek ?? "Select a day",
    retentionValue: String(fields?.retentionDays ?? ""),
    retentionLabel: fields
      ? `${fields.retentionDays} days`
      : "Select a retention period",
    changeWeekday(value: string) {
      const day = backupWeekdays.find((weekday) => weekday === value);
      if (day) change("dayOfWeek", day);
    },
    changeRetention(value: string) {
      if (retentionDays.some((days) => String(days) === value))
        change("retentionDays", Number(value));
    },
    retry() {
      void query.refetch();
    },
    change,
    submit() {
      if (disabled || saving.current || !fields) return;
      const request = {
        enabled: fields.enabled,
        frequency: fields.frequency,
        dayOfWeek: fields.frequency === "Weekly" ? fields.dayOfWeek : null,
        time: fields.time,
        retentionDays: fields.retentionDays,
      };
      const validation = validateBackupSchedule(request);
      if (validation) {
        setError(validation);
        return;
      }
      saving.current = true;
      setError("");
      setSaved(false);
      mutation.mutate(request);
    },
  };
}

export type BackupScheduleModel = ReturnType<typeof useBackupSchedule>;
