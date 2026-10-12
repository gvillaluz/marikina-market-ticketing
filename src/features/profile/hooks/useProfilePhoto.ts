import { useEffect, useId, useRef, useState, type ChangeEvent } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { profileApi } from "@/api/endpoints/profile.api";
import { useAuthStore } from "@/store/store";
import { useToast } from "@/components/ui/Toast/useToast";
import { ApiRequestError, getApiErrorMessage } from "@/utils/apiErrors";
import { normalizeUserRole } from "@/utils/roles";
import { validateProfilePhoto } from "../profile.validation";
import { validateProfile } from "./useProfile";

export function useProfilePhoto(userId: number | undefined, disabled = false) {
  const inputId = useId();
  const inputRef = useRef<HTMLInputElement>(null);
  const saving = useRef(false);
  const mounted = useRef(true);
  const [isSaving, setIsSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const queryClient = useQueryClient();
  const { showToast } = useToast();

  useEffect(() => {
    mounted.current = true;
    return () => {
      mounted.current = false;
    };
  }, []);

  async function upload(file: File | null) {
    if (!file || saving.current || disabled || !userId) return;
    let sessionValid = true;
    const isCurrentUser = () =>
      sessionValid &&
      useAuthStore.getState().isAuthenticated &&
      useAuthStore.getState().user?.userId === userId;
    if (!isCurrentUser()) return;
    const stopWatchingSession = useAuthStore.subscribe((current, previous) => {
      if (
        !current.isAuthenticated ||
        current.user?.userId !== userId ||
        current.isAuthenticated !== previous.isAuthenticated ||
        current.user?.userId !== previous.user?.userId
      )
        sessionValid = false;
    });
    saving.current = true;
    setIsSaving(true);
    setError(null);
    try {
      const validationError = await validateProfilePhoto(file);
      if (!isCurrentUser()) return;
      if (validationError) {
        if (mounted.current) setError(validationError);
        return;
      }
      const response = await profileApi.changePhoto(file);
      if (!isCurrentUser()) return;
      validateProfile(response);
      if (response.userId !== userId || typeof response.profileUrl !== "string")
        throw new ApiRequestError();
      const url = new URL(response.profileUrl);
      if (!["https:", "http:"].includes(url.protocol))
        throw new ApiRequestError();
      const updated = { ...response, role: normalizeUserRole(response.role) };
      await queryClient.cancelQueries({ queryKey: ["profile", userId] });
      if (!isCurrentUser()) return;
      useAuthStore.getState().setUser(updated);
      queryClient.setQueryData(["profile", userId], updated);
      showToast({ title: "Profile photo updated", variant: "success" });
    } catch (failure: unknown) {
      if (isCurrentUser() && mounted.current)
        setError(
          getApiErrorMessage(
            failure instanceof ApiRequestError ? failure : undefined,
            "Unable to update your profile photo. Please try again.",
          ),
        );
    } finally {
      stopWatchingSession();
      saving.current = false;
      if (mounted.current) setIsSaving(false);
    }
  }

  return {
    inputId,
    inputRef,
    isSaving,
    error,
    disabled: disabled || isSaving || !userId,
    choosePhoto: () => {
      if (!disabled && !saving.current && userId) inputRef.current?.click();
    },
    selectPhoto: (event: ChangeEvent<HTMLInputElement>) => {
      const file = event.currentTarget.files?.[0] ?? null;
      event.currentTarget.value = "";
      void upload(file);
    },
    upload,
  };
}

export type ProfilePhotoModel = ReturnType<typeof useProfilePhoto>;
