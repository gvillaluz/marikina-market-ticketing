const firebaseConfig = new URL(self.location.href).searchParams;

self.addEventListener("notificationclick", (event) => {
  const notificationData = event.notification.data || {};
  const messageData = notificationData.FCM_MSG?.data || notificationData;
  const registrationId = messageData.registration_id;
  event.notification.close();

  if (
    messageData.type !== "vendor_registration" ||
    typeof registrationId !== "string" ||
    !/^\d{1,12}$/.test(registrationId)
  ) {
    return;
  }

  const destination = new URL(
    `/admin/vendor-registrations/review/${registrationId}`,
    self.location.origin,
  ).href;

  event.waitUntil(
    self.clients
      .matchAll({ type: "window", includeUncontrolled: true })
      .then(async (clients) => {
        for (const client of clients) {
          if (new URL(client.url).origin !== self.location.origin) continue;
          await client.navigate(destination);
          return client.focus();
        }
        return self.clients.openWindow(destination);
      }),
  );
});

importScripts(
  "https://www.gstatic.com/firebasejs/12.12.1/firebase-app-compat.js",
  "https://www.gstatic.com/firebasejs/12.12.1/firebase-messaging-compat.js",
);

const requiredConfig = [
  "apiKey",
  "authDomain",
  "projectId",
  "messagingSenderId",
  "appId",
];

const config = Object.fromEntries(
  requiredConfig.map((key) => [key, firebaseConfig.get(key)]),
);

if (requiredConfig.every((key) => config[key])) {
  firebase.initializeApp(config);
  firebase.messaging().onBackgroundMessage(async (payload) => {
    const data = payload.data || {};
    if (
      data.type !== "vendor_registration" ||
      typeof data.registration_id !== "string" ||
      !/^\d{1,12}$/.test(data.registration_id)
    ) {
      return;
    }

    const handoff = self.clients
      .matchAll({ type: "window", includeUncontrolled: true })
      .then((clients) => {
        for (const client of clients) {
          if (new URL(client.url).origin !== self.location.origin) continue;
          client.postMessage({
            type: "vendor-registration-push",
            payload: {
              data: {
                type: data.type,
                registration_id: data.registration_id,
              },
              messageId: payload.messageId,
            },
          });
        }
      });
    // Firebase already displays notification payloads in the background.
    const notification = payload.notification
      ? Promise.resolve()
      : self.registration.showNotification("New vendor registration request", {
          body: "A vendor submitted an application for review.",
          data,
        });
    await Promise.all([handoff, notification]);
  });
}
