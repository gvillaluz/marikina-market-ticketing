import type { Ticket, CreateTicketInput, TicketHistoryEntry } from '@/api/types/ticket.types';
import type { Vendor, VendorRegistrationInput, VendorRegistrationWizardInput } from '@/api/types/vendor.types';
import type { Status, UserRole } from '@/api/types/common.types';
import {
  mockTickets,
  mockTicketHistory,
  mockVendors,
  mockPenalties,
  mockPenaltySummary,
  mockComplianceScores,
} from './mockData';

/**
 * In-memory mock adapter. Simulates network latency so the frontend
 * behaves like it is talking to the real ASP.NET backend via the API layer.
 * Each method returns a Promise and performs a shallow clone.
 */
const delay = (ms = 350) => new Promise<void>((resolve) => setTimeout(resolve, ms));

function clone<T>(value: T): T {
  return JSON.parse(JSON.stringify(value)) as T;
}

export const mockAdapter = {
  /* ----------------------------- AUTH ----------------------------- */
  async login(email: string, password: string) {
    await delay(500);
    const isAdmin = email === 'admin@marikina.gov.ph' && password === 'admin123';
    const isVendor = email === 'vendor@marikina.gov.ph' && password === 'vendor123';

    if (!isAdmin && !isVendor) {
      throw new Error('Invalid email or password.');
    }

    return {
      user: {
        id: isAdmin ? 'u-admin' : 'u-vendor',
        name: isAdmin ? 'Marikina Administrator' : 'Juan Dela Cruz',
        email,
        role: isAdmin ? 'admin' as const : 'vendor' as const,
        avatar: isAdmin ? 'MA' : 'JD',
      },
      token: `mock-token-${Date.now()}`,
    };
  },

  async register(input: { name: string; email: string; password: string; role: UserRole }) {
    await delay(500);
    return {
      user: { id: `u-${Date.now()}`, name: input.name, email: input.email, role: input.role, avatar: input.name.slice(0, 2).toUpperCase() },
      token: `mock-token-${Date.now()}`,
    };
  },

  /* ---------------------------- TICKETS ---------------------------- */
  async listTickets(params: { page?: number; pageSize?: number; search?: string; status?: Status; type?: string } = {}) {
    await delay();
    let items = clone(mockTickets);
    const { page = 1, pageSize = 10, search = '', status, type } = params;

    if (status) items = items.filter((t) => t.status === status);
    if (type) items = items.filter((t) => t.type === type);
    if (search) {
      const q = search.toLowerCase();
      items = items.filter(
        (t) =>
          t.ticketNumber.toLowerCase().includes(q) ||
          t.title.toLowerCase().includes(q) ||
          (t.vendorName ?? '').toLowerCase().includes(q),
      );
    }

    const total = items.length;
    const start = (page - 1) * pageSize;
    const paged = items.slice(start, start + pageSize);
    return {
      items: paged,
      total,
      page,
      pageSize,
      totalPages: Math.ceil(total / pageSize),
    };
  },

  async getTicket(id: string): Promise<Ticket> {
    await delay();
    const ticket = mockTickets.find((t) => t.id === id);
    if (!ticket) throw new Error('Ticket not found.');
    return clone(ticket);
  },

  async createTicket(input: CreateTicketInput): Promise<Ticket> {
    await delay();
    const vendor = mockVendors.find((v) => v.id === input.vendorId);
    const ticket: Ticket = {
      id: `t-${Date.now()}`,
      ticketNumber: `MKT-${new Date().getFullYear()}-${String(mockTickets.length + 1).padStart(4, '0')}`,
      type: input.type,
      title: input.title,
      description: input.description,
      status: 'pending',
      severity: input.severity,
      vendorId: input.vendorId,
      vendorName: vendor?.businessName,
      createdBy: 'admin@marikina.gov.ph',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      dueDate: input.dueDate,
      location: input.location,
    };
    mockTickets.unshift(ticket);
    return clone(ticket);
  },

  async updateTicketStatus(id: string, status: Status): Promise<Ticket> {
    await delay();
    const ticket = mockTickets.find((t) => t.id === id);
    if (!ticket) throw new Error('Ticket not found.');
    ticket.status = status;
    ticket.updatedAt = new Date().toISOString();
    return clone(ticket);
  },

  async getTicketHistory(id: string): Promise<TicketHistoryEntry[]> {
    await delay(200);
    const history = mockTicketHistory.filter((h) => h.ticketId === id);
    if (history.length === 0) {
      return [
        { id: 'h-0', ticketId: id, action: 'created', note: 'Ticket filed', performedBy: 'system', timestamp: new Date().toISOString() },
      ];
    }
    return clone(history);
  },

  /* ---------------------------- VENDORS ---------------------------- */
  async listVendors(params: { page?: number; pageSize?: number; search?: string; status?: Status } = {}) {
    await delay();
    let items = clone(mockVendors);
    const { page = 1, pageSize = 10, search = '', status } = params;

    if (status) items = items.filter((v) => v.status === status);
    if (search) {
      const q = search.toLowerCase();
      items = items.filter(
        (v) =>
          v.businessName.toLowerCase().includes(q) ||
          v.name.toLowerCase().includes(q) ||
          v.barangay.toLowerCase().includes(q),
      );
    }

    const total = items.length;
    const start = (page - 1) * pageSize;
    const paged = items.slice(start, start + pageSize);
    return {
      items: paged,
      total,
      page,
      pageSize,
      totalPages: Math.ceil(total / pageSize),
    };
  },

  async getVendor(id: string): Promise<Vendor> {
    await delay();
    const vendor = mockVendors.find((v) => v.id === id);
    if (!vendor) throw new Error('Vendor not found.');
    return clone(vendor);
  },

  async registerVendor(input: VendorRegistrationInput): Promise<Vendor> {
    await delay();
    const vendor: Vendor = {
      id: `v-${Date.now()}`,
      name: input.contactPerson,
      businessName: input.businessName,
      category: input.category,
      address: input.address,
      barangay: input.barangay,
      contactPerson: input.contactPerson,
      email: input.email,
      phone: input.phone,
      status: 'pending',
      registrationDate: new Date().toISOString(),
      expiryDate: '',
      complianceScore: 0,
      qrCode: `VND-${Math.floor(Math.random() * 900 + 100)}`,
    };
    mockVendors.unshift(vendor);
    return clone(vendor);
  },

async registerVendorWizard(input: VendorRegistrationWizardInput): Promise<Vendor> {
    await delay();
    const vendor: Vendor = {
      id: `v-${Date.now()}`,
      name: `${input.firstName} ${input.lastName}`,
      businessName: input.businessName,
      category: 'food',
      address: `${input.houseNo} ${input.street}, ${input.barangay}, ${input.city}`,
      barangay: input.barangay,
      contactPerson: `${input.firstName} ${input.lastName}`,
      email: input.email,
      phone: input.mobileNumber,
      status: 'pending',
      registrationDate: new Date().toISOString(),
      expiryDate: '',
      complianceScore: 0,
      qrCode: `VND-${Math.floor(Math.random() * 900 + 100)}`,
    };
    mockVendors.unshift(vendor);
    return clone(vendor);
  },

  async updateVendorStatus(id: string, status: Status): Promise<Vendor> {
    await delay();
    const vendor = mockVendors.find((v) => v.id === id);
    if (!vendor) throw new Error('Vendor not found.');
    vendor.status = status;
    return clone(vendor);
  },

  /* ---------------------------- PENALTIES ---------------------------- */
  async listPenalties(params: { page?: number; pageSize?: number; status?: string } = {}) {
    await delay();
    let items = clone(mockPenalties);
    const { page = 1, pageSize = 10, status } = params;
    if (status) items = items.filter((p) => p.status === status);
    const total = items.length;
    const start = (page - 1) * pageSize;
    return {
      items: items.slice(start, start + pageSize),
      total,
      page,
      pageSize,
      totalPages: Math.ceil(total / pageSize),
    };
  },

  async getPenaltySummary() {
    await delay(200);
    return clone(mockPenaltySummary);
  },

  async markPenaltyPaid(id: string) {
    await delay(200);
    const penalty = mockPenalties.find((p) => p.id === id);
    if (!penalty) throw new Error('Penalty not found.');
    penalty.status = 'paid';
    penalty.paidAt = new Date().toISOString();
    return clone(penalty);
  },

  /* --------------------------- COMPLIANCE --------------------------- */
  async getCompliance(vendorId: string) {
    await delay();
    const score = mockComplianceScores.find((c) => c.vendorId === vendorId) ?? mockComplianceScores[0];
    if (!score) throw new Error('No compliance record found.');
    return clone(score);
  },
};

export default mockAdapter;
