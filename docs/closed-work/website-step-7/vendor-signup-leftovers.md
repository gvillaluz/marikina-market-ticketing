# Website vendor sign-up leftovers removed (CLOSED 2026-11-11, PR #22)

The second item in the Revision Phase "Open" list. Approved scope (2026-11-11): website cleanup, then extended by the user the same day to the unused website files, the `firebase` package and the server's old sign-up routes. The `roadmap.md` item had been on hold since the business and person management slice.

What was removed
- Website: home page register buttons and the "Market Vendor" card (Login opens `/admin/login`; closing section is "Business records", telling businesses to contact the market office); the vendor login page, its "Create one" link and the vendor forgot-password address; the vendor sign-up page and the old application review pages and their registration counter. Old addresses (`/register`, `/login`, `/admin/vendor-registrations`, ...) end on the administrator login, or on the dashboard when signed in.
- Browser alerts: the "new vendor registration request" pop-up and the notification registration and sign-out cleanup that only served it (the server sends no such alert and the website ignored every other kind); the `firebase` package; the Firebase settings.
- Also: unused colour variables, the Accounts page registration hint, the landing page QR bullet, the "+ Add Vendor" button on the old vendors page, and 37 files nothing imported.
- Server: 9 routes now answer 404: `POST /api/vendor/register`, `approve-registry`, `decline-registry`, `request-more-information`, `POST /api/admin/vendors/register`, `GET /api/admin/vendors/registration-status-counts`, `registration-requests`, `registration-requests/{id}`, `registration-requests/{id}/documents`. Service and repository methods, request/response types and the old tests were deleted. The registration table and its mapping were kept: no schema change, no migration. Shared test helpers moved to `SharedTestDoubles.cs`.

Evidence ([live results](../../../evidence/vendor-signup-cleanup-live/results.md)): website build passed; 160 Node tests (5 new, each failed first, deliberate break caught); server 841 tests passed, 2 skipped, 0 failed (3 new route tests failed first). Live on `marikina_market_e2e`: website 35/35 with the worktree website and server; server routes: 9 removed routes answer 404, kept routes 401. Records, businesses and persons stayed at 13 / 3 / 3.

Limits: Admin Officer not checked live; phone app not touched. The audit-log labels for old sign-up actions were kept so old audit entries still read correctly; the unused `SendPushNotificationToAdminsAsync` on the server and the `--registration-*` colour names still used by other screens were left alone. Existing application rows stay in the database, unused.

Code: commit `a947e8d` on branch `vendor-signup-cleanup`, merged as pull request #22 (main `a26ce13`). The worktree was removed on 2026-11-11 with the user's approval; the branch is kept.
