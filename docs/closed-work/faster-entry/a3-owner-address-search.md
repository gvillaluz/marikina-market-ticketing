# Faster entry A3: business search by owner or address (closed 2026-11-09)

Closed by the user on 2026-11-09 after all automated checks, deliberate breaks and phone checks passed. Full results and screenshots: `evidence/a3-owner-address-search-live/results.md`.

## What it does for the enforcer

The "Find business" search on the phone also finds a business by the owner's name (first name first or last name first) or by any part of its address (house number, street, barangay, city). Each result line now ends with the business address. The search box, search page and entry page wording name owner and address. Inactive businesses still never appear.

## API contract (as built)

- Route: `GET /api/vendor/lookup?search=` (MarketEnforcer). Unchanged route and response.
- Request: unchanged.
- Response: unchanged (business list plus `has_more` and `total`). Matching now also covers owner "first last", owner "last first", and the address "house number, street, barangay, city". Active businesses only, at most 20, exact stall or account number first, then by business name.
- Errors: 400 when the search is empty ("Enter a business name, stall, owner, address or account number.") or over 200 characters; 401/403.
- Consumers: phone app only. No website change, no database change, no migration.

## Changes per file

- Server: `Application/Services/VendorService.cs` (empty-search message), `Infrastructure/Repositories/VendorRepository.cs` (owner and address matching).
- Server tests: `MarikinaMarket.Tests/BusinessLookupAndPeopleTests.cs` (10 owner/address search cases; empty-search message checked).
- Phone: `search_business_bottom_sheet.dart` (address on each result line; wording), `violator_info_card.dart` (entry page wording).
- Phone tests: `test/business_people_test.dart` (address on the result line, sheet wording, new entry page wording test).

## Evidence

- Server: build 0 errors; 825 passed, 0 failed, 2 skipped (the same 2 as before).
- Phone: format clean, analyze no issues, 458 passed.
- Deliberate breaks: 4 of 4 caught (last-name-first match, address match, address on the result line, entry page wording).
- Phone checks on V2529 against `marikina_market_e2e`: checks 1–6 passed; nothing submitted, no photos uploaded.

## Limits

- An owner's name typed with the middle name is not matched; only "first last" and "last first".
- Not committed when closed: the code is in the worktree `mmt-a3-owner-address-search` (branch `a3-owner-address-search`). An older copy of these changes, with different wording, also sits uncommitted in the main project folder.
- Merged into `main` as pull request #7 (2026-11-09). The older copy in the main folder was discarded (backed up outside the project first) and the worktree removed; the branch `a3-owner-address-search` is kept.
