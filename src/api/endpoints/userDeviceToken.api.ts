import client from "@/api/client";

export const userDeviceTokenApi = {
  async register(deviceToken: string): Promise<void> {
    await client.post(
      "/user/device-token",
      JSON.stringify({ deviceToken }),
      { headers: { "Content-Type": "application/json" } },
    );
  },
};
