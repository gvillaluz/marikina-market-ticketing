import { CheckCircle2 } from "lucide-react";
import type { AccountSummary } from "@/api/types/accounts.types";
import type { UserRole } from "@/api/types/common.types";
import { USER_ROLE_LABELS } from "@/api/types/common.types";
import UrlImage from "@/components/ui/UrlImage";
import { useAccountAvatar } from "../hooks/useAccountAvatar";
import styles from "./CurrentAccountCard.module.css";

type CurrentAccount = Omit<AccountSummary, "id" | "role"> & {
  role: UserRole | null;
};

export default function CurrentAccountCard({ user }: { user: CurrentAccount }) {
  const avatar = useAccountAvatar(user.profileUrl);
  const name =
    [user.firstName, user.middleName, user.lastName]
      .filter(Boolean)
      .join(" ") || user.username;
  const initials =
    `${user.firstName.charAt(0)}${user.lastName.charAt(0)}` ||
    user.username.charAt(0);
  return (
    <section className={styles.account} aria-labelledby="current-account-title">
      <div className={styles.heading}>
        <h2 id="current-account-title">Your account</h2>
        <span className={styles.signedIn}>
          <CheckCircle2 size={16} aria-hidden="true" />
          Signed in
        </span>
      </div>
      <div className={styles.content}>
        <div className={styles.identity}>
          <span className={styles.avatar}>
            <UrlImage
              src={avatar.src}
              alt=""
              fallback={initials}
              onError={avatar.onError}
              referrerPolicy="no-referrer"
            />
          </span>
          <div className={styles.name}>
            <h3>{name}</h3>
            <p>{user.username}</p>
          </div>
        </div>
        <dl className={styles.details}>
          <div>
            <dt>Role</dt>
            <dd>{user.role ? USER_ROLE_LABELS[user.role] : "Not assigned"}</dd>
          </div>
          <div>
            <dt>Status</dt>
            <dd
              className={
                user.status === "Active" ? styles.active : styles.inactive
              }
            >
              {user.status}
            </dd>
          </div>
        </dl>
      </div>
    </section>
  );
}
