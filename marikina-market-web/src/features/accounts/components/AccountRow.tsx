import type { AccountSummary } from "@/api/types/accounts.types";
import { ACCOUNT_ROLE_LABELS } from "../accounts.constants";
import { useAccountAvatar } from "../hooks/useAccountAvatar";
import styles from "./AccountRow.module.css";
import UrlImage from "@/components/ui/UrlImage";
import SearchHighlight from "@/components/ui/SearchHighlight";

export default function AccountRow({
  account,
  search,
  onManage,
}: {
  account: AccountSummary;
  search: string;
  onManage: (id: number) => void;
}) {
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
            <UrlImage
              src={avatar.src}
              alt=""
              fallback={initials}
              onError={avatar.onError}
              referrerPolicy="no-referrer"
            />
          </span>
          <div>
            <p className={styles.name}>
              <SearchHighlight text={name} search={search} />
            </p>
            <p className={styles.secondary}>
              <SearchHighlight text={account.username} search={search} />
            </p>
          </div>
        </div>
      </td>
      <td>
        <span className={styles.role}>
          {ACCOUNT_ROLE_LABELS[account.role] ?? account.role}
        </span>
      </td>
      <td>
        <p>
          {account.email ? (
            <SearchHighlight text={account.email} search={search} />
          ) : (
            "No email provided"
          )}
        </p>
        <p className={styles.secondary}>
          {account.phoneNumber ? (
            <SearchHighlight text={account.phoneNumber} search={search} />
          ) : (
            "No phone provided"
          )}
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
          onClick={() => onManage(account.id)}
          aria-label={`Manage ${name}`}
        >
          Manage
        </button>
      </td>
    </tr>
  );
}
