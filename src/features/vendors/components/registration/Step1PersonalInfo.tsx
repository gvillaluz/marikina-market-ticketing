import { FC } from 'react';
import type { VendorRegistrationWizardInput } from '@/api/types/vendor.types';
import { TextInput } from './FormField';

interface Step1Props {
  form: VendorRegistrationWizardInput;
  errors: Record<string, string>;
  update: <K extends keyof VendorRegistrationWizardInput>(key: K, value: VendorRegistrationWizardInput[K]) => void;
}

const Step1PersonalInfo: FC<Step1Props> = ({ form, errors, update }) => {
  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
      <TextInput
        label="Last Name"
        required
        value={form.lastName}
        onChange={(e) => update('lastName', e.target.value)}
        placeholder="Dela Cruz"
        error={errors.lastName}
      />
      <TextInput
        label="First Name"
        required
        value={form.firstName}
        onChange={(e) => update('firstName', e.target.value)}
        placeholder="Juan"
        error={errors.firstName}
      />
      <TextInput
        label="Middle Name"
        value={form.middleName}
        onChange={(e) => update('middleName', e.target.value)}
        placeholder="Santos"
      />
      <TextInput
        label="Date of Birth"
        required
        type="date"
        value={form.dateOfBirth}
        onChange={(e) => update('dateOfBirth', e.target.value)}
        error={errors.dateOfBirth}
      />
      <TextInput
        label="Age"
        required
        type="number"
        value={form.age}
        onChange={(e) => update('age', e.target.value)}
        placeholder="35"
        error={errors.age}
      />
      <TextInput
        label="Mobile Number"
        required
        type="tel"
        value={form.mobileNumber}
        onChange={(e) => update('mobileNumber', e.target.value)}
        placeholder="0917 123 4567"
        error={errors.mobileNumber}
      />

      {/* Address block spans full width on mobile, 2 cols on sm+ */}
      <div className="sm:col-span-2 grid grid-cols-1 sm:grid-cols-3 gap-4">
        <TextInput
          label="House No."
          required
          value={form.houseNo}
          onChange={(e) => update('houseNo', e.target.value)}
          placeholder="123"
          error={errors.houseNo}
        />
        <TextInput
          label="Street"
          required
          value={form.street}
          onChange={(e) => update('street', e.target.value)}
          placeholder="J.P. Rizal St."
          error={errors.street}
        />
        <TextInput
          label="Barangay"
          required
          value={form.barangay}
          onChange={(e) => update('barangay', e.target.value)}
          placeholder="San Roque"
          error={errors.barangay}
        />
      </div>

      <TextInput
        label="City"
        value={form.city}
        onChange={(e) => update('city', e.target.value)}
        placeholder="Marikina City"
      />
    </div>
  );
};

export default Step1PersonalInfo;
