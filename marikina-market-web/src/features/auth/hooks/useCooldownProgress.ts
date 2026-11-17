import { useRef } from "react";
import { cooldownProgress } from "../motion";

export function useCooldownProgress(remaining: number) {
  const total = useRef(0);
  if (remaining === 0) total.current = 0;
  else if (remaining > total.current) total.current = remaining;
  return cooldownProgress(remaining, total.current);
}
