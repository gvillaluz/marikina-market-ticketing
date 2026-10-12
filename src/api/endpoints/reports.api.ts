import client from "@/api/client";
import type {
  GenerateReportInput,
  ReportType,
  ReportHistoryItem,
} from "../types/reports.types";
import { ApiRequestError } from "@/utils/apiErrors";
import { validateReport, validateReportHistory } from "./reports.validation";

const path = "/admin/reports";
const types: readonly ReportType[] = ["Warning", "Ticket", "Warning & Ticket"];
export const reportsApi = {
  async generate(input: GenerateReportInput) {
    const { data } = await client.post<unknown>(path, input);
    return validateReport(data, true);
  },
  async detail(id: number, signal?: AbortSignal) {
    if (!Number.isSafeInteger(id) || id <= 0) throw new ApiRequestError();
    const { data } = await client.get<unknown>(`${path}/${id}`, { signal });
    return validateReport(data, true);
  },
  async preview(date: string, type: ReportType, signal?: AbortSignal) {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(date) || !types.includes(type))
      throw new ApiRequestError();
    const { data } = await client.get<unknown>(`${path}/preview`, {
      params: { date, type },
      signal,
    });
    return validateReport(data, false);
  },
  async list(offset = 0, signal?: AbortSignal) {
    if (!Number.isSafeInteger(offset) || offset < 0)
      throw new ApiRequestError();
    const { data } = await client.get<unknown>(path, {
      params: { offset },
      signal,
    });
    return validateReportHistory(data);
  },
  async listAll(signal?: AbortSignal): Promise<ReportHistoryItem[]> {
    const items: ReportHistoryItem[] = [];
    let offset = 0;
    while (true) {
      signal?.throwIfAborted();
      const page = await reportsApi.list(offset, signal);
      items.push(...page.items);
      if (!page.hasMore) return items;
      if (!page.items.length) throw new ApiRequestError();
      offset += 10;
    }
  },
};
