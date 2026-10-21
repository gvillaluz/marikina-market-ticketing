import { FC } from "react";
import styles from "./TicketDetailFooter.module.css";
import { SquareCheck } from "lucide-react";
import Button from "@/components/ui/Button/Button";

interface TicketDetailFooterProps {
  onViewFullRecord: () => void;
  onChangeStatus: () => void;
  statusOptionsOpen: boolean;
}

const TicketDetailFooter: FC<TicketDetailFooterProps> = ({
  onViewFullRecord,
  onChangeStatus,
  statusOptionsOpen,
}) => {
  return (
    <div className={styles.footer}>
      <button
        type="button"
        className={styles.linkBtn}
        onClick={onViewFullRecord}
      >
        View Full Ticket Record
      </button>
      <Button
        type="button"
        variant="primary"
        icon={<SquareCheck size={18} aria-hidden="true" />}
        onClick={onChangeStatus}
        aria-expanded={statusOptionsOpen}
        aria-controls="ticket-status-options"
      >
        Change Status
      </Button>
    </div>
  );
};

export default TicketDetailFooter;
