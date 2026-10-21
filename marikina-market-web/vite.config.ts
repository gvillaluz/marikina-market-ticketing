import { defineConfig, loadEnv } from "vite";
import react from "@vitejs/plugin-react";
import path from "path";

export default defineConfig(({ mode }) => {
  const localEnv = loadEnv(mode, process.cwd(), "");
  return {
    plugins: [react()],
    resolve: {
      alias: {
        "@": path.resolve(__dirname, "./src"),
      },
    },
    server: {
      port: 5173,
      open: false,
      proxy: {
        "/api": {
          target: localEnv.API_PROXY_TARGET || "http://127.0.0.1:5000",
          changeOrigin: true,
          secure: false,
        },
      },
    },
  };
});
origin;
