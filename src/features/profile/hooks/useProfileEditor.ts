import { useRef, useState } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { profileApi, type ProfileResponse } from "@/api/endpoints/profile.api";
import { useAuthStore } from "@/store/store";
import { useToast } from "@/components/ui/Toast/useToast";
import { ApiRequestError, getApiErrorMessage } from "@/utils/apiErrors";
import { normalizeUserRole } from "@/utils/roles";
import { validateProfile } from "./useProfile";
import {
  profilePayload,
  validateProfileForm,
  type ProfileField,
  type ProfileFormValues,
} from "../profile.validation";

export function useProfileEditor(
  profile: ProfileResponse,
  onClose: () => void,
) {
  const [values, setValues] = useState<ProfileFormValues>({
    firstName: profile.firstName,
    middleName: profile.middleName ?? "",
    lastName: profile.lastName,
    dateOfBirth: profile.dateOfBirth,
    email: profile.email,
    phoneNumber: profile.phoneNumber,
    houseNumber: profile.houseNumber,
    street: profile.street,
    barangay: profile.barangay,
    city: profile.city,
  });
  const [touched, setTouched] = useState<
    Partial<Record<ProfileField, boolean>>
  >({});
  const [isSaving, setIsSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const saving = useRef(false);
  const queryClient = useQueryClient();
  const { showToast } = useToast();
  const errors = validateProfileForm(values);
  const payload = profilePayload(values);
  const initialPayload = useRef(payload);
  const hasChanges = (Object.keys(payload) as ProfileField[]).some(
    (field) => payload[field] !== initialPayload.current[field],
  );

  async function submit() {
    if (
      saving.current ||
      !hasChanges ||
      Object.keys(validateProfileForm(values)).length > 0
    )
      return;
    saving.current = true;
    setIsSaving(true);
    setError(null);
    try {
      const response = await profileApi.update(payload);
      validateProfile(response);
      if (response.userId !== profile.userId) throw new ApiRequestError();
      const updated = { ...response, role: normalizeUserRole(response.role) };
      if (useAuthStore.getState().user?.userId !== profile.userId) return;
      await queryClient.cancelQueries({
        queryKey: ["profile", profile.userId],
      });
      if (useAuthStore.getState().user?.userId !== profile.userId) return;
      useAuthStore.getState().setUser(updated);
      queryClient.setQueryData(["profile", profile.userId], updated);
      showToast({ title: "Profile updated", variant: "success" });
      onClose();
    } catch (failure: unknown) {
      setError(
        getApiErrorMessage(
          failure instanceof ApiRequestError ? failure : undefined,
          "Unable to update your profile. Please try again.",
        ),
      );
    } finally {
      saving.current = false;
      setIsSaving(false);
    }
  }

  return {
    values,
    errors,
    touched,
    error,
    isSaving,
    canSubmit: hasChanges && Object.keys(errors).length === 0 && !isSaving,
    change(field: ProfileField, value: string) {
      setValues((current) => ({ ...current, [field]: value }));
      setTouched((current) => ({ ...current, [field]: true }));
      setError(null);
    },
    blur(field: ProfileField) {
      setTouched((current) => ({ ...current, [field]: true }));
    },
    submit,
    close: () => {
      if (!saving.current) onClose();
    },
  };
}
