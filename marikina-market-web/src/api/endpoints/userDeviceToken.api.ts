import client from "@/api/client";

export const userDeviceTokenApi = {
  async register(deviceToken: string): Promise<void> {
    await client.post(
      "/user/device-token",
      { device_token: deviceToken },
      {
        headers: { "Content-Type": "application/json" },
        validateStatus: (status) => {
          if (import.meta.env.DEV) {
            console.info("[Web push] Device token endpoint response", {
              status,
            });
          }
          return status >= 200 && status < 300;
        },
      },
    );
  },
};
