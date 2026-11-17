import { ROUTES } from "@/routes/routePaths";

export const SUCCESS_PAUSE_MS = 400;

export type SlideDirection = "forward" | "back";

// Where each login address sits on the way through. A later page is forward.
// The first forgot-password step (find account) is not listed: it takes the default.
const STEP_RANKS: Record<string, number> = {
  [ROUTES.adminLogin]: 0,
  [ROUTES.loginVerification]: 1,
  [ROUTES.changePassword]: 2,
  [`${ROUTES.forgotPassword}/options`]: 2,
  [`${ROUTES.forgotPassword}/verify`]: 3,
  [`${ROUTES.forgotPassword}/reset`]: 4,
};
const DEFAULT_STEP_RANK = 1;

export function authStepRank(pathname: string) {
  return STEP_RANKS[pathname] ?? DEFAULT_STEP_RANK;
}

export function slideDirection(from: number, to: number): SlideDirection {
  return to < from ? "back" : "forward";
}

function motionTurnedOff() {
  return (
    typeof window !== "undefined" &&
    window.matchMedia("(prefers-reduced-motion: reduce)").matches
  );
}

// Lets the success tick show before the next page opens.
export function successPause(): Promise<void> {
  if (motionTurnedOff()) return Promise.resolve();
  return new Promise((resolve) => window.setTimeout(resolve, SUCCESS_PAUSE_MS));
}

// 0 when a waiting time has just started, 1 when it is over.
export function cooldownProgress(remaining: number, total: number) {
  if (total <= 0) return 1;
  return Math.min(1, Math.max(0, 1 - remaining / total));
}
