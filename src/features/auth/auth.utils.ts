export function resolveLoginIdentifier(username: string): string | null {
  const trimmed = username.trim();
  if (!trimmed) return null;

  if (trimmed.includes("@")) {
    const isEmail = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(trimmed);
    return isEmail ? trimmed : null;
  }

  if (trimmed.toLowerCase() === "admin") return "admin@marikina.gov.ph";
  if (
    trimmed.toLowerCase() === "vendor" ||
    /^\d{3}-\d{5}[A-Za-z]?$/.test(trimmed)
  ) {
    return "vendor@marikina.gov.ph";
  }

  return null;
}
