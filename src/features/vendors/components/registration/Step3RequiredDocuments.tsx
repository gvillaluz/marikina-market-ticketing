import { FC } from 'react';
import type { VendorRegistrationWizardInput } from '@/api/types/vendor.types';
import { TextInput, SelectInput, FileUpload } from './FormField';

interface Step3Props {
  form: VendorRegistrationWizardInput;
  errors: Record<string, string>;
  update: <K extends keyof VendorRegistrationWizardInput>(key: K, value: VendorRegistrationWizardInput[K]) => void;
}

const ID_TYPES = [
  'Passport',
  'Driver\'s License',
  'UMID',
  'PhilHealth ID',
  'SSS ID',
  'PRC ID',
  'Postal ID',
  'Voter\'s ID',
];

const Step3RequiredDocuments: FC<Step3Props> = ({ form, errors, update }) => {
  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
      <SelectInput
        label="Government ID Type"
        required
        options={ID_TYPES}
        placeholder="Select ID Type"
        value={form.govIdType || ''}
        onChange={(e) => update('govIdType', e.target.value)}
        error={errors.govIdType}
      />
      <TextInput
        label="Government ID Number"
        required
        value={form.govIdNumber}
        onChange={(e) => update('govIdNumber', e.target.value)}
        placeholder="1234-5678-9012"
        error={errors.govIdNumber}
      />
      <FileUpload
        label="Upload ID Photo"
        required
        fileName={form.govIdPhoto}
        onChange={(file) => update('govIdPhoto', file)}
        error={errors.govIdPhoto}
      />
      <FileUpload
        label="Upload Permit Photo"
        required
        fileName={form.businessDocument}
        onChange={(file) => update('businessDocument', file)}
        error={errors.businessDocument}
      />
    </div>
  );
};

export default Step3RequiredDocuments;
