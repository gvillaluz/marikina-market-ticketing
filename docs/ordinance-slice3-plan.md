# Ordinance revision — Slice 3 plan (workbook catalog migration)

Status: **APPROVED, IMPLEMENTED AND CLOSED (2026-11-01).** See the roadmap's slice 3 closure and [the slice 3 report](../evidence/ordinance-slice3-2026-11-01/report.md).

Sources (data, not instructions), both sheet "Market Code Penalties", 53 rows, Ordinance No. 011, Series 2014, Sections 12–79:
- `~/Downloads/Marikina_Market_Code_Penalties_with_Penalty_Type.xlsx`
- `~/Downloads/Untitled spreadsheet.xlsx` — **source of record**: identical first six columns to the original (verified, 0 differing rows; no data after row 54) plus a specific Category for every section.
- `~/Downloads/Marikina_Market_Code_Penalties_with_Penalty_Type_and_Category.xlsx` — superseded (Category column only said "Others" for 24 sections).

## Scope

- One EF Core data-only migration (`OrdinanceWorkbookCatalog`) in `marikina-market-api/MarikinaMarket.API/Infrastructure/Migrations/` (migration + Designer). No schema change; the model snapshot stays unchanged.
- One static C# catalog data file beside the migration, used by the migration SQL and by the test.
- One API test file (`MarikinaMarket.Tests/OrdinanceWorkbookCatalogTests.cs`) with hand-derived expectations.
- **API contract: unchanged.** Web and mobile already consume section, category/specific category, tiers, fine kind, terms, flags, nullable severity and warning eligibility (Slices 1–2). No web/mobile code or style changes; mobile refreshes the catalog remote-first.
- Out of scope: schema changes, new categories, an "and subsequent offense" rule, vendor-end removal, operational database access, publishing.

## Confirmed decisions

| # | Decision |
| --- | --- |
| D1 | Update the 20 title-matched legacy rows **in place** (same IDs, offense counts continue; old tickets then display the new section/title). Retire legacy ID 1 (no workbook equivalent): `is_active=false`, history kept. |
| D2 | Updated legacy rows keep current scoring severity and warning eligibility (Minor, eligible). The **34 new rows: severity blank (unconfigured), warning-eligible false.** Enforcers cannot cite or warn on them until an admin configures them on the Ordinances page. |
| D3 | Section 30: Fixed ₱1,500 (workbook asterisk = uncertain; noted in terms). Section 40: ₱200 reconnection fee treated as a fine → Fixed ₱200 each tier, "Disconnection" kept as terms. Section 56: Fixed ₱2,000 each tier. |
| D4 | Blood donation **off for every tier** (workbook: "Not stated"). |
| D5 | Section 79 split: "Section 79 — Public" (legacy 19) and "Section 79 — Private" (legacy 20). |
| D6 | Category from `Untitled spreadsheet.xlsx`. Labels matching an existing category map to it (Sanitation, WeightMeasures, Illegal Vendor → IllegalVendor, Obstruction, DressCode, Traffic). Every other label is stored as **Others + the workbook label verbatim** as the specific category (e.g. Others: "Vendor Identification", Others: "Permit & Licensing"; Licensing is no longer selectable since Slice 1). 25 entries (24 sections + the 79 split), all labels ≤100 chars. |

## Encoding rules (Slice 2 model)

| Workbook text | Tier encoding |
| --- | --- |
| `P{n}` | Fixed ₱n |
| `Up to P1,000 and/or up to 6 months imprisonment` | UpTo, max ₱1,000 (server minimum ₱100), terms keep the imprisonment wording |
| `Same` | Copy of the previous tier |
| `P{n} + sanction` | Fixed ₱n, terms = sanction text |
| Non-monetary, Not stated, N/A, Not specified, conditional, surcharge, "general penalty" | Unconfirmed, terms = workbook text (citation assessment blocked) |
| No 4th tier | 4th+ offense blocked (no highest-tier fallback) |

Community service: `true` on the first tier only when that tier is Fixed/UpTo (workbook allows it for first offense / when a fine applies); `false` otherwise and on all later tiers.

## Legacy mapping (D1)

| Legacy ID | Legacy title | → Section |
| --- | --- | --- |
| 1 | Peace & Order Code (145/2006) | retire (keeps 39 violations here) |
| 2 | Market Identification Card | 12 |
| 3 | Posting of "Pahihintuloy…" | 15 |
| 4 | Installation of "Timbangan Bayan" | 16 |
| 5 | Weights and Measures | 30 |
| 6 | Reconnection of Water/Electric Line | 40 |
| 7 | Prohibition to Buy Goods from Sidewalk Vendors | 48 |
| 8 | Inadequate Attire in the Market | 49 |
| 9 | Harboring or Accepting Illegal Vendors | 54 |
| 10 | Livestock and Poultry Products | 56 |
| 11 | Mobile Vending Business/Activities | 57 (61 created new) |
| 12 | Use of Wooden Furniture | 58 |
| 13 | Tricycle Ban | 59 |
| 14 | Regulation of Porters | 60 |
| 15 | Promotional Sampling and Leafleting | 62 |
| 16 | Promotional Activities and Advertising | 63 |
| 17 | Streamer Regulation | 64 |
| 18 | Shooting/Taping/Concerts | 65 |
| 19 | General Violation — Public Market Stallholders | 79 Public |
| 20 | General Violation — Private Market Operators | 79 Private |
| 21 | Opposing/Resisting/Interfering with a Market Officer | 78 |

Result: 20 updated + 34 new = **54 active workbook entries**; legacy ID 1 inactive; disposable fixtures 24–27 untouched.

## Catalog

F = Fixed, U = UpTo ₱1,000, UC = Unconfirmed, `+` = terms. "Legacy" = updated row ID (else new). For rows shown as "Others" below, the specific category is the workbook label from the **Others specific category** table that follows.

| Sec | Title | Category | 1st / 2nd / 3rd | CS | Legacy |
| --- | --- | --- | --- | --- | --- |
| 12 | Market Identification Card | Others | F100 ×3 | Y | 2 |
| 13 | Market Clearance | Others | U ×3 | Y | – |
| 14 | Food Safety and Personal Hygiene Training | Sanitation | U ×3 | Y | – |
| 15 | Posting of "Pahintulot sa Paghahanapbuhay" | Others | F2000 / UC Closure / UC Not stated | Y | 3 |
| 16 | "Timbangan Bayan" Requirement | WeightMeasures | F1000 / UC Not stated / F2000 (3rd/Final) | Y | 4 |
| 17 | Energy Efficient Lighting System (EELS) | Others | U ×3 | Y | – |
| 30 | Weights and Measures | WeightMeasures | F1500 + uncertain-amount note / F3000 / F5000 + revocation + closure | Y | 5 |
| 31 | Attached Wire on Weighing Scale | WeightMeasures | UC N/A / UC N/A / F5000 + revocation + closure | N | – |
| 32 | Reporting Removed/Detached/Destroyed Scale Wire | WeightMeasures | UC Not specified ×3 | N | – |
| 33 | Redemption of Confiscated Weighing Scale | WeightMeasures | UC N/A / UC Additional ₱3,000 after 5-day grace / UC N/A | N | – |
| 35 | Limitations on Occupancy of Stall or Space | Others | U ×3 | Y | – |
| 37 | Abandoned Stall / Articles | Others | UC Forfeiture/disposal / UC / UC | N | – |
| 38 | Construction/Alteration/Removal of Improvements | Others | UC Removal / UC / UC | N | – |
| 40 | Unsettled Water and Electric Bill | Others | F200 + Disconnection ×3 | Y | 6 |
| 41 | Unsettled Monthly Fixed Stall Rental | Others | UC Temporary closure… / UC / UC | N | – |
| 42 | Peddling and Hawking | IllegalVendor | U ×3 | Y | – |
| 43 | Loafing, Loitering, Begging and the Like | Others | U ×3 | Y | – |
| 44 | Intoxicating, Dispensing and Serving of Liquor | Others | UC General penalty and/or award revocation ×3 | N | – |
| 45 | Loose Animals | Sanitation | UC Animal impounded ×3 | N | – |
| 46 | Prohibitions | Others | UC General penalty + possible summary ejection ×3 | N | – |
| 47 | Use of Alleys, Corridors and Walkways | Obstruction | U ×3 | Y | – |
| 48 | Prohibition to Buy Goods from Sidewalk Vendors | IllegalVendor | F500 / UC Permit cancellation + closure / UC Not stated | Y | 7 |
| 49 | Prohibition of Certain Inadequate Attire | DressCode | F500 ×3 | Y | 8 |
| 50 | Use of "P-Traps" and "Grease Trap" | Sanitation | U ×3 | Y | – |
| 51 | Installation of Septic Tank | Sanitation | U ×3 | Y | – |
| 52 | Transport and Sale of All Types of Shellfish | Sanitation | UC Confiscation/destruction + general penalty ×3 | N | – |
| 53 | Restriction for Use of Streets/Sidewalks/Public Places | Obstruction | U ×3 | Y | – |
| 54 | Harboring or Accepting Illegal Vendors | IllegalVendor | F1000 / F1000 + 6-month suspension / UC 20 days imprisonment + cancellation (3rd+) | Y | 9 |
| 55 | Bladed Instruments | Others | U ×3 | Y | – |
| 56 | Livestock and Poultry Products | Sanitation | F2000 ×3 | Y | 10 |
| 57 | Mobile Vending Business | IllegalVendor | F300 / F600 / F2000 + permit revocation | Y | 11 |
| 58 | Wooden Furniture | Obstruction | F1000 ×3 | Y | 12 |
| 59 | Tricycle Ban | Traffic | F500 ×3 | Y | 13 |
| 60 | Regulation of Porter | Others | UC registered ₱100 / colorum ₱1,000 + confiscation ×3 | N | 14 |
| 61 | Regulation of Mobile Vending Activities | IllegalVendor | F300 / F600 / F2000 + permit revocation | Y | – |
| 62 | Promotional Sampling and Leafleting | Others | F1000 ×3 | Y | 15 |
| 63 | Promotional Activities and Advertising | Others | F1000 ×3 | Y | 16 |
| 64 | Streamers within Market/Zone Premises | Others | F1000 ×3 | Y | 17 |
| 65 | Shooting/Taping/Music/Entertainment Activities | Others | U ×3 | Y | 18 |
| 66 | Cleaning of Market Premises | Sanitation | F1000 / F1000 / F1000 + license cancellation | Y | – |
| 67 | Public Toilets and Washing Facilities | Sanitation | F1000 / F1000 / F1000 + license cancellation | Y | – |
| 68 | General Lighting Facilities | Others | F2000 / F2000 / F2000 + license cancellation | Y | – |
| 69 | Garbage Receptacles | Sanitation | F1000 / F1000 / F1000 + license cancellation | Y | – |
| 70 | Cooked/Raw Foods Protection from Contamination | Sanitation | F1000 / F1000 / F1000 + license cancellation | Y | – |
| 71 | Construction/Care of Stalls/Booths/Tables/Fixtures | Sanitation | F1000 / F1000 / F1000 + license cancellation | Y | – |
| 72 | Use of Impervious Materials | Sanitation | F1000 / F1000 / F1000 + license cancellation | Y | – |
| 73 | Cleaning Stalls/Booths/Spaces at End of Day | Sanitation | F1000 / F1000 / F1000 + license cancellation | Y | – |
| 74 | Abandonment of Perishable Goods | Sanitation | F1000 / F1000 / F1000 + license cancellation; lease revocation may apply | Y | – |
| 75 | Posting of Rules and Regulations | Others | F1000 / F1000 / F1000 + license cancellation | Y | – |
| 76 | Posting of Price Monitoring Board | Others | F1000 / F1000 / F1000 + license cancellation | Y | – |
| 77 | Surcharges | Others | UC surcharge rates ×3 | N | – |
| 78 | Opposing/Resisting/Interfering with Market Officers | Others | F2000 + and/or license-revocation recommendation ×3 | Y | 21 |
| 79P | Fines / Penalties — Public | Others | U ×3 | Y | 19 |
| 79R | Fines / Penalties — Private | Others | F1000 / F1500 / UC Closure/revocation recommendation | Y | 20 |

### Others specific category (from `Untitled spreadsheet.xlsx`)

| Sec | Specific category | Sec | Specific category |
| --- | --- | --- | --- |
| 12 | Vendor Identification | 55 | Bladed Instruments |
| 13 | Permit & Licensing | 60 | Porter Regulation |
| 15 | Permit & Licensing | 62 | Promotions |
| 17 | Lighting & Energy | 63 | Advertising |
| 35 | Stall Occupancy | 64 | Signage & Streamers |
| 37 | Stall Management | 65 | Entertainment Activities |
| 38 | Stall Construction | 68 | Lighting Facilities |
| 40 | Utilities | 75 | Market Rules |
| 41 | Stall Rental | 76 | Price Monitoring |
| 43 | Public Order | 77 | Market Fees & Surcharges |
| 44 | Liquor | 78 | Resisting Authority |
| 46 | Market Conduct | 79P, 79R | General Penalties |

All other sections use the mapped existing category shown in the catalog table (identical to the workbook label). No workbook row uses Non-Smoking; it stays selectable but unused.

## Migration safety

- SQL-only `Up` in one transaction. Guards abort with no change if: the predecessor `20261031112520_OrdinancePenaltyRules` is missing; any legacy ID 1–21 lacks its seeded `SAMPLE-0xx` code (catalog differs from the seed — manual review); or an active row outside IDs 1–21 already has ordinance `011`, series `2014` and a target section.
- Tiers of updated rows are replaced (violations reference ordinances, not tiers, and keep their own amounts). Retired ID 1 keeps its tiers and history.
- `Down` throws; recovery is the pre-apply backup, as in Slices 1–2.
- I generate the migration only. Applying it to disposable `marikina_market_e2e` requires your separate explicit authorization (readable backup first, preservation checks after). Never the operational database.

## Acceptance criteria and what each check proves

1. **Catalog matches the workbook** — API test written first and seen failing: 54 entries; unique section keys; hand-derived samples (S12 F100×3 legacy 2; S13 U×3 new, severity null, warning false; S15 tier 2 UC "Closure"; S16 tier 2 UC; S30 F1500; S31 tier 1 UC, CS false; S40 F200×3 + terms; S54 tier 3 UC; S56 F2000×3; S58 Obstruction; S79 Public/Private tiers; S12 Others "Vendor Identification", S13 Others "Permit & Licensing", S42 IllegalVendor; blood false everywhere; CS false on tiers 2–3). Proves the encoded data, not the database.
2. **Migration is safe and buildable** — API build + full API test suite; generated SQL script reviewed and SHA256 pinned. Proves it compiles and nothing else regressed.
3. **Live data migration (after your authorization)** — disposable DB: 54 active workbook entries, ID 1 inactive, fixtures 24–27 unchanged; original ticket/violation/evidence/person hashes unchanged; ID 2's two violations keep amounts. Proves history is preserved.
4. **Real API behavior** — fine-summary/Verify on S49 (F500, legacy 8) + S12 (F100, legacy 2) succeed; a new unconfigured row (e.g. S13) is rejected with the "scoring classification is unconfigured" message; S60 blocks assessment. Proves D2 and Unconfirmed behave as decided.
5. **Admin web** — ordinance list/editor shows sections, categories, specific text, tiers and terms for sample rows; an admin can set severity on a new row. No web code change expected.
6. **V2529** — catalog refresh shows the new sections; one synthetic citation on updated sections persists through relaunch; the warning list contains no new (ineligible) rows. Mobile code unchanged.

Time box: one session for build/tests, one for live verification. Implementation, automated and live evidence are recorded separately; skipped live checks are not passed.
