import {
  type MessagePayload,
  type Messaging,
} from "firebase/messaging";
import env, { isFirebasePushConfigured } from "@/config/env";

export type { MessagePayload };

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
