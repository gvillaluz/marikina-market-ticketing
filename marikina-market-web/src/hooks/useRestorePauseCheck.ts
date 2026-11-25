import { useEffect } from "react";
import { authApi } from "@/api/endpoints/auth.api";
import { useAuthStore } from "@/store/store";

const CHECK_INTERVAL = 15_000;

// While the pause banner shows, ask the server now and then whether the restore is over. Its answer
// clears the banner (any normal answer) or, once everyone has been signed out, sends the page to sign-in.
export function useRestorePauseCheck(paused: boolean) {
  useEffect(() => {
    if (!paused) return;
    const timer = window.setInterval(() => {
      const token = useAuthStore.getState().token;
      if (token) authApi.getMe(token).catch(() => {});
    }, CHECK_INTERVAL);
    return () => window.clearInterval(timer);
  }, [paused]);
}
