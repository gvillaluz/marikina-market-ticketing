import { useRef, useState } from "react";
import { flushSync } from "react-dom";
import { useReactToPrint } from "react-to-print";
import { useToast } from "@/components/ui/Toast/useToast";
import { getApiErrorMessage } from "@/utils/apiErrors";
import {
  downloadCsv,
  fetchAllRows,
  type ExportColumn,
  type RowPage,
} from "@/utils/tableExport";

interface TableExportOptions<T> {
  title: string;
  fileName: string;
  columns: ExportColumn<T>[];
  fetchPage: (offset: number) => Promise<RowPage<T>>;
}

export type TableExportAction = "export" | "print";

const PAGE_STYLE = `
  @page { size: A4 landscape; margin: 10mm; }
`;

// Export and Print for a table: both collect every matching row first.
export function useTableExport<T>({
  title,
  fileName,
  columns,
  fetchPage,
}: TableExportOptions<T>) {
  const printRef = useRef<HTMLDivElement>(null);
  const running = useRef(false);
  const [preparing, setPreparing] = useState<TableExportAction | null>(null);
  const [printRows, setPrintRows] = useState<T[] | null>(null);
  const { showToast } = useToast();
  const openPrint = useReactToPrint({
    contentRef: printRef,
    documentTitle: title,
    pageStyle: PAGE_STYLE,
    onAfterPrint: () => setPrintRows(null),
    onPrintError: () => {
      setPrintRows(null);
      showToast({
        title: "Print failed",
        description: "Couldn't open the print window. Please try again.",
        variant: "error",
      });
    },
  });

  async function run(action: TableExportAction) {
    if (running.current) return;
    running.current = true;
    setPreparing(action);
    try {
      const rows = await fetchAllRows(fetchPage);
      if (rows.length === 0) {
        showToast({
          title: "Nothing to " + action,
          description: "No records match the current search and filters.",
          variant: "info",
        });
      } else if (action === "export") {
        downloadCsv(fileName, columns, rows);
        showToast({ title: "Export downloaded", variant: "success" });
      } else {
        flushSync(() => setPrintRows(rows));
        openPrint();
      }
    } catch (error: unknown) {
      showToast({
        title: action === "export" ? "Export failed" : "Print failed",
        description: getApiErrorMessage(
          error,
          "Couldn't load the records. Please try again.",
        ),
        variant: "error",
      });
    } finally {
      running.current = false;
      setPreparing(null);
    }
  }

  return {
    preparing,
    exportFile: () => run("export"),
    print: () => run("print"),
    printTable: { contentRef: printRef, title, columns, rows: printRows },
  };
}
