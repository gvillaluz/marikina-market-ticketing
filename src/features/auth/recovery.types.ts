export type RecoveryChannel = "email" | "sms";

export interface RecoveryState {
  username?: string;
  maskedEmail?: string;
  maskedPhoneNumber?: string;
  channel?: RecoveryChannel;
  resetToken?: string;
  error?: string;
}

export interface RecoveryAccount {
  maskedEmail: string;
  maskedPhoneNumber: string;
}
