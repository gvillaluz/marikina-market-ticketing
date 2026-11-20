import type { EnforcerPenaltyKind } from "@/api/types/enforcer.types";
import { formatCurrency, formatNumber } from "@/utils/formatters";
import { penaltyKindLabel } from "../../enforcerReport.utils";
import styles from "./EnforcerPenaltyRow.module.css";

export default function EnforcerPenaltyRow({
  kind,
}: {
  kind: EnforcerPenaltyKind;
}) {
  return (
    <tr>
      <th
        scope="row"
        className={kind.penaltyType ? undefined : styles.notRecorded}
      >
        {penaltyKindLabel(kind.penaltyType)}
      </th>
      <td>{formatNumber(kind.tickets)}</td>
      <td>{formatNumber(kind.settledTickets)}</td>
      <td>{formatNumber(kind.openTickets)}</td>
      <td>{kind.finesCharged > 0 ? formatCurrency(kind.finesCharged) : "—"}</td>
    </tr>
  );
}
