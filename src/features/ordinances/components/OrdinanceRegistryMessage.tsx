import styles from "./OrdinanceRegistryMessage.module.css";

interface Props {
  message: string;
  loading: boolean;
}

export default function OrdinanceRegistryMessage({ message, loading }: Props) {
  return (
    <tr>
      <td colSpan={6} className={styles.message}>
        <span role={loading ? "status" : undefined}>{message}</span>
      </td>
    </tr>
  );
}
