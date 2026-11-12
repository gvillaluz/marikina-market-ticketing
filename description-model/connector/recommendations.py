"""Section recommendations from the model's findings.

Weighting, risk levels and peak window follow the model's own section summary
(description-model "summarize_sections"). Added by agreement (2026-11-11): a category
needs at least 2 records in the section, and confidence counts the section's records.
"""

from collections import Counter, defaultdict
from datetime import timedelta, timezone

MANILA = timezone(timedelta(hours=8))
MINIMUM_RECORDS = 2


def risk_level(score):
    return "High" if score >= 14 else "Moderate" if score >= 8 else "Low"


def pattern_confidence(record_count):
    return "High" if record_count >= 8 else "Moderate" if record_count >= 5 else "Low"


def summarize_sections(records, findings, taxonomy):
    """records: dicts with id, section_id, type ("Warning" or "Ticket") and issued_at (aware).
    findings: record id -> set of category codes. Returns one card per section that has a
    recommendation, highest risk first."""
    by_section = defaultdict(list)
    for record in records:
        by_section[record["section_id"]].append(record)
    cards = [card for section_id, section_records in by_section.items()
             if (card := summarize_section(section_id, section_records, findings, taxonomy))]
    return sorted(cards, key=lambda card: (-card["risk_score"], card["section_id"]))


def summarize_section(section_id, records, findings, taxonomy):
    groups = defaultdict(list)
    for record in records:
        for code in findings.get(record["id"], ()):
            groups[code].append(record)

    def weight(code):
        severity = int(taxonomy[code]["severity"])
        return sum(severity * (0.5 if record["type"] == "Warning" else 1.0) for record in groups[code])

    eligible = [code for code in groups if len(groups[code]) >= MINIMUM_RECORDS]
    if not eligible:
        return None
    main = max(eligible, key=lambda code: (weight(code), len(groups[code]), code))
    score = round(sum(weight(code) for code in groups), 2)
    flagged = [record for record in records if findings.get(record["id"])]
    hourly = Counter(record["issued_at"].astimezone(MANILA).hour for record in flagged)
    peak = max(range(24), key=lambda start: (sum(hourly[(start + i) % 24] for i in range(3)), -start))
    category = taxonomy[main]
    return {
        "section_id": section_id,
        "category_code": main,
        "category_name_english": category["name_en"],
        "category_name_filipino": category["name_tl"],
        "recommended_action": category["action_template_en"],
        "category_record_count": len(groups[main]),
        "section_record_count": len(records),
        "risk_score": score,
        "risk_level": risk_level(score),
        "pattern_confidence": pattern_confidence(len(records)),
        "peak_start_hour": peak,
        "hourly_counts": [hourly[hour] for hour in range(24)],
        "last_flagged_at": max(record["issued_at"] for record in flagged),
    }
