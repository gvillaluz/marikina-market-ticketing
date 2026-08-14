import { FC, InputHTMLAttributes, SelectHTMLAttributes } from 'react';

interface BaseProps {
  label: string;
  error?: string;
  required?: boolean;
}

type TextInputProps = BaseProps & InputHTMLAttributes<HTMLInputElement>;

/** Shared text/email/password input. */
export const TextInput: FC<TextInputProps> = ({ label, error, required, ...inputProps }) => {
  return (
    <div>
      <label className="block text-xs font-semibold uppercase tracking-wider text-bodygray mb-1.5">
        {label}
        {required && <span className="text-accent"> *</span>}
      </label>
      <input
        {...inputProps}
        className={`w-full px-3 py-2.5 rounded-md border bg-white text-sm focus:outline-none focus:ring-2 focus:ring-primary/30 transition-colors ${
          error ? 'border-red-400 focus:border-red-400' : 'border-gray-300 focus:border-primary'
        }`}
      />
      {error && <span className="text-xs text-red-600 mt-1 block">{error}</span>}
    </div>
  );
};

type SelectProps = BaseProps & SelectHTMLAttributes<HTMLSelectElement> & {
  options: string[];
  placeholder?: string;
};

/** Shared select input. */
export const SelectInput: FC<SelectProps> = ({ label, error, required, options, placeholder, ...selectProps }) => {
  return (
    <div>
      <label className="block text-xs font-semibold uppercase tracking-wider text-bodygray mb-1.5">
        {label}
        {required && <span className="text-accent"> *</span>}
      </label>
      <select
        {...selectProps}
        className={`w-full px-3 py-2.5 rounded-md border bg-white text-sm focus:outline-none focus:ring-2 focus:ring-primary/30 transition-colors ${
          error ? 'border-red-400' : 'border-gray-300 focus:border-primary'
        }`}
      >
        {placeholder && <option value="">{placeholder}</option>}
        {options.map((opt) => (
          <option key={opt} value={opt}>
            {opt}
          </option>
        ))}
      </select>
      {error && <span className="text-xs text-red-600 mt-1 block">{error}</span>}
    </div>
  );
};

interface FileUploadProps {
  label: string;
  error?: string;
  required?: boolean;
  fileName?: File | string | null;
  onChange: (file: File | null) => void;
}

/** Dashed upload box that stores a file object. */
export const FileUpload: FC<FileUploadProps> = ({ label, error, required, fileName, onChange }) => {
  const fileDisplayName = typeof fileName === 'string' ? '' : fileName?.name ?? 'Click to upload';

  return (
    <div>
      <label className="block text-xs font-semibold uppercase tracking-wider text-bodygray mb-1.5">
        {label}
        {required && <span className="text-accent"> *</span>}
      </label>
      <label
        className={`flex flex-col items-center justify-center gap-1 border-2 border-dashed rounded-lg px-4 py-6 text-center cursor-pointer transition-colors ${
          error ? 'border-red-400 bg-red-50/40' : 'border-primary/40 bg-bglight hover:bg-bglight/70'
        }`}
      >
        <input
          type="file"
          className="hidden"
          onChange={(e) => {
            const file = e.target.files?.[0];
            onChange(file ?? null);
          }}
        />
        <span className="text-primary text-xl leading-none" aria-hidden>
          ⬆
        </span>
        <span className="text-sm font-medium text-primary">
          {fileDisplayName}
        </span>
        {!fileName && (
          <span className="text-xs text-bodygray">JPG, PNG or PDF, max 5MB</span>
        )}
      </label>
      {error && <span className="text-xs text-red-600 mt-1 block">{error}</span>}
    </div>
  );
};
