import { useState } from "react";
import { useToast } from "@/components/ui/Toast/useToast";
import { getApiErrorMessage } from "@/utils/apiErrors";
import {
  downloadCsv,
  fetchAllRows,
  manilaDay,
  type ExportColumn,
  type RowPage,
} from "@/utils/tableExport";

export type ExportRecordType = "Warning" | "Ticket";
export type ExportFormField = "types" | "columns" | "dates";

export interface PrintConfigOptions<T> {
  fileName: string;
  columns: ExportColumn<T>[];
  // Offered only on pages whose list holds more than one record type.
  recordTypes?: ExportRecordType[];
  fetchPage: (
    offset: number,
    type: ExportRecordType | undefined,
  ) => Promise<RowPage<T>>;
  onExported: () => void;
}

export function usePrintConfigForm<T extends { issuedAt: string | Date }>({
  fileName,
  columns,
  recordTypes,
  fetchPage,
  onExported,
}: PrintConfigOptions<T>) {
  const [types, setTypes] = useState<ExportRecordType[]>(recordTypes ?? []);
  const [columnKeys, setColumnKeys] = useState(
    columns.map((column) => column.key),
  );
  const [startDate, setStartDate] = useState("");
  const [endDate, setEndDate] = useState("");
  const [fieldError, setFieldError] = useState<{
    field: ExportFormField;
    message: string;
  } | null>(null);
  const [notice, setNotice] = useState<{
    kind: "error" | "empty";
    message: string;
  } | null>(null);
  const [isPending, setIsPending] = useState(false);
  const { showToast } = useToast();

  const toggleType = (value: ExportRecordType) => {
    setTypes((prev) =>
      prev.includes(value) ? prev.filter((t) => t !== value) : [...prev, value],
    );
  };

  const toggleColumn = (key: string) => {
    setColumnKeys((prev) =>
      prev.includes(key) ? prev.filter((c) => c !== key) : [...prev, key],
    );
  };

  const isInRange = (row: T) => {
    const day = manilaDay(row.issuedAt);
    return (!startDate || day >= startDate) && (!endDate || day <= endDate);
  };

  const handleGenerate = async () => {
    if (isPending) return;
    if (recordTypes && types.length === 0) {
      setFieldError({ field: "types", message: "Select at least one record type." });
      return;
    }
    if (columnKeys.length === 0) {
      setFieldError({
        field: "columns",
        message: "Select at least one column to include.",
      });
      return;
    }
    if (startDate && endDate && startDate > endDate) {
      setFieldError({
        field: "dates",
        message: "The start date must be on or before the end date.",
      });
      return;
    }

    setFieldError(null);
    setNotice(null);
    setIsPending(true);
    try {
      const type = types.length === 1 ? types[0] : undefined;
      const rows = (
        await fetchAllRows((offset) => fetchPage(offset, type))
      ).filter(isInRange);
      if (rows.length === 0) {
        setNotice({
          kind: "empty",
          message: `No records match these choices.${startDate || endDate ? " Try a wider date range." : ""}`,
        });
        return;
      }
      downloadCsv(
        fileName,
        columns.filter((column) => columnKeys.includes(column.key)),
        rows,
      );
      showToast({ title: "Export downloaded", variant: "success" });
      onExported();
    } catch (error: unknown) {
      setNotice({
        kind: "error",
        message: getApiErrorMessage(
          error,
          "Unable to generate the export. Please try again.",
        ),
      });
    } finally {
      setIsPending(false);
    }
  };

  return {
    recordTypes,
    columns: columns.map(({ key, header }) => ({ key, header })),
    fields: { types, columnKeys, startDate, endDate },
    setFields: { setStartDate, setEndDate },
    toggleType,
    toggleColumn,
    handleGenerate,
    isPending,
    fieldError,
    notice,
  };
}
