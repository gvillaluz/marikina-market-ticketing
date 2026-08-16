import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Lock, KeyRound, ShieldCheck, ArrowLeft } from 'lucide-react';
import { useAuth } from '@/context/AuthContext';
import { authApi } from '@/api/endpoints/auth.api';
import { ROUTES } from '@/routes/routePaths';

export default function ChangePasswordPage() {
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const { clearMustChangePassword } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setError(null);
    if (!currentPassword) return setError('Enter your current password.');
    if (newPassword.length < 6) return setError('New password must be at least 6 characters.');
    if (!/\d/.test(newPassword)) return setError('New password must contain at least one number.');
    if (newPassword !== confirmPassword) return setError('Passwords do not match.');
    setLoading(true);
    try {
      await authApi.mandatoryChangePassword({
        current_password: currentPassword,
        new_password: newPassword,
        confirm_new_password: confirmPassword,
      });
      clearMustChangePassword();
      navigate(ROUTES.dashboard, { replace: true });
    } catch (err: any) {
      setError(err?.response?.data?.message ?? 'Failed to change password. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 px-4 py-8 sm:px-8">
      <button type="button" onClick={() => navigate(-1)} className="mb-10 inline-flex items-center gap-2 rounded-md bg-blue-900 px-4 py-2 text-sm font-medium text-white shadow-sm transition-colors hover:bg-blue-800">
        <ArrowLeft className="h-4 w-4" />
        Back Home
      </button>
      <div className="mx-auto flex max-w-3xl overflow-hidden rounded-xl bg-white shadow-lg ring-1 ring-black/5">
        <div className="hidden w-2/5 flex-col items-center justify-center gap-4 bg-blue-900 px-8 py-12 text-center sm:flex">
          <div className="flex h-24 w-24 items-center justify-center rounded-full bg-white shadow-md">
            <div className="flex h-full w-full items-center justify-center rounded-full bg-gradient-to-br from-yellow-300 via-green-400 to-blue-400 text-[10px] font-bold text-blue-900">SEAL</div>
          </div>
          <h2 className="text-lg font-bold leading-snug text-white">Marikina Public Market<br />Inspection System</h2>
          <p className="text-sm text-blue-200">Admin Access</p>
        </div>
        <div className="w-full px-6 py-10 sm:w-3/5 sm:px-10">
          <h1 className="mb-8 text-center text-xl font-bold tracking-wide text-blue-900">CHANGE PASSWORD</h1>
          <form onSubmit={handleSubmit} className="space-y-5" noValidate>
            <div>
              <label className="mb-1.5 block text-xs font-semibold uppercase tracking-wide text-slate-500">Current Password</label>
              <div className="relative">
                <Lock className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
                <input type="password" value={currentPassword} onChange={(e) => setCurrentPassword(e.target.value)} placeholder="Enter current password" className="w-full rounded-md border border-slate-300 bg-white py-2.5 pl-9 pr-3 text-sm text-slate-800 placeholder:text-slate-400 focus:border-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-100" />
              </div>
            </div>
            <div>
              <label className="mb-1.5 block text-xs font-semibold uppercase tracking-wide text-slate-500">New Password</label>
              <div className="relative">
                <KeyRound className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
                <input type="password" value={newPassword} onChange={(e) => setNewPassword(e.target.value)} placeholder="Enter new password" className="w-full rounded-md border border-slate-300 bg-white py-2.5 pl-9 pr-3 text-sm text-slate-800 placeholder:text-slate-400 focus:border-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-100" />
              </div>
              <p className="mt-1 text-xs text-slate-400">Min. 6 characters, at least 1 number.</p>
            </div>
            <div>
              <label className="mb-1.5 block text-xs font-semibold uppercase tracking-wide text-slate-500">Confirm New Password</label>
              <div className="relative">
                <ShieldCheck className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
                <input type="password" value={confirmPassword} onChange={(e) => setConfirmPassword(e.target.value)} placeholder="Re-enter new password" className="w-full rounded-md border border-slate-300 bg-white py-2.5 pl-9 pr-3 text-sm text-slate-800 placeholder:text-slate-400 focus:border-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-100" />
              </div>
            </div>
            {error && <p className="rounded-md bg-red-50 px-3 py-2 text-sm text-red-700">{error}</p>}
            <button type="submit" disabled={loading} className="w-full rounded-md bg-blue-900 py-3 text-sm font-semibold tracking-wide text-white shadow-sm transition-colors hover:bg-blue-800 disabled:cursor-not-allowed disabled:opacity-60">
              {loading ? 'SAVING...' : 'SAVE PASSWORD'}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
