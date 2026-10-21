import { useRef, useState } from "react";
import { toPng } from "html-to-image";
import jsPDF from "jspdf";
import type { ReportDocument } from "@/api/types/reports.types";
import { reportCsv } from "../reports.utils";

export function useReportExport(report?: ReportDocument) {
  const [busy, setBusy] = useState<"pdf" | "csv" | null>(null);
  const [error, setError] = useState("");
  const exporting = useRef(false);
  const paperRef = useRef<HTMLElement>(null);
  async function download(action: "pdf" | "csv") {
    if (!report || exporting.current) return;
    exporting.current = true;
    setBusy(action);
    setError("");
    const fileName = `Marikina-Market-${"id" in report ? `Report-${report.id}` : "Preview"}-${report.dateRange.from}-${report.dateRange.to}`;
    try {
      if (action === "csv") {
        const url = URL.createObjectURL(
          new Blob([reportCsv(report)], { type: "text/csv;charset=utf-8;" }),
        );
        const link = document.createElement("a");
        link.href = url;
        link.download = `${fileName}.csv`;
        document.body.appendChild(link);
        try {
          link.click();
        } finally {
          link.remove();
          window.setTimeout(() => URL.revokeObjectURL(url), 1000);
        }
      } else {
        const paper = paperRef.current;
        if (!paper) throw new Error("Report paper unavailable");
        await document.fonts.ready;
        const width = paper.scrollWidth;
        const height = paper.scrollHeight;
        const dataUrl = await toPng(paper, {
          pixelRatio: 3,
          backgroundColor: getComputedStyle(paper).backgroundColor,
          style: {
            margin: "0",
            marginInline: "0",
            transform: "none",
            boxShadow: "none",
            animation: "none",
          },
        });
        const pdf = new jsPDF({
          orientation: "landscape",
          unit: "px",
          format: [width, height],
          hotfixes: ["px_scaling"],
          compress: true,
        });
        pdf.addImage(dataUrl, "PNG", 0, 0, width, height);
        pdf.save(`${fileName}.pdf`);
      }
    } catch {
      setError(
        `Unable to export the ${action.toUpperCase()} file. Please try again.`,
      );
    } finally {
      exporting.current = false;
      setBusy(null);
    }
  }
  return { paperRef, busy, error, download };
}
