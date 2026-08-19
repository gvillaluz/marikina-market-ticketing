import { useState } from 'react';
import { Download, Printer } from 'lucide-react';
import styles from './InspectionsPage.module.css';
import { InspectionFilters } from '../components/InspectionFilters';
import { InspectionTable } from '../components/InspectionTable';
import { PrintConfigModal } from '../components/PrintConfigModal';
import { WrittenWarningModal } from '../components/WrittenWarningModal';
import { TicketRecordModal } from '../components/TicketRecordModal';
import { Button } from '../../../components/ui/Button';
import { useDebounce } from '../../../hooks/useDebounce';
import { usePagination } from '../../../hooks/usePagination';
import { useInspections } from '../hooks/useInspections';
import type { InspectionType, MarketSection } from '../../../api/types/common.types';
import type { InspectionRecord } from '../../../api/types/ticket.types';

export function InspectionsPage() {
  const [search, setSearch] = useState('');
  const [type, setType] = useState<InspectionType>('all');
  const [section, setSection] = useState<'all' | MarketSection>('all');
  const [isPrintModalOpen, setIsPrintModalOpen] = useState(false);
  const [activeRecord, setActiveRecord] = useState<InspectionRecord | null>(null);

  const debouncedSearch = useDebounce(search, 400);
  const pagination = usePagination(1, 10);

  const { data, total, isLoading, isError } = useInspections(
    { search: debouncedSearch, type, section },
    pagination.page,
    pagination.pageSize
  );

  const { from, to } = pagination.getRange(total);
  const totalPages = pagination.totalPages(total);

  return (
    <div className={styles.page}>
      <div className={styles.pageIntro}>
        <h1 className={styles.title}>Inspection Records</h1>
        <p className={styles.subtitle}>Overview and administration of all conducted market inspections.</p>
      </div>

      <section className={styles.recordsContainer}>
        <InspectionFilters
          search={search}
          onSearchChange={(value) => {
            setSearch(value);
            pagination.setPage(1);
          }}
          type={type}
          onTypeChange={(value) => {
            setType(value);
            pagination.setPage(1);
          }}
          section={section}
          onSectionChange={(value) => {
            setSection(value as 'all' | MarketSection);
            pagination.setPage(1);
          }}
        />

        <InspectionTable
          rows={data}
          isLoading={isLoading}
          isError={isError}
          onView={setActiveRecord}
        />

        <div className={styles.footer}>
          <span className={styles.entries}>
            Showing {from} to {to} of {total} entries
          </span>

          <div className={styles.footerActions}>
            <Button
              className={styles.exportButton}
              variant="outline"
              icon={<Download size={14} strokeWidth={1.8} aria-hidden="true" />}
              onClick={() => setIsPrintModalOpen(true)}
            >
              Export
            </Button>
            <button
              className={styles.printButton}
              onClick={() => window.print()}
              aria-label="Print inspection records"
              title="Print inspection records"
            >
              <Printer size={15} strokeWidth={1.8} aria-hidden="true" />
            </button>
            <button
              className={styles.pageButton}
              disabled={pagination.page <= 1}
              onClick={() => pagination.goToPage(pagination.page - 1, totalPages)}
              aria-label="Previous page"
            >
              ‹
            </button>
            {Array.from({ length: Math.min(totalPages, 3) }, (_, index) => index + 1).map((page) => (
              <button
                key={page}
                className={`${styles.pageButton} ${pagination.page === page ? styles.currentPage : ''}`}
                onClick={() => pagination.goToPage(page, totalPages)}
                aria-label={`Go to page ${page}`}
              >
                {page}
              </button>
            ))}
            {totalPages > 3 && <span className={styles.ellipsis}>...</span>}
            <button
              className={styles.pageButton}
              disabled={pagination.page >= totalPages}
              onClick={() => pagination.goToPage(pagination.page + 1, totalPages)}
              aria-label="Next page"
            >
              ›
            </button>
          </div>
        </div>
      </section>

      <PrintConfigModal isOpen={isPrintModalOpen} onClose={() => setIsPrintModalOpen(false)} />

      <WrittenWarningModal
        isOpen={Boolean(activeRecord && activeRecord.type === 'warning')}
        recordId={activeRecord?.type === 'warning' ? activeRecord.id : null}
        onClose={() => setActiveRecord(null)}
      />

      <TicketRecordModal
        isOpen={Boolean(activeRecord && activeRecord.type === 'ticket')}
        recordId={activeRecord?.type === 'ticket' ? activeRecord.id : null}
        onClose={() => setActiveRecord(null)}
      />
    </div>
  );
}
