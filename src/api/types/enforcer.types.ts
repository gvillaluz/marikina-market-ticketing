import { AccountStatus } from "./common.types";

export interface EnforcerSummary {
    enforcerId: number;
    username: string;
    firstName: string;
    lastName: string;
    profileUrl: string;
    status: AccountStatus;
    warningViolationCount: number;
    ticketViolationCount: number;
}

export interface TopIssuer {
    enforcerId: number;
    enforcerName: string;
    totalTickets: number;
}

export interface EnforcerActivityData {
    totalTicketCount: number;
    totalWarningCount: number;
    averageTicketPerDay: number;
    averageWarningPerDay: number;
    topEnforcers: TopIssuer[];
}