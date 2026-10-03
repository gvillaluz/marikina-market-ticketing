import { useState } from "react";
import { PRINT_COLUMN_OPTIONS } from "../../../utils/constants";
import { usePrintExport } from "../hooks/usePrintExport";
import type { PrintConfigPayload } from "../../../api/types/ticket.types";

type RecordType = PrintConfigPayload["types"][number];

export function usePrintConfigForm(
  initialTypes: RecordType[],
  onExported: () => void,
) {
  const [types, setTypes] = useState<RecordType[]>(initialTypes);
  const [columns, setColumns] = useState<PrintConfigPayload["columns"]>(
    PRINT_COLUMN_OPTIONS.filter((column) => column.value !== "severity").map(
      (c) => c.value,
    ),
  );
  const [startDate, setStartDate] = useState("");
  const [endDate, setEndDate] = useState("");
  const [validationError, setValidationError] = useState("");

  const { mutate, isPending, isError, error } = usePrintExport();

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
    if (types.length === 0) {
      setValidationError("Select at least one record type.");
      return;
    }
    if (columns.length === 0) {
      setValidationError("Select at least one column to include.");
      return;
    }
    if (startDate && endDate && startDate > endDate) {
      setValidationError("The start date must be on or before the end date.");
      return;
    }

    setValidationError("");
    mutate({ types, columns, startDate, endDate }, { onSuccess: onExported });
  };

  return {
    fields: { types, columns, startDate, endDate },
    setFields: { setStartDate, setEndDate },
    toggleType,
    toggleColumn,
    handleGenerate,
    isPending,
    isError,
    error,
    validationError,
  };
}

export type PrintConfigFormState = ReturnType<typeof usePrintConfigForm>;
