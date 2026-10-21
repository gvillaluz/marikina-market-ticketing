import client from "@/api/client";
import type { Vendor, VendorRegistrationForm } from "@/api/types/vendor.types";
import type {
  ApiResponse,
  PaginatedResponse,
  PaginationParams,
} from "@/api/types/common.types";
import type { Status } from "@/api/types/common.types";
import { compressImageFile } from "@/utils/compressImageFile";

export const vendorApi = {
  async list(
    params: PaginationParams & { status?: Status } = {},
  ): Promise<PaginatedResponse<Vendor>> {
    const { data } = await client.get<ApiResponse<PaginatedResponse<Vendor>>>(
      "/vendors",
      { params },
    );
    return data.data;
  },

  async getById(id: string): Promise<Vendor> {
    const { data } = await client.get<ApiResponse<Vendor>>(`/vendor/${id}`);
    return data.data;
  },

  async getMyProfile(): Promise<Vendor> {
    const { data } = await client.get<ApiResponse<Vendor>>("/vendor/me");
    return data.data;
  },

  async register(input: VendorRegistrationForm): Promise<void> {
    if (!input.governmentIdPhoto || !input.businessDocumentPhoto) {
      throw new Error("Both required registration documents must be selected.");
    }

    const [governmentIdPhoto, businessDocumentPhoto] = await Promise.all([
      compressImageFile(input.governmentIdPhoto),
      compressImageFile(input.businessDocumentPhoto),
    ]);
    const formData = new FormData();
    formData.append("FirstName", input.firstName.trim());
    formData.append("MiddleName", input.middleName.trim());
    formData.append("LastName", input.lastName.trim());
    formData.append("DateOfBirth", input.dateOfBirth);
    formData.append("PhoneNumber", input.phoneNumber.trim());
    formData.append("HouseNumber", input.houseNumber.trim());
    formData.append("Street", input.street.trim());
    formData.append("Barangay", input.barangay.trim());
    formData.append("City", input.city.trim());
    formData.append("BusinessId", input.businessId.trim());
    formData.append("BusinessName", input.businessName.trim());
    formData.append("NatureOfBusiness", input.natureOfBusiness.trim());
    formData.append("VendorType", input.vendorType);
    formData.append("StallNumber", input.stallNumber.trim());
    formData.append("MarketSectionId", input.marketSectionId);
    formData.append("GovernmentIdType", input.governmentIdType);
    formData.append("government_id_photo", governmentIdPhoto);
    formData.append("business_document_photo", businessDocumentPhoto);
    formData.append("Email", input.email.trim());
    formData.append("Password", input.password);
    formData.append("ConfirmPassword", input.confirmPassword);

    await client.post("/vendor/register", formData, {
      headers: { "Content-Type": "multipart/form-data" },
    });
  },

  async approve(id: string): Promise<Vendor> {
    const { data } = await client.patch<ApiResponse<Vendor>>(
      `/vendor/${id}/approve`,
    );
    return data.data;
  },

  async reject(id: string, reason?: string): Promise<Vendor> {
    const { data } = await client.patch<ApiResponse<Vendor>>(
      `/vendor/${id}/reject`,
      { reason },
    );
    return data.data;
  },

  async suspend(id: string): Promise<Vendor> {
    const { data } = await client.patch<ApiResponse<Vendor>>(
      `/vendor/${id}/suspend`,
    );
    return data.data;
  },
};
