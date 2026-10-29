import { useEffect, useRef } from "react";

export function useLandingMotion() {
  const landingRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const chart = landingRef.current?.querySelector("[data-landing-chart]");
    if (!chart || typeof IntersectionObserver === "undefined") return;

    const preference = window.matchMedia("(prefers-reduced-motion: reduce)");
    if (preference.matches) return;

    const animations: Animation[] = [];
    const observer = new IntersectionObserver(
      (entries) => {
        if (!entries.some((entry) => entry.isIntersecting)) return;
        observer.disconnect();
        if (preference.matches) return;

        chart.querySelectorAll<HTMLElement>("[data-landing-bar]").forEach((bar, index) => {
          if (typeof bar.animate !== "function") return;
          animations.push(
            bar.animate(
              [
                { transform: "scaleX(0.08)", opacity: 0.5 },
                { transform: "none", opacity: 1 },
              ],
              {
                duration: 650,
                delay: index * 45,
                easing: "cubic-bezier(0.16, 1, 0.3, 1)",
              },
            ),
          );
        });
      },
      { threshold: 0.25 },
    );

    const cancelMotion = () => {
      if (!preference.matches) return;
      observer.disconnect();
      animations.forEach((animation) => animation.cancel());
    };
    observer.observe(chart);
    preference.addEventListener("change", cancelMotion);

    return () => {
      observer.disconnect();
      animations.forEach((animation) => animation.cancel());
      preference.removeEventListener("change", cancelMotion);
    };
  }, []);

  return landingRef;
}
