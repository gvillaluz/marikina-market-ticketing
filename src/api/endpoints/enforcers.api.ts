import { AccountStatus, PaginatedResponse } from "../types/common.types";
import apiClient from '../client';
import { EnforcerActivityData, EnforcerSummary } from "../types/enforcer.types";

export interface GetEnforcerParams {
    offset?: number;
    search?: string;
    status?: AccountStatus;
    sortBy?: string;
    sortDirection?: 'asc' | 'desc';
}

export const enforcersApi = {
    enforcerList(params: GetEnforcerParams): Promise<PaginatedResponse<EnforcerSummary>> {
        return apiClient.get('/admin/enforcers', { params }).then((response) => response.data as PaginatedResponse<EnforcerSummary>);
    },

    enforcersActivity(): Promise<EnforcerActivityData> {
        return apiClient.get('/admin/enforcers/activities').then((response) => response.data as EnforcerActivityData);
    }
}