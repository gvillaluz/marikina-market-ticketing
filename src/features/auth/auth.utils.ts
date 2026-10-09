export function resolveLoginIdentifier(username: string): string | null {
  const trimmed = username.trim();
  if (!trimmed) return null;

  if (trimmed.includes("@")) {
    const isEmail = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(trimmed);
    return isEmail ? trimmed : null;
  }

  return /\s/.test(trimmed) ? null : trimmed;
}
