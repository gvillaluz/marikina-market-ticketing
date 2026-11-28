import { Badge } from "@/components/ui/Badge/Badge";
import { formatSeverityLevel } from "@/utils/formatters";

// Only Levels 4-5 are red: the tickets the market office must act on; the wording carries the rest.
export function SeverityLevelBadge({
  level,
}: {
  level: number | null | undefined;
}) {
  return (
    <Badge tone={level != null && level >= 4 ? "ticket" : "neutral"}>
      {formatSeverityLevel(level)}
    </Badge>
  );
}
