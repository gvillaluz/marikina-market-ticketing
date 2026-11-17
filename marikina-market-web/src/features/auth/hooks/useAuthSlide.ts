import { useRef } from "react";
import { useLocation } from "react-router-dom";
import { authStepRank, slideDirection, type SlideDirection } from "../motion";

// Which way the login card's content slides when the page changes.
// The first page has no direction: the opening sequence plays instead.
export function useAuthSlide() {
  const { pathname } = useLocation();
  const last = useRef<{ pathname: string; direction: SlideDirection | null }>({
    pathname,
    direction: null,
  });
  if (last.current.pathname !== pathname) {
    last.current = {
      pathname,
      direction: slideDirection(
        authStepRank(last.current.pathname),
        authStepRank(pathname),
      ),
    };
  }
  return last.current;
}
