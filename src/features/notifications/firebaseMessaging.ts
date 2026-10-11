import { type MessagePayload, type Messaging } from "firebase/messaging";
import env, { isFirebasePushConfigured } from "@/config/env";

export type { MessagePayload };

async function waitForWorkerActivation(
  registration: ServiceWorkerRegistration,
): Promise<void> {
  if (registration.active?.state === "activated") return;

  const worker =
    registration.installing || registration.waiting || registration.active;
  if (!worker) throw new Error("No notification service worker is available.");

  await new Promise<void>((resolve, reject) => {
    const cleanup = () => {
      clearTimeout(timeout);
      worker.removeEventListener("statechange", checkState);
    };
    const checkState = () => {
      if (worker.state === "activated") {
        cleanup();
        resolve();
      } else if (worker.state === "redundant") {
        cleanup();
        reject(
          new Error("The notification service worker failed to activate."),
        );
      }
    };
    const timeout = setTimeout(() => {
      cleanup();
      reject(
        new Error("The notification service worker activation timed out."),
      );
    }, 10_000);
    worker.addEventListener("statechange", checkState);
    checkState();
  });
}

export async function getBrowserMessaging() {
  if (!isFirebasePushConfigured) return null;
  const [appSdk, messagingSdk] = await Promise.all([
    import("firebase/app"),
    import("firebase/messaging"),
  ]);
  if (!(await messagingSdk.isSupported())) return null;
  const firebaseConfig = {
    apiKey: env.firebase.apiKey,
    authDomain: env.firebase.authDomain,
    projectId: env.firebase.projectId,
    messagingSenderId: env.firebase.messagingSenderId,
    appId: env.firebase.appId,
  };
  const app =
    appSdk.getApps().length > 0
      ? appSdk.getApp()
      : appSdk.initializeApp(firebaseConfig);
  return messagingSdk.getMessaging(app);
}

export async function getBrowserPushToken(
  messaging: Messaging,
  serviceWorkerRegistration: ServiceWorkerRegistration,
): Promise<string> {
  if (import.meta.env.DEV) {
    console.info("[Web push] Waiting for service worker activation", {
      active: serviceWorkerRegistration.active?.state ?? null,
      installing: serviceWorkerRegistration.installing?.state ?? null,
      waiting: serviceWorkerRegistration.waiting?.state ?? null,
    });
  }
  await waitForWorkerActivation(serviceWorkerRegistration);
  if (import.meta.env.DEV) {
    console.info("[Web push] Service worker active; requesting FCM token");
  }
  const { getToken } = await import("firebase/messaging");
  return getToken(messaging, {
    vapidKey: env.firebase.vapidKey,
    serviceWorkerRegistration,
  });
}

export async function subscribeToMessages(
  messaging: Messaging,
  callback: (payload: MessagePayload) => void,
): Promise<() => void> {
  const { onMessage } = await import("firebase/messaging");
  return onMessage(messaging, callback);
}
