import { useEffect, useRef } from "react";
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
import {
  getVendorRegistrationReviewPath,
  getVendorRegistrationPushKey,
} from "../notification.utils";

const tokenRegistrations = new Map<string, Promise<void>>();
const seenMessages = new Set<string>();
let registrationVersion = 0;
let browserDeviceToken: string | null = null;
let pushLogout: Promise<void> | null = null;

export function logoutBrowserPushNotifications(): Promise<void> {
  const deviceToken = browserDeviceToken;
  browserDeviceToken = null;
  registrationVersion += 1;
  seenMessages.clear();
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
  const callbacks = useRef({ navigate, showToast });
  callbacks.current = { navigate, showToast };
  const userId = user?.userId;
  const role = user?.role;

  useEffect(() => {
    if (
      !isAuthReady ||
      !isAuthenticated ||
      !userId ||
      !role ||
      !STAFF_ROLES.includes(role)
    ) {
      return;
    }

    if (
      !isFirebasePushConfigured ||
      typeof Notification === "undefined" ||
      !("serviceWorker" in navigator)
    ) {
      return;
    }

    const canReviewRegistrations = ADMIN_ROLES.includes(role);
    const version = registrationVersion;
    let cancelled = false;
    let unsubscribe: () => void = () => {};
    const isCancelled = () => cancelled || version !== registrationVersion;
    const pendingMessages = new Map<string, string>();

    const showRegistrationToast = (reviewPath: string) => {
      callbacks.current.showToast({
        title: "New vendor registration request",
        description: "A vendor submitted an application for review.",
        actionLabel: "Review registration",
        onAction: () => {
          if (!isCancelled()) callbacks.current.navigate(reviewPath);
        },
        duration: 12_000,
        variant: "info",
      });
    };

    const receiveMessage = (payload: unknown) => {
      if (isCancelled() || !canReviewRegistrations) return;
      if (
        typeof payload !== "object" ||
        payload === null ||
        !("data" in payload)
      )
        return;
      const data = payload.data;
      if (
        typeof data !== "object" ||
        data === null ||
        !("type" in data) ||
        data.type !== "vendor_registration" ||
        !("registration_id" in data) ||
        typeof data.registration_id !== "string"
      )
        return;
      const reviewData = {
        type: data.type,
        registration_id: data.registration_id,
      };
      const messageId =
        "messageId" in payload && typeof payload.messageId === "string"
          ? payload.messageId
          : undefined;
      const reviewPath = getVendorRegistrationReviewPath(reviewData);
      const messageKey = getVendorRegistrationPushKey(reviewData, messageId);
      if (!reviewPath || !messageKey) return;
      const key = `${version}:${userId}:${messageKey}`;
      if (seenMessages.has(key)) return;
      seenMessages.add(key);
      if (seenMessages.size > 500) {
        const oldest = seenMessages.values().next().value;
        if (oldest) seenMessages.delete(oldest);
      }
      if (document.visibilityState !== "visible") {
        pendingMessages.set(key, reviewPath);
        if (pendingMessages.size > 500) {
          const oldest = pendingMessages.keys().next().value;
          if (oldest) pendingMessages.delete(oldest);
        }
        return;
      }
      showRegistrationToast(reviewPath);
    };

    const receiveWorkerMessage = (event: MessageEvent<unknown>) => {
      const source = event.source;
      if (
        !source ||
        !("scriptURL" in source) ||
        typeof source.scriptURL !== "string"
      )
        return;
      try {
        const url = new URL(source.scriptURL);
        if (
          url.origin !== window.location.origin ||
          url.pathname !== "/firebase-messaging-sw.js"
        )
          return;
      } catch {
        return;
      }
      const message = event.data;
      if (
        typeof message !== "object" ||
        message === null ||
        !("type" in message) ||
        message.type !== "vendor-registration-push" ||
        !("payload" in message)
      )
        return;
      receiveMessage(message.payload);
    };

    const showPendingMessages = () => {
      if (isCancelled() || document.visibilityState !== "visible") return;
      for (const reviewPath of pendingMessages.values())
        showRegistrationToast(reviewPath);
      pendingMessages.clear();
    };

    navigator.serviceWorker.addEventListener("message", receiveWorkerMessage);
    document.addEventListener("visibilitychange", showPendingMessages);

    const initializePush = async () => {
      // A new sign-in must register after the previous browser token is revoked.
      await pushLogout?.catch(() => {});
      if (isCancelled()) return;
      const messaging = await getBrowserMessaging();
      if (isCancelled()) return;
      if (!messaging) {
        return;
      }

      const stopListening = await subscribeToMessages(
        messaging,
        receiveMessage,
      );
      if (isCancelled()) {
        stopListening();
        return;
      }
      unsubscribe = stopListening;

      let permission = Notification.permission;
      if (permission === "default") {
        permission = await Notification.requestPermission();
      }
      if (isCancelled() || permission !== "granted") return;

      const registration = await navigator.serviceWorker.register(
        serviceWorkerUrl().toString(),
        { scope: "/" },
      );
      if (isCancelled()) return;
      const deviceToken = await getBrowserPushToken(messaging, registration);
      if (isCancelled()) return;
      if (!deviceToken.trim())
        throw new Error("Firebase returned no device token.");
      browserDeviceToken = deviceToken;
      await registerTokenOnce(userId, deviceToken);
    };

    void initializePush().catch((failure: unknown) => {
      if (!isCancelled()) {
        const pushServiceError =
          failure instanceof Error &&
          failure.message.toLowerCase().includes("push service error");
        callbacks.current.showToast({
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
      navigator.serviceWorker.removeEventListener(
        "message",
        receiveWorkerMessage,
      );
      document.removeEventListener("visibilitychange", showPendingMessages);
      pendingMessages.clear();
    };
  }, [isAuthReady, isAuthenticated, userId, role]);
}
