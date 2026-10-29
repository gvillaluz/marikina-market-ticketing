import client from "@/api/client";
import type { PersonPage, PersonRecord, SavePersonRequest } from "@/api/types/person.types";

export const personsApi = {
  async list(search: string, offset: number): Promise<PersonPage> {
    const { data } = await client.get<PersonPage>("/persons", { params: { search, offset } });
    return data;
  },
  async get(id: number): Promise<PersonRecord> {
    const { data } = await client.get<PersonRecord>(`/persons/${id}`);
    return data;
  },
  async save(id: number | null, request: SavePersonRequest): Promise<PersonRecord> {
    const payload = {
      fullName: request.fullName.trim(), address: request.address.trim(),
      phoneNumber: request.phoneNumber?.trim() || null,
    };
    const { data } = id === null
      ? await client.post<PersonRecord>("/admin/persons", payload)
      : await client.put<PersonRecord>(`/admin/persons/${id}`, payload);
    return data;
  },
};
