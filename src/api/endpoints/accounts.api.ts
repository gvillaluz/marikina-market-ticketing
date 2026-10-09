import client from "@/api/client";
import type {
  AccountCounts,
  AccountFilters,
  AccountPageResponse,
  CreateStaffAccountRequest,
  CreatedStaffAccount,
} from "@/api/types/accounts.types";

export const accountsApi = {
  async createStaff(
    request: CreateStaffAccountRequest,
  ): Promise<CreatedStaffAccount> {
    const { data } = await client.post<CreatedStaffAccount>(
      "/admin/users",
      request,
    );
    return data;
  },
  async getCounts(signal?: AbortSignal): Promise<AccountCounts> {
    const { data } = await client.get<AccountCounts>("/admin/accounts/counts", {
      signal,
    });
    return data;
  },
  async list(
    filters: AccountFilters,
    signal?: AbortSignal,
  ): Promise<AccountPageResponse> {
    const { data } = await client.get<AccountPageResponse>("/admin/accounts", {
      params: filters,
      signal,
    });
    return data;
  },
};
