import { RecordBadge } from "@/components/ui/Records";
import SearchHighlight from "@/components/ui/SearchHighlight";
import StackedCell from "@/components/ui/StackedCell";

const UNAVAILABLE = "Historical business details unavailable.";

interface BusinessCellProps {
  vendorId: number | null;
  name: string;
  owner: string;
  search?: string;
}

// A business and its registered owner in one table cell.
export default function BusinessCell({
  vendorId,
  name,
  owner,
  search = "",
}: BusinessCellProps) {
  if (vendorId === null)
    return (
      <span className="text-truncate">
        <RecordBadge value="Unregistered" />
      </span>
    );
  if (name === UNAVAILABLE && owner === UNAVAILABLE) return <span>{name}</span>;

  return (
    <StackedCell
      primary={<SearchHighlight text={name} search={search} />}
      secondary={
        <>
          Owner: <SearchHighlight text={owner} search={search} />
        </>
      }
    />
  );
}
