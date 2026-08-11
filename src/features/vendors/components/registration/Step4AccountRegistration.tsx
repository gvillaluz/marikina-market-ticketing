import { FC } from 'react';
import type { VendorRegistrationWizardInput } from '@/api/types/vendor.types';
import { TextInput } from './FormField';

interface Step4Props {
  form: VendorRegistrationWizardInput;
  errors: Record<string, string>;
  update: <K extends keyof VendorRegistrationWizardInput>(key: K, value: VendorRegistrationWizardInput[K]) => void;
}

const Step4AccountRegistration: FC<Step4Props> = ({ form, errors, update }) => {
  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
      <div className="sm:col-span-2">
        <TextInput
          label="Email Address"
          required
          type="email"
          value={form.email}
          onChange={(e) => update('email', e.target.value)}
          placeholder="you@example.com"
          error={errors.email}
        />
      </div>
      <TextInput
        label="Password"
        required
        type="password"
        value={form.password}
        onChange={(e) => update('password', e.target.value)}
        placeholder="Enter password"
        error={errors.password}
      />
      <TextInput
        label="Confirm Password"
        required
        type="password"
        value={form.confirmPassword}
        onChange={(e) => update('confirmPassword', e.target.value)}
        placeholder="Re-enter password"
        error={errors.confirmPassword}
      />
    </div>
  );
};

export default Step4AccountRegistration;
