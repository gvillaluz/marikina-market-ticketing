# Web ticket modal: photo evidence layout

**Summary.** The photo section of the web ticket modal (`TicketPhotoEvidenceSection`) will match the phone's new "Ticket Photos" design, built with CSS Grid. The paper ticket sits on the left at a readable size and the supporting photos sit on the right, in one column on a narrow window. The wording is the phone's. Written warnings use the same layout with one "Paper warning" group. Visual: `docs/web-ticket-photos-visual.html` (a clickable copy of the modal with the three layouts for comparison; W2 is the chosen one).

No web code has been written. The file plan below needs approval first, as the web rules require.

## Terms

- **Ticket Photos**: the new section title. Avoid: "Photo Evidence Record".
- **Paper ticket**: the scanned photo of the printed paper ticket, shown as its own group. Avoid: "Paper ticket photo", "hero image".
- **Supporting evidence**: every other saved photo of a ticket.

## Why

The web shows every photo as the same 90px thumbnail, so the paper ticket cannot be read without opening it, and the section title and subtitle ("Photo Evidence Record", "shown by their saved classification") do not say that this is a scanned paper ticket plus supporting photos. The user asked for the same improvement the phone got, using CSS Grid, and wanted to choose the layout.

## Locked decisions

None passed all three durable gates; every decision below is a routine, easily reversed styling choice.

## Routine choices

- **Q1 layout: W2, side by side (answer B).** Paper ticket left (about 3/5 of the width, 4:3), supporting photos right (about 2/5, two-column grid of squares); one column below 640px. Rejected: W1 (wide hero with thumbnails underneath), W3 (two stacked titled boxes; recommended, but the user preferred the shorter side-by-side layout).
- **Q2 wording: copy the phone (answer A).** Title "Ticket Photos"; subtitle "The scanned paper ticket and any supporting photos."; groups "Paper ticket" and "Supporting evidence", each with a count ("1 photo", "4 photos"). Rejected: keep the current web titles.
- **Q3 warnings: same layout (answer A).** A written warning shows one "Paper warning" group in the same layout (no supporting column, so it takes the full width) with the subtitle "Photos attached to this warning." Rejected: leave warnings as they are.

## Verified facts

- `TicketPhotoEvidenceSection.tsx` builds the groups; `TicketEvidenceGallery.tsx` renders the thumbnails (90px, flex wrap) and the existing lightbox (zoom and thumbnails). Both are used by `TicketModal.tsx` and `TicketDetailPage.tsx`. The lightbox is not part of this change.
- Current titles: "Photo Evidence Record", "Paper ticket photo", "Supporting evidence", "Unclassified evidence", "Paper warning photo".
- The web rules allow CSS Modules only, CSS variables from the global stylesheet, no inline styles, no new libraries, and one component per file.

## Proposed file plan (not approved yet)

- `TicketPhotoEvidenceSection.tsx` and its CSS Module: new title, subtitle, group labels with counts, and the two-column grid.
- `TicketEvidenceGallery.tsx` and its CSS Module: larger tile for the paper ticket and square tiles for supporting photos, keeping the click-to-open lightbox.
- Possibly one small new component for a labelled group, if the section file grows (one component per file).
- Check: `npm run build`, then look at a ticket and a warning in the modal at wide and narrow widths.

## Risks

- A tall or portrait paper-ticket photo may need `object-fit: contain` so the whole ticket stays visible; to confirm with a real photo.
- Warnings are touched even though not originally named; check one warning record.
- Old records with only unclassified photos need a sensible fallback group ("Unclassified evidence").

## Deferred

None.

## Open threads

None.
