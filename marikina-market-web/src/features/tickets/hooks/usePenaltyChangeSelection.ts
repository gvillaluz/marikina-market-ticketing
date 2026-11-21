import { useState } from "react";
import type {
  ChangePenaltyRequest,
  PenaltyChangeReason,
  PenaltyOptions,
  PenaltyType,
} from "@/api/types/ticket.types";
import { penaltyLabel } from "../tickets.utils";

const HOURS_ERROR = "Enter at least 3 whole hours.";

export type PenaltyChangeSelection = ReturnType<typeof usePenaltyChangeSelection>;

// Choices left untouched (null) follow the loaded options, so a fresh load or reset starts from the ticket's current penalty.
export function usePenaltyChangeSelection(options: PenaltyOptions | undefined) {
  const [penalty, setPenalty] = useState<PenaltyType | null>(null);
  const [hoursText, setHoursText] = useState<string | null>(null);
  const [reason, setReason] = useState<PenaltyChangeReason | null>(null);

  const current = options?.currentPenaltyType ?? undefined;
  const isAllowed = (type: PenaltyType) =>
    options?.allowedPenaltyTypes.includes(type) ?? false;
  const selectedPenalty = penalty ?? current;
  const hours =
    hoursText ??
    (current === "CommunityService" && options?.communityServiceHours != null
      ? String(options.communityServiceHours)
      : "");
  const needsHours = selectedPenalty === "CommunityService";
  const hoursValid = /^\d+$/.test(hours.trim()) && Number(hours) >= 3;
  const hoursError = needsHours && !hoursValid ? HOURS_ERROR : null;
  const changed =
    selectedPenalty !== undefined &&
    selectedPenalty !== current &&
    isAllowed(selectedPenalty);
  const canConfirm = changed && hoursError === null && reason !== null;

  let summary = "Select a different penalty.";
  if (changed && hoursError) summary = HOURS_ERROR;
  else if (changed && reason === null) summary = "Select a reason for the change.";
  else if (changed)
    summary = `${penaltyLabel(current)} → ${penaltyLabel(selectedPenalty)}${
      needsHours ? ` (${Number(hours)} hours)` : ""
    }. This will be recorded in the ticket history.`;

  return {
    selectedPenalty,
    selectPenalty: (type: PenaltyType) => {
      if (isAllowed(type)) setPenalty(type);
    },
    isAllowed,
    hours,
    setHours: setHoursText,
    needsHours,
    hoursError,
    reason,
    setReason,
    canConfirm,
    summary,
    request: (): ChangePenaltyRequest | null =>
      canConfirm && options && selectedPenalty && reason
        ? {
            penaltyType: selectedPenalty,
            communityServiceHours: needsHours ? Number(hours) : null,
            reason,
            version: options.version,
          }
        : null,
    reset: () => {
      setPenalty(null);
      setHoursText(null);
      setReason(null);
    },
  };
}
