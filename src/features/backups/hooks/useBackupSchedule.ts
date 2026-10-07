import { useRef, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { backupsApi } from "@/api/endpoints/backups.api";
import type { UpdateBackupScheduleRequest } from "@/api/types/backups.types";
import {
  backupError,
  backupKeys,
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
    queryFn: ({ signal }) => backupsApi.getSchedule(signal),
    enabled: canManage,
  });
  const fields = draft ?? query.data;
  const mutation = useMutation({
    mutationFn: backupsApi.updateSchedule,
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
  const weekdays = [
    "Sunday",
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
  ];
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
    weekdayOptions: weekdays.map((label, value) => ({
      value: String(value),
      label,
    })),
    retentionOptions: retentionDays.map((days) => ({
      value: String(days),
      label: `${days} days`,
    })),
    weekdayValue: fields?.dayOfWeek == null ? "" : String(fields.dayOfWeek),
    weekdayLabel:
      fields?.dayOfWeek == null ? "Select a day" : weekdays[fields.dayOfWeek],
    retentionValue: String(fields?.retentionDays ?? ""),
    retentionLabel: fields
      ? `${fields.retentionDays} days`
      : "Select a retention period",
    changeWeekday(value: string) {
      if (/^[0-6]$/.test(value)) change("dayOfWeek", Number(value));
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
