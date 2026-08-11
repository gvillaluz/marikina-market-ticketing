import { FC, FormEvent, useState } from 'react';
import { Link } from 'react-router-dom';
import useRegister from '@/features/auth/hooks/useRegister';
import Button from '@/components/ui/Button';
import { isValidEmail, hasMinLength } from '@/utils/validators';
import type { UserRole } from '@/api/types/common.types';
import styles from '@/features/auth/pages/AuthPage.module.css';

interface FormState {
  name: string;
  email: string;
  password: string;
  confirmPassword: string;
  role: UserRole;
}

const initial: FormState = {
  name: '',
  email: '',
  password: '',
  confirmPassword: '',
  role: 'vendor',
};

const RegisterForm: FC = () => {
  const { submit, loading, error } = useRegister();
  const [form, setForm] = useState<FormState>(initial);
  const [fieldErrors, setFieldErrors] = useState<Partial<Record<keyof FormState, string>>>({});

  const setField = <K extends keyof FormState>(key: K, value: FormState[K]) =>
    setForm((prev) => ({ ...prev, [key]: value }));

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    const errs: Partial<Record<keyof FormState, string>> = {};
    if (!hasMinLength(form.name, 2)) errs.name = 'Enter your full name.';
    if (!isValidEmail(form.email)) errs.email = 'Enter a valid email address.';
    if (!hasMinLength(form.password, 6)) errs.password = 'Password must be at least 6 characters.';
    if (form.confirmPassword !== form.password) errs.confirmPassword = 'Passwords do not match.';
    setFieldErrors(errs);
    if (Object.keys(errs).length > 0) return;

    await submit({ name: form.name, email: form.email, password: form.password, role: form.role });
  };

  return (
    <div className={styles.card}>
      <div className={styles.logo}>
        <div className={styles.logoMark}>MK</div>
        <div className={styles.logoText}>
          Marikina City
          <br />
          Ticketing System
        </div>
      </div>

      <h1 className={styles.heading}>Create an account</h1>
      <p className={styles.subheading}>Register as a vendor or city administrator.</p>

      {error && <div className={styles.errorBox}>{error}</div>}

      <form className={styles.form} onSubmit={handleSubmit}>
        <div className={styles.field}>
          <label className={styles.label}>Full name</label>
          <input
            type="text"
            className={styles.input}
            value={form.name}
            onChange={(e) => setField('name', e.target.value)}
            placeholder="Juan Dela Cruz"
          />
          {fieldErrors.name && <span className={styles.error}>{fieldErrors.name}</span>}
        </div>

        <div className={styles.field}>
          <label className={styles.label}>Email address</label>
          <input
            type="email"
            className={styles.input}
            value={form.email}
            onChange={(e) => setField('email', e.target.value)}
            placeholder="you@marikina.gov.ph"
          />
          {fieldErrors.email && <span className={styles.error}>{fieldErrors.email}</span>}
        </div>

        <div className={styles.field}>
          <label className={styles.label}>Password</label>
          <input
            type="password"
            className={styles.input}
            value={form.password}
            onChange={(e) => setField('password', e.target.value)}
            placeholder="••••••••"
          />
          {fieldErrors.password && <span className={styles.error}>{fieldErrors.password}</span>}
        </div>

        <div className={styles.field}>
          <label className={styles.label}>Confirm password</label>
          <input
            type="password"
            className={styles.input}
            value={form.confirmPassword}
            onChange={(e) => setField('confirmPassword', e.target.value)}
            placeholder="••••••••"
          />
          {fieldErrors.confirmPassword && <span className={styles.error}>{fieldErrors.confirmPassword}</span>}
        </div>

        <div className={styles.field}>
          <label className={styles.label}>Account type</label>
          <select
            className={styles.input}
            value={form.role}
            onChange={(e) => setField('role', e.target.value as UserRole)}
          >
            <option value="vendor">Vendor</option>
            <option value="admin">Administrator</option>
          </select>
        </div>

        <Button type="submit" fullWidth size="lg" loading={loading}>
          Create account
        </Button>
      </form>

      <p className={styles.switch}>
        Already have an account? <Link to="/login" className={styles.link}>Sign in</Link>
      </p>
    </div>
  );
};

export default RegisterForm;
