import {
  ADMIN_ROLES,
  USER_ROLES,
  type UserRole,
} from "@/api/types/common.types";
import { ROUTES } from "@/routes/routePaths";

export class UnsupportedUserRoleError extends Error {
  constructor() {
    super("The user profile did not include a supported role.");
    this.name = "UnsupportedUserRoleError";
  }
}

export function normalizeUserRole(value: unknown): UserRole {
  if (typeof value === "string") {
    const normalized = value
      .trim()
      .replace(/[\s_-]/g, "")
      .toLowerCase();
    const role = USER_ROLES.find((role) => role.toLowerCase() === normalized);
    if (role) return role;
  }
  throw new UnsupportedUserRoleError();
}

export function isAdministrator(role: UserRole | null | undefined): boolean {
  return Boolean(role && ADMIN_ROLES.includes(role));
}

export function roleHomePath(role: UserRole): string {
  return role === "MarketVendor" ? ROUTES.vendors : ROUTES.dashboard;
}
