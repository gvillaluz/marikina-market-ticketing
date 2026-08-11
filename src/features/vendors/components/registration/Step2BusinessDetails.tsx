import { FC } from 'react';
import type { VendorRegistrationWizardInput } from '@/api/types/vendor.types';
import { TextInput, SelectInput } from './FormField';

interface Step2Props {
  form: VendorRegistrationWizardInput;
  errors: Record<string, string>;
  update: <K extends keyof VendorRegistrationWizardInput>(key: K, value: VendorRegistrationWizardInput[K]) => void;
}

const SECTION_OPTIONS = [
  'Dry Goods Section A',
  'Dry Goods Section B',
  'Wet Section A',
  'Wet Section B',
  'Meat & Poultry Section',
  'Produce Section',
  'Fish Section',
  'Other',
];

const Step2BusinessDetails: FC<Step2Props> = ({ form, errors, update }) => {
  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
      <TextInput
        label="Business Name"
        required
        value={form.businessName}
        onChange={(e) => update('businessName', e.target.value)}
        placeholder="Juan's Fresh Produce"
        error={errors.businessName}
      />
      <TextInput
        label="Nature of Business"
        required
        value={form.natureOfBusiness}
        onChange={(e) => update('natureOfBusiness', e.target.value)}
        placeholder="Fruits & Vegetables Retail"
        error={errors.natureOfBusiness}
      />
      <TextInput
        label="Stall Number"
        required
        value={form.stallNumber}
        onChange={(e) => update('stallNumber', e.target.value)}
        placeholder="A-123"
        error={errors.stallNumber}
      />
      <SelectInput
        label="Market Section"
        required
        options={SECTION_OPTIONS}
        placeholder="Select Market Section"
        value={form.section || ''}
        onChange={(e) => update('section', e.target.value)}
        error={errors.section}
      />
    </div>
  );
};

export default Step2BusinessDetails;
