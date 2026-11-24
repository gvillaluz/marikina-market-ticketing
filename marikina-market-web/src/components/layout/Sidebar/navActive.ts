// A sidebar item stays highlighted on its own page and on the pages inside it.
export function isNavItemActive(
  pathname: string,
  to: string,
  innerPaths: readonly string[] = [],
): boolean {
  return [to, ...innerPaths].some(
    (path) => pathname === path || pathname.startsWith(`${path}/`),
  );
}
