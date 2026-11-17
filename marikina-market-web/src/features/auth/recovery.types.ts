export type RecoveryChannel = "email";

export interface RecoveryState {
  username?: string;
  maskedEmail?: string;
  channel?: RecoveryChannel;
  resetToken?: string;
  error?: string;
}

export interface RecoveryAccount {
  maskedEmail: string;
}
