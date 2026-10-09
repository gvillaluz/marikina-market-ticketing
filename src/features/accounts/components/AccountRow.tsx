import type { AccountSummary } from "@/api/types/accounts.types";
import { ACCOUNT_ROLE_LABELS } from "../accounts.constants";
import { useAccountAvatar } from "../hooks/useAccountAvatar";
import styles from "./AccountRow.module.css";

export default function AccountRow({ account }: { account: AccountSummary }) {
  const avatar = useAccountAvatar(account.profileUrl);
  const name =
    [account.firstName, account.middleName, account.lastName]
      .filter(Boolean)
      .join(" ") || account.username;
  const initials =
    `${account.firstName?.charAt(0) ?? ""}${account.lastName?.charAt(0) ?? ""}` ||
    account.username.charAt(0);
  return (
    <tr className={styles.row}>
      <td>
        <div className={styles.identity}>
          <span className={styles.avatar}>
            {avatar.src ? (
              <img
                src={avatar.src}
                alt=""
                onError={avatar.onError}
                referrerPolicy="no-referrer"
              />
            ) : (
              initials
            )}
          </span>
          <div>
            <p className={styles.name}>{name}</p>
            <p className={styles.secondary}>{account.username}</p>
          </div>
        </div>
      </td>
      <td>
        <span className={styles.role}>
          {ACCOUNT_ROLE_LABELS[account.role] ?? account.role}
        </span>
      </td>
      <td>
        <p>{account.email || "No email provided"}</p>
        <p className={styles.secondary}>
          {account.phoneNumber || "No phone provided"}
        </p>
      </td>
      <td>
        <span
          className={`${styles.status} ${account.status === "Active" ? styles.active : styles.inactive}`}
        >
          {account.status}
        </span>
      </td>
      <td>
        <button
          className={styles.manage}
          type="button"
          disabled
          title="Account management is not available yet"
          aria-label={`Manage ${name}`}
        >
          Manage
        </button>
      </td>
    </tr>
  );
}
