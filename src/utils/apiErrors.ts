import axios from "axios";

const DEFAULT_API_ERROR = "The request could not be completed. Please try again.";

export class ApiRequestError extends Error {
  readonly serverMessage?: string;

  constructor(serverMessage?: string) {
    super(serverMessage || DEFAULT_API_ERROR);
    this.name = "ApiRequestError";
    this.serverMessage = serverMessage;
  }
}

function firstMessage(value: unknown): string | undefined {
  if (typeof value === "string") {
    const message = value.trim();
    if (!message || message.startsWith("<")) return undefined;
    return message;
  }

  if (Array.isArray(value)) {
    for (const item of value) {
      const message = firstMessage(item);
      if (message) return message;
    }
    return undefined;
  }

  if (typeof value !== "object" || value === null) return undefined;

  const response = value as Record<string, unknown>;
  for (const key of ["message", "errorMessage", "detail", "errors", "error", "title"]) {
    const message = firstMessage(response[key]);
    if (message) return message;
  }

  for (const value of Object.values(response)) {
    const message = firstMessage(value);
    if (message) return message;
  }

  return undefined;
}

export function getApiResponseMessage(response: unknown): string | undefined {
  return firstMessage(response);
}

export function getApiErrorMessage(
  error: unknown,
  fallback: string,
): string {
  if (error instanceof ApiRequestError) {
    return error.serverMessage || fallback;
  }

  if (axios.isAxiosError(error)) {
    return getApiResponseMessage(error.response?.data) || fallback;
  }

  if (error instanceof Error && error.message.trim()) {
    return error.message;
  }

  return fallback;
}
