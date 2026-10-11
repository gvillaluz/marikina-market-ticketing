import { useEffect } from "react";
import { useNavigate } from "react-router-dom";
import type { User } from "@/features/auth/auth.types";
import { ADMIN_ROLES, STAFF_ROLES } from "@/api/types/common.types";
import { userDeviceTokenApi } from "@/api/endpoints/userDeviceToken.api";
import { authApi } from "@/api/endpoints/auth.api";
import env, { isFirebasePushConfigured } from "@/config/env";
import { useToast } from "@/components/ui/Toast/useToast";
import { ApiRequestError, getApiErrorMessage } from "@/utils/apiErrors";
import {
  getBrowserMessaging,
  getBrowserPushToken,
  subscribeToMessages,
} from "../firebaseMessaging";
import { getVendorRegistrationReviewPath } from "../notification.utils";

const tokenRegistrations = new Map<string, Promise<void>>();
let registrationVersion = 0;
let browserDeviceToken: string | null = null;
let pushLogout: Promise<void> | null = null;

export function logoutBrowserPushNotifications(): Promise<void> {
  const deviceToken = browserDeviceToken;
  browserDeviceToken = null;
  registrationVersion += 1;
  const pending = [...tokenRegistrations.values()];
  tokenRegistrations.clear();
  if (!deviceToken && pushLogout) return pushLogout;
  const request = Promise.allSettled(pending).then(async () => {
    if (deviceToken) await authApi.logout(deviceToken);
  });
  pushLogout = request;
  const clearLogout = () => {
    if (pushLogout === request) pushLogout = null;
  };
  void request.then(clearLogout, clearLogout);
  return request;
}

function logPushStep(
  step: string,
  details?: Record<string, string | boolean | null>,
): void {
  if (import.meta.env.DEV) console.info(`[Web push] ${step}`, details ?? {});
}

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
  const activeRegistration = tokenRegistrations.get(key);
  if (activeRegistration) return activeRegistration;

  const registration = userDeviceTokenApi.register(deviceToken).finally(() => {
    if (tokenRegistrations.get(key) === registration)
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
      !STAFF_ROLES.includes(user.role)
    ) {
      return;
    }

    if (
      !isFirebasePushConfigured ||
      typeof Notification === "undefined" ||
      !("serviceWorker" in navigator)
    ) {
      logPushStep("Setup skipped", {
        firebaseConfigured: isFirebasePushConfigured,
        notificationSupported: typeof Notification !== "undefined",
        serviceWorkerSupported: "serviceWorker" in navigator,
      });
      return;
    }

    const canReviewRegistrations = ADMIN_ROLES.includes(user.role);
    const version = registrationVersion;
    let cancelled = false;
    let unsubscribe: () => void = () => {};
    let stage = "Firebase initialization";
    const isCancelled = () => cancelled || version !== registrationVersion;

    const initializePush = async () => {
      // A new sign-in must register after the previous browser token is revoked.
      await pushLogout?.catch(() => {});
      if (isCancelled()) return;
      logPushStep(stage);
      const messaging = await getBrowserMessaging();
      if (isCancelled()) return;
      if (!messaging) {
        logPushStep("Firebase messaging is unsupported in this browser");
        return;
      }

      stage = "Foreground listener subscription";
      const stopListening = await subscribeToMessages(messaging, (payload) => {
        if (isCancelled() || !canReviewRegistrations) return;
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
      if (isCancelled()) {
        stopListening();
        return;
      }
      unsubscribe = stopListening;

      stage = "Notification permission";
      logPushStep(stage, { permission: Notification.permission });
      let permission = Notification.permission;
      if (permission === "default") {
        permission = await Notification.requestPermission();
      }
      logPushStep("Permission result", { permission });
      if (isCancelled() || permission !== "granted") return;

      stage = "Service worker registration";
      logPushStep(stage);
      const registration = await navigator.serviceWorker.register(
        serviceWorkerUrl().toString(),
        { scope: "/" },
      );
      if (isCancelled()) return;
      stage = "Service worker activation / FCM token request";
      logPushStep(stage);
      const deviceToken = await getBrowserPushToken(messaging, registration);
      if (isCancelled()) return;
      if (!deviceToken.trim())
        throw new Error("Firebase returned no device token.");
      browserDeviceToken = deviceToken;
      logPushStep("FCM token received");
      stage = "Device token API registration";
      logPushStep(stage);
      await registerTokenOnce(user.userId, deviceToken);
      if (!isCancelled()) logPushStep("Device token registered successfully");
    };

    void initializePush().catch((failure: unknown) => {
      if (!isCancelled()) {
        const pushServiceError =
          failure instanceof Error &&
          failure.message.toLowerCase().includes("push service error");
        const firebaseCode =
          typeof failure === "object" &&
          failure !== null &&
          "code" in failure &&
          typeof failure.code === "string" &&
          /^messaging\/[a-z-]+$/.test(failure.code)
            ? failure.code
            : null;
        logPushStep("Setup failed", {
          stage,
          pushServiceError,
          firebaseCode,
          errorName: failure instanceof DOMException ? failure.name : "Error",
        });
        showToast({
          title: "Browser notifications unavailable",
          description:
            failure instanceof ApiRequestError
              ? getApiErrorMessage(
                  failure,
                  "We couldn't save this browser's notification token. Please try again.",
                )
              : pushServiceError
                ? "Notification permission was allowed, but the browser's push service could not register. Check your browser push settings and network connection, then reload."
                : "We couldn't set up browser notifications. Please reload and try again.",
          variant: "warning",
        });
      }
    });

    return () => {
      cancelled = true;
      unsubscribe();
    };
  }, [isAuthReady, isAuthenticated, navigate, showToast, user]);
}
