import { useEffect } from "react";
import { useNavigate } from "react-router-dom";
import type { User } from "@/features/auth/auth.types";
import { ADMIN_ROLES } from "@/api/types/common.types";
import { userDeviceTokenApi } from "@/api/endpoints/userDeviceToken.api";
import env, { isFirebasePushConfigured } from "@/config/env";
import { useToast } from "@/components/ui/Toast/useToast";
import { getApiErrorMessage } from "@/utils/apiErrors";
import {
  getBrowserMessaging,
  getBrowserPushToken,
  subscribeToMessages,
} from "../firebaseMessaging";
import { getVendorRegistrationReviewPath } from "../notification.utils";

const registeredTokens = new Set<string>();
const tokenRegistrations = new Map<string, Promise<void>>();

interface UseAdminPushNotificationsOptions {
  user: User | null;
  isAuthenticated: boolean;
  isAuthReady: boolean;
}

function serviceWorkerUrl(): URL {
  const url = new URL("/firebase-messaging-sw.js", window.location.origin);
  const { apiKey, authDomain, projectId, messagingSenderId, appId } =
    env.firebase;
  url.search = new URLSearchParams({
    apiKey,
    authDomain,
    projectId,
    messagingSenderId,
    appId,
  }).toString();
  return url;
}

async function registerTokenOnce(userId: number, deviceToken: string) {
  const key = `${userId}:${deviceToken}`;
  if (registeredTokens.has(key)) return;
  const activeRegistration = tokenRegistrations.get(key);
  if (activeRegistration) return activeRegistration;

  const registration = userDeviceTokenApi
    .register(deviceToken)
    .then(() => {
      registeredTokens.add(key);
    })
    .finally(() => {
      tokenRegistrations.delete(key);
    });
  tokenRegistrations.set(key, registration);
  return registration;
}

export function useAdminPushNotifications({
  user,
  isAuthenticated,
  isAuthReady,
}: UseAdminPushNotificationsOptions): void {
  const navigate = useNavigate();
  const { showToast } = useToast();

  useEffect(() => {
    if (
      !isAuthReady ||
      !isAuthenticated ||
      !user ||
      !user.role ||
      !ADMIN_ROLES.includes(user.role) ||
      !isFirebasePushConfigured ||
      typeof Notification === "undefined" ||
      !("serviceWorker" in navigator)
    ) {
      return;
    }

    let cancelled = false;
    let unsubscribe: () => void = () => {};

    const initializePush = async () => {
      const messaging = await getBrowserMessaging();
      if (!messaging || cancelled) return;

      const stopListening = await subscribeToMessages(messaging, (payload) => {
        const reviewPath = getVendorRegistrationReviewPath(payload.data);
        if (!reviewPath) return;

        showToast({
          title: "New vendor registration request",
          description: "A vendor submitted an application for review.",
          actionLabel: "Review registration",
          onAction: () => navigate(reviewPath),
          duration: 12_000,
          variant: "info",
        });
      });
      if (cancelled) {
        stopListening();
        return;
      }
      unsubscribe = stopListening;

      let permission = Notification.permission;
      if (permission === "default") {
        permission = await Notification.requestPermission();
      }
      if (cancelled || permission !== "granted") return;

      const registration = await navigator.serviceWorker.register(
        serviceWorkerUrl().toString(),
        { scope: "/" },
      );
      const deviceToken = await getBrowserPushToken(messaging, registration);
      if (!cancelled) await registerTokenOnce(user.userId, deviceToken);
    };

    void initializePush().catch((failure: unknown) => {
      if (!cancelled) {
        showToast({
          title: "Browser notifications unavailable",
          description: getApiErrorMessage(
            failure,
            "We couldn't connect this browser for new registration alerts.",
          ),
          variant: "warning",
        });
      }
    });

    return () => {
      cancelled = true;
      unsubscribe();
    };
  }, [
    isAuthReady,
    isAuthenticated,
    navigate,
    showToast,
    user,
  ]);
}
