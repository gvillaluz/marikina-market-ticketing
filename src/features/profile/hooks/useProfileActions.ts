import { useState } from "react";

export function useProfileActions() {
  const [activeModal, setActiveModal] = useState<"password" | "profile" | null>(
    null,
  );
  return {
    activeModal,
    openPassword: () => setActiveModal("password"),
    openProfile: () => setActiveModal("profile"),
    close: () => setActiveModal(null),
  };
}
