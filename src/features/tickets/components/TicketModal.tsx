import Modal from "@/components/ui/Modal";
import styles from './CreateTicketModal.module.css';
import logo from '../../../assets/icons/Marikina_City_Seal.svg (1).webp';

interface TicketModalProps {
    isOpen: boolean,
    ticketId: number | null,
    onClose: () => void
}

export function TicketModal({ isOpen, ticketId, onClose }: TicketModalProps) {
    
}