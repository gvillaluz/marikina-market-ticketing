import { LucideIcon } from "lucide-react";
import StatCard from "@/components/ui/Card/StatCard/StatCard";
import ConfigStatCardSkeleton from "./ConfigStatCardSkeleton";
import UnavailableStatCard from "./UnavailableStatCard";

interface ConfigStatCardProps {
  icon: LucideIcon;
  iconColor: string;
  iconBg: string;
  label: string;
  value: string | number;
  note: string;
  isLoading: boolean;
  isFetching: boolean;
  error: string;
  onRetry: () => void;
}

export default function ConfigStatCard({
  icon,
  iconColor,
  iconBg,
  label,
  value,
  note,
  isLoading,
  isFetching,
  error,
  onRetry,
}: ConfigStatCardProps) {
  if (isLoading) return <ConfigStatCardSkeleton />;
  if (error)
    return (
      <UnavailableStatCard
        icon={icon}
        iconColor={iconColor}
        iconBg={iconBg}
        label={label}
        message={error}
        busy={isFetching}
        onRetry={onRetry}
      />
    );
  return (
    <StatCard
      icon={icon}
      iconColor={iconColor}
      iconBg={iconBg}
      value={value}
      label={label}
      note={note}
    />
  );
}
