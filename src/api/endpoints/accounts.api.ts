import client from "@/api/client";
import type {
  AccountCounts,
  AccountFilters,
  AccountPageResponse,
  CreateStaffAccountRequest,
  CreatedStaffAccount,
  AccountDetails,
  UpdateAccountRequest,
} from "@/api/types/accounts.types";
import { ApiRequestError } from "@/utils/apiErrors";
import { USER_ROLE_LABELS } from "@/api/types/common.types";

function accountDetails(data: AccountDetails, id: number): AccountDetails {
  if (
    !data ||
    data.id !== id ||
    !Number.isSafeInteger(data.version) ||
    data.version < 1 ||
    data.version > 4294967295 ||
    (data.role !== null && !(data.role in USER_ROLE_LABELS)) ||
    ![
      data.username,
      data.firstName,
      data.lastName,
      data.dateOfBirth,
      data.email,
      data.phoneNumber,
      data.houseNumber,
      data.street,
      data.barangay,
      data.city,
    ].every((value) => typeof value === "string") ||
    (data.middleName !== null && typeof data.middleName !== "string") ||
    !["Active", "Inactive"].includes(data.status)
  ) {
    throw new ApiRequestError(
      "Account details were incomplete. Reload the account before saving.",
    );
  }
  return data;
}

export const accountsApi = {
  async getAccount(id: number): Promise<AccountDetails> {
    const { data } = await client.get<AccountDetails>(`/admin/users/${id}`);
    return accountDetails(data, id);
  },
  async updateAccount(
    id: number,
    request: UpdateAccountRequest,
  ): Promise<AccountDetails> {
    const { data } = await client.put<AccountDetails>(
      `/admin/users/${id}`,
      request,
    );
    return accountDetails(data, id);
  },
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
