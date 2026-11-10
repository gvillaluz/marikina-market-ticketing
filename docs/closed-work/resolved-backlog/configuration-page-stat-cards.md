# Resolved backlog item

- Resolved 2026-11-03: hardcoded configuration page stat cards and notes (market sections, active ordinances, last backup). The page now shows live counts and the real last successful backup (HeadAdmin only), with loading skeletons and per-card retry. Evidence: web build passed; the configuration browser check passed 3/3 against a temporary dev server with mocked API responses (real values, none-yet, error/fallback, retry, AdminOfficer hides the backup card, 390px layout). Not verified against the real API; changes remain uncommitted.
