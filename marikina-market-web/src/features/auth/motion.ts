export const SUCCESS_PAUSE_MS = 400;

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
