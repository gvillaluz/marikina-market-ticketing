import { Pencil } from "lucide-react";
import type { MarketSectionResponse } from "../api/marketSection.api";

interface MarketSectionRowProps {
  section: MarketSectionResponse;
}

export default function MarketSectionRow({ section }: MarketSectionRowProps) {
  return (
    <tr>
      <th scope="row" className="directory-cell pl-4.5! font-medium wrap-anywhere text-ui-heading">{section.name}</th>
      <td className="directory-cell wrap-anywhere">{section.description}</td>
      <td className="directory-cell">{section.vendorCount.toLocaleString()}</td>
      <td className="directory-cell">
        <span className={`inline-flex items-center gap-1.25 rounded-pill border px-2! py-0.75! text-micro font-medium leading-badge ${
          section.isActive
            ? "border-ui-success-border bg-ui-success-subtle text-ui-success"
            : "border-ui-inactive-border bg-ui-inactive-subtle text-ui-inactive"
        }`}>
          <span className="size-1.25 rounded-full bg-current" aria-hidden="true" />
          {section.isActive ? "Active" : "Inactive"}
        </span>
      </td>
      <td className="directory-cell">
        <div className="flex items-center justify-end gap-3">
          <button
            type="button"
            className="control-focus grid size-8 shrink-0 place-items-center rounded-ui-sm border border-ui-border bg-ui-surface text-ui-info disabled:cursor-not-allowed!"
            disabled
            aria-label={`Edit ${section.name}`}
            aria-describedby="market-section-actions-note"
            title="Editing sections is currently unavailable"
          >
            <Pencil size={14} aria-hidden="true" />
          </button>
          <button
            type="button"
            role="switch"
            aria-checked={section.isActive}
            aria-label={`${section.name} active status`}
            aria-describedby="market-section-actions-note"
            title="Changing section status is currently unavailable"
            className={`control-focus flex h-5 w-8.75 shrink-0 items-center rounded-pill border-0 p-0.75! disabled:cursor-not-allowed! ${
              section.isActive ? "justify-end bg-ui-info" : "bg-ui-switch-off"
            }`}
            disabled
          >
            <span className="size-3.5 rounded-full bg-ui-surface" aria-hidden="true" />
          </button>
        </div>
      </td>
    </tr>
  );
}
