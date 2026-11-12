"""Section summary rules, with expected values worked out by hand.

Severities match the model's taxonomy: Sanitation 3, Obstruction 3, Vendor Identification 2, DressCode 1.
Times are UTC; Manila is UTC+8.
"""

from datetime import datetime, timezone
import unittest

from recommendations import summarize_sections

TAXONOMY = {
    "Sanitation": {"name_en": "Sanitation", "name_tl": "Kalinisan", "severity": "3",
                   "action_template_en": "Inspect the affected stall."},
    "Obstruction": {"name_en": "Obstruction", "name_tl": "Harang", "severity": "3",
                    "action_template_en": "Clear the passage."},
    "Vendor Identification": {"name_en": "Vendor Identification", "name_tl": "Pagkakakilanlan ng Tindero",
                              "severity": "2", "action_template_en": "Verify vendor IDs."},
    "DressCode": {"name_en": "Dress Code", "name_tl": "Kasuotan", "severity": "1",
                  "action_template_en": "Remind vendors of the dress code."},
}


def utc(day, hour, minute=0):
    return datetime(2026, 11, day, hour, minute, tzinfo=timezone.utc)


class Records:
    def __init__(self):
        self.records, self.findings = [], {}

    def add(self, section, kind, issued_at, *codes):
        record_id = len(self.records) + 1
        self.records.append({"id": record_id, "section_id": section, "type": kind, "issued_at": issued_at})
        self.findings[record_id] = set(codes)
        return self

    def summarize(self):
        return summarize_sections(self.records, self.findings, TAXONOMY)


def hours(**counts):
    values = [0] * 24
    for name, count in counts.items():
        values[int(name[1:])] = count
    return values


class SummarizeSectionsTests(unittest.TestCase):
    def test_one_record_of_a_category_gives_no_recommendation(self):
        data = (Records().add(1, "Ticket", utc(1, 1), "Sanitation")
                .add(1, "Ticket", utc(2, 1)).add(1, "Ticket", utc(3, 1)).add(1, "Ticket", utc(4, 1)))
        self.assertEqual(data.summarize(), [])

    def test_full_card_for_one_section(self):
        # Sanitation: 2 tickets (3 each) + 1 warning (half of 3) = 7.5 -> Low. 4 records -> Low confidence.
        # Manila hours 9, 10, 9 -> best 3-hour window 08:00 (8,9,10 = 3; ties with 09:00, earliest wins).
        data = (Records()
                .add(1, "Ticket", utc(1, 1, 30), "Sanitation")
                .add(1, "Ticket", utc(2, 2, 10), "Sanitation")
                .add(1, "Warning", utc(3, 1), "Sanitation")
                .add(1, "Ticket", utc(4, 5)))
        self.assertEqual(data.summarize(), [{
            "section_id": 1,
            "category_code": "Sanitation",
            "category_name_english": "Sanitation",
            "category_name_filipino": "Kalinisan",
            "recommended_action": "Inspect the affected stall.",
            "category_record_count": 3,
            "section_record_count": 4,
            "risk_score": 7.5,
            "risk_level": "Low",
            "pattern_confidence": "Low",
            "peak_start_hour": 8,
            "hourly_counts": hours(h9=2, h10=1),
            "last_flagged_at": utc(3, 1),
        }])

    def test_risk_levels_at_their_cut_offs_and_highest_risk_first(self):
        # Section 2: Sanitation 3 + 3 + 1.5 (warning) + DressCode 0.5 (warning) = 8.0 -> Moderate.
        # Section 3: Sanitation 4 tickets = 12 + Vendor Identification 1 ticket = 2 -> 14.0 -> High.
        data = Records()
        for kind in ("Ticket", "Ticket", "Warning"):
            data.add(2, kind, utc(5, 3), "Sanitation")
        data.add(2, "Warning", utc(5, 4), "DressCode")
        for _ in range(4):
            data.add(3, "Ticket", utc(6, 3), "Sanitation")
        data.add(3, "Ticket", utc(6, 4), "Vendor Identification")
        # Section 9: Sanitation 4 tickets = 12 + 1 warning = 1.5 -> 13.5, just below High -> Moderate.
        for kind in ("Ticket", "Ticket", "Ticket", "Ticket", "Warning"):
            data.add(9, kind, utc(6, 5), "Sanitation")
        result = data.summarize()
        self.assertEqual([(r["section_id"], r["risk_score"], r["risk_level"]) for r in result],
                         [(3, 14.0, "High"), (9, 13.5, "Moderate"), (2, 8.0, "Moderate")])

    def test_main_category_needs_two_records_and_the_biggest_weight(self):
        # Sanitation: 1 ticket (weight 3) is left out by the 2-record rule.
        # DressCode: 3 tickets = 3.0. Vendor Identification: 2 warnings = 2.0. DressCode wins.
        # Risk counts every finding: 3 + 3 + 2 = 8.0 -> Moderate.
        data = Records().add(4, "Ticket", utc(7, 2), "Sanitation")
        for _ in range(3):
            data.add(4, "Ticket", utc(7, 2), "DressCode")
        for _ in range(2):
            data.add(4, "Warning", utc(7, 2), "Vendor Identification")
        [card] = data.summarize()
        self.assertEqual((card["category_code"], card["category_record_count"], card["section_record_count"],
                          card["risk_score"], card["risk_level"]), ("DressCode", 3, 6, 8.0, "Moderate"))

    def test_confidence_cut_offs(self):
        # Two Sanitation tickets plus clean records: 4 -> Low, 5 and 7 -> Moderate, 8 -> High.
        expected = {4: "Low", 5: "Moderate", 7: "Moderate", 8: "High"}
        for total, level in expected.items():
            data = Records().add(5, "Ticket", utc(8, 2), "Sanitation").add(5, "Ticket", utc(8, 2), "Sanitation")
            for _ in range(total - 2):
                data.add(5, "Ticket", utc(8, 2))
            [card] = data.summarize()
            self.assertEqual((card["section_record_count"], card["pattern_confidence"]), (total, level))

    def test_record_with_two_categories_counts_for_both_but_once_per_hour(self):
        # Manila 23:00 (both categories), 00:30 and 01:00 next day -> hours 23, 0, 1.
        # Window starting 23:00 covers all three and wraps past midnight.
        # Sanitation 2 tickets = 6, Obstruction 2 tickets = 6: tie on weight and count; the model breaks
        # ties by the later name, Sanitation. Risk 12 -> Moderate. Last flagged = 17:00 UTC on the 9th.
        data = (Records()
                .add(6, "Ticket", utc(9, 15), "Sanitation", "Obstruction")
                .add(6, "Ticket", utc(9, 16, 30), "Sanitation")
                .add(6, "Ticket", utc(9, 17), "Obstruction"))
        [card] = data.summarize()
        self.assertEqual((card["category_code"], card["category_record_count"], card["risk_score"],
                          card["peak_start_hour"], card["hourly_counts"], card["last_flagged_at"]),
                         ("Sanitation", 2, 12.0, 23, hours(h23=1, h0=1, h1=1), utc(9, 17)))

    def test_sections_are_summarized_separately(self):
        # One Sanitation ticket in each of two sections: neither reaches 2 in its own section.
        data = Records().add(7, "Ticket", utc(10, 2), "Sanitation").add(8, "Ticket", utc(10, 2), "Sanitation")
        self.assertEqual(data.summarize(), [])


if __name__ == "__main__":
    unittest.main()
