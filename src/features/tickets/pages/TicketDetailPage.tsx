import { FC, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import Loader from '@/components/feedback/Loader/Loader';
import Card from '@/components/ui/Card';
import Button from '@/components/ui/Button';
import StatusBadge from '@/components/ui/StatusBadge';
import useTicketHistory from '@/features/tickets/hooks/useTicketHistory';
import TicketExportModal from '@/features/tickets/components/TicketExportModal';
import { formatCurrency, formatDate, formatDateTime } from '@/utils/formatters';
import styles from './TicketDetailPage.module.css';

const STATUS_OPTIONS = [['PENDING', 'Payment or review is still pending.'], ['PAID', 'Settlement has been verified.'], ['CONTESTED', 'Vendor has appealed the ticket.'], ['WAIVED', 'The penalty has been waived.'], ['CLEARED', 'The ticket has been cleared.']] as const;

const TicketDetailPage: FC = () => {
  const { id = '' } = useParams<{ id: string }>(); const navigate = useNavigate();
  const { ticket, history, isLoading, error, updateStatus } = useTicketHistory(id);
  const [selected, setSelected] = useState(''); const [confirm, setConfirm] = useState(false); const [exportOpen, setExportOpen] = useState(false); const [saving, setSaving] = useState(false);
  if (isLoading) return <Loader fullPage label="Loading ticket..." />;
  if (error || !ticket) return <div className={styles.errorState}><h2>Ticket not found</h2><p>{error instanceof Error ? error.message : 'No ticket data was returned.'}</p><Button onClick={() => navigate('/tickets')}>Back to Tickets</Button></div>;
  const evidence = ticket.photoEvidenceUrls ?? (ticket.photoEvidenceUrl ? [ticket.photoEvidenceUrl] : []); const settlement = ticket.settlementEvidenceUrls ?? []; const status = selected || ticket.status;
  const confirmUpdate = async () => { setSaving(true); try { await updateStatus(status); setConfirm(false); } finally { setSaving(false); } };
  return <div>
    <Link to="/tickets" className={styles.back}>Back to Tickets</Link>
    <header className={styles.header}><div><div className={styles.headerTop}><h1 className={styles.title}>Ticket #{ticket.controlNumber}</h1><StatusBadge status={ticket.status} /></div><p className={styles.subtitle}>Last updated {formatDateTime(ticket.dateTime)}</p></div></header>
    <div className={styles.detailCards}><Card className={styles.infoCard}><h3>Enforcer & Vendor Details</h3><Detail label="Enforcer / Inspector" value={ticket.enforcerName ?? ticket.enforcer ?? ticket.issuedByName} /><Detail label="Vendor Name" value={ticket.tradeName} /><Detail label="Stall Location" value={`${ticket.stallNo} · ${ticket.location}`} /></Card><Card className={styles.infoCard}><h3>Ticket Parameters</h3><Detail label="Date Issued" value={formatDateTime(ticket.dateTime)} /><Detail label="Severity Level" value={ticket.penalty.severity} /><Detail label="Control Type" value={ticket.controlType ?? ticket.type} /></Card><Card className={styles.infoCard}><h3>Penalty & Settlement Status</h3><Detail label="Penalty Type" value={ticket.penalty.penaltyType} /><Detail label="Total Penalty Due" value={formatCurrency(ticket.penalty.totalFineDue)} highlight /><Detail label="Due Date" value={formatDate(ticket.penalty.dueDate)} /><p className={styles.infoBanner}>Settle this amount at the City Treasurer's Office.</p></Card></div>
    <Card className={styles.contentCard}><h3>Violation & Inspection Notes</h3><Detail label="Violation Type / Ordinance" value={ticket.violationCommitted} /><p className={styles.description}>{ticket.description}</p><Evidence title="Photographic Evidence" urls={evidence} /></Card>
    <Card className={styles.contentCard}><h3>Vendor Settlement Verification</h3><Evidence title="Submitted proof of settlement" urls={settlement} empty="No additional settlement media" /></Card>
    <Card className={styles.contentCard} id="status"><h3>Update Ticket Status</h3><div className={styles.statusOptions}>{STATUS_OPTIONS.map(([option, description]) => <button key={option} className={`${styles.statusOption} ${status === option ? styles.selected : ''}`} onClick={() => setSelected(option)}><strong>{option}</strong><span>{description}</span></button>)}</div><div className={styles.detailFooter}><Button variant="outline" onClick={() => setExportOpen(true)}>View Full Ticket Record</Button><Button disabled={status === ticket.status} loading={saving} onClick={() => setConfirm(true)}>Save Changes</Button></div></Card>
    <Card className={styles.historyCard}><h3>Status Audit Log</h3>{history.length ? history.map((entry) => <p key={entry.id}><strong>{entry.action}</strong> · {entry.performedBy} · {formatDateTime(entry.timestamp)}</p>) : <p>No audit entries returned.</p>}</Card>
    {confirm && <div className={styles.confirmOverlay}><div className={styles.confirm}><h2>Confirm Status Update</h2><p>Are you sure you want to update the status for Ticket #{ticket.controlNumber}? This action will be recorded in the audit log.</p><div className={styles.detailFooter}><Button variant="outline" onClick={() => setConfirm(false)}>Cancel</Button><Button loading={saving} onClick={confirmUpdate}>Confirm Update</Button></div></div></div>}
    <TicketExportModal ticket={ticket} open={exportOpen} onClose={() => setExportOpen(false)} />
  </div>;
};
const Detail: FC<{ label: string; value: string; highlight?: boolean }> = ({ label, value, highlight }) => <div className={styles.detail}><span className={styles.detailLabel}>{label}</span><strong className={highlight ? styles.highlight : ''}>{value}</strong></div>;
const Evidence: FC<{ title: string; urls: string[]; empty?: string }> = ({ title, urls, empty = 'No additional media' }) => <div className={styles.evidence}><span className={styles.detailLabel}>{title}</span>{urls.length ? <div className={styles.thumbs}>{urls.map((url) => <img key={url} src={url} alt="Ticket evidence" />)}</div> : <p>{empty}</p>}</div>;
export default TicketDetailPage;