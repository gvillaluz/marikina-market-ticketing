import { FC } from 'react';

interface LoaderProps {
  size?: 'sm' | 'md' | 'lg';
  label?: string;
  fullPage?: boolean;
}

const Loader: FC<LoaderProps> = ({ size = 'md', label, fullPage = false }) => {
  const dimension = size === 'sm' ? '20px' : size === 'lg' ? '48px' : '32px';

  const content = (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '0.75rem' }}>
      <div
        style={{
          width: dimension,
          height: dimension,
          border: '3px solid var(--neutral-200)',
          borderTopColor: 'var(--primary-500)',
          borderRadius: '50%',
          animation: 'spin 0.7s linear infinite',
        }}
      />
      {label && <p style={{ color: 'var(--neutral-500)', fontSize: '0.875rem' }}>{label}</p>}
    </div>
  );

  if (fullPage) {
    return (
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          minHeight: '60vh',
        }}
      >
        {content}
      </div>
    );
  }

  return <div style={{ padding: '0.5rem' }}>{content}</div>;
};

/** Global keyframes (injected once). */
export function injectSpinKeyframes() {
  if (typeof document === 'undefined') return;
  if (document.getElementById('spin-keyframes')) return;
  const style = document.createElement('style');
  style.id = 'spin-keyframes';
  style.textContent = '@keyframes spin { to { transform: rotate(360deg); } }';
  document.head.appendChild(style);
}

export default Loader;
