import styles from './InspectionFilters.module.css';
import { Search } from 'lucide-react';
import { Dropdown } from '../../../components/ui/Dropdown';
import { INSPECTION_TYPE_OPTIONS } from '../../../utils/constants';
import { MARKET_SECTION_LABELS } from '../../../api/types/common.types';
import type { MarketSection, InspectionType } from '../../../api/types/common.types';

interface InspectionFiltersProps {
  search: string;
  onSearchChange: (value: string) => void;
  type: InspectionType;
  onTypeChange: (value: InspectionType) => void;
  section: string;
  onSectionChange: (value: string) => void;
}

// MarketSection is a type, not a runtime value — Object.values(MarketSection) doesn't work.
// Build options from MARKET_SECTION_LABELS instead, since that's the actual object at runtime.
const SECTION_OPTIONS = [
  { value: 'all', label: 'All Sections' },
  ...(Object.keys(MARKET_SECTION_LABELS) as MarketSection[]).map((section) => ({
    value: section,
    label: MARKET_SECTION_LABELS[section],
  })),
];

export function InspectionFilters({
  search,
  onSearchChange,
  type,
  onTypeChange,
  section,
  onSectionChange,
}: InspectionFiltersProps) {
  return (
    <div className={styles.toolbar}>
      <div className={styles.searchWrapper}>
        <Search className={styles.searchIcon} size={14} strokeWidth={1.8} aria-hidden="true" />
        <input
          className={styles.searchInput}
          placeholder="Search by control number or vendor..."
          value={search}
          onChange={(e) => onSearchChange(e.target.value)}
          aria-label="Search inspection records"
        />
      </div>

      <div className={styles.filterGroup}>
        <Dropdown
          ariaLabel="Filter by Type"
          triggerLabel={INSPECTION_TYPE_OPTIONS.find((option) => option.value === type)?.label ?? 'All Records'}
          value={type}
          onChange={(value) => onTypeChange(value as InspectionType)}
          options={INSPECTION_TYPE_OPTIONS}
        />

        <Dropdown
          ariaLabel="Market Section"
          triggerLabel={SECTION_OPTIONS.find((option) => option.value === section)?.label ?? 'Market Section'}
          value={section}
          onChange={onSectionChange}
          options={SECTION_OPTIONS}
        />
      </div>
    </div>
  );
}