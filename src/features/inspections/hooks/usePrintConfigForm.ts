import { useState } from "react";
import { PRINT_COLUMN_OPTIONS } from "../../../utils/constants";
import { usePrintExport } from "../hooks/usePrintExport";
import type { PrintConfigPayload } from "../../../api/types/ticket.types";

const EXPORT_FORMATS = [
  { value: "csv", label: "CSV" },
  { value: "xlsx", label: "Excel (XLSX)" },
  { value: "pdf", label: "PDF" },
] as const;

type RecordType = "warning" | "ticket";
type ExportFormat = (typeof EXPORT_FORMATS)[number]["value"];

export function usePrintConfigForm() {
  const [types, setTypes] = useState<RecordType[]>(["warning"]);
  const [columns, setColumns] = useState<PrintConfigPayload["columns"]>(
    PRINT_COLUMN_OPTIONS.filter((column) => column.value !== "severity").map(
      (c) => c.value,
    ),
  );
  const [format, setFormat] = useState<ExportFormat>("csv");
  const [startDate, setStartDate] = useState("");
  const [endDate, setEndDate] = useState("");

  const { mutate, isPending, isError } = usePrintExport();

  const toggleType = (value: RecordType) => {
    setTypes((prev) =>
      prev.includes(value) ? prev.filter((t) => t !== value) : [...prev, value],
    );
  };

  const toggleColumn = (value: PrintConfigPayload["columns"][number]) => {
    setColumns((prev) =>
      prev.includes(value) ? prev.filter((c) => c !== value) : [...prev, value],
    );
  };

  const handleGenerate = () => {
    mutate({ types, columns, startDate, endDate });
  };

  return {
    fields: { types, columns, format, startDate, endDate },
    setFields: { setFormat, setStartDate, setEndDate },
    toggleType,
    toggleColumn,
    handleGenerate,
    isPending,
    isError,
  };
}
