"""One recommendation run.

Reads every warning and ticket issued in the last 30 days, runs the frozen final model
(v4) on each description, and saves the findings and section recommendations in one
transaction. Warnings and tickets are only read. If anything fails, nothing is saved.

Settings come from the environment:
  MODEL_DIR   the delivered model folder ("description-model/New Training Model").
  PGHOST, PGPORT, PGDATABASE, PGUSER, PGPASSWORD   the standard PostgreSQL settings.

Run it with the model's own Python and -B, so nothing is written inside the locked model
folder:  python -B run.py
"""

import csv
from datetime import datetime, timedelta, timezone
import importlib.util
import os
from pathlib import Path
import sys

import psycopg

from recommendations import summarize_sections

WINDOW = timedelta(days=30)


def load_model(model_dir):
    """Load the model the same way its own grading tool does, after the same self-check."""
    sys.dont_write_bytecode = True
    frozen = Path(model_dir) / "evaluation" / "frozen-final-v4"
    spec = importlib.util.spec_from_file_location("frozen_evaluate", frozen / "evaluate.py")
    evaluate = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(evaluate)
    manifest = evaluate.verify_snapshot()

    sys.path.insert(0, str(evaluate.SCRIPTS))
    from evaluate_targeted_v4 import CHECKS, PilotReplay, normalize, with_targeted_v4

    if list(CHECKS) != [addon["id"] for addon in manifest["enabled_add_ons"]]:
        raise ValueError("Frozen add-on order differs from the manifest")
    pilot = PilotReplay()
    if pilot.verifier.cutoff != manifest["global_verifier_cutoff"]:
        raise ValueError("Frozen verifier cutoff differs from the manifest")

    def classify(descriptions):
        baseline = pilot.predict(descriptions)
        return [with_targeted_v4(text, codes, normalize)[0]
                for text, codes in zip(descriptions, baseline, strict=True)]

    with (evaluate.SCRIPTS.parent / "config" / "taxonomy.csv").open(encoding="utf-8", newline="") as file:
        taxonomy = {row["code"]: row for row in csv.DictReader(file)}
    return manifest["version"], classify, taxonomy


def read_records(conn, window_start, window_end):
    rows = conn.execute(
        """SELECT id, market_section_id, type, description, issued_at FROM tickets
           WHERE issued_at >= %s AND issued_at <= %s ORDER BY id""",
        (window_start, window_end)).fetchall()
    return [{"id": row[0], "section_id": row[1], "type": row[2], "description": row[3], "issued_at": row[4]}
            for row in rows]


def save(conn, run, findings, cards):
    with conn.transaction():
        run_id = conn.execute(
            """INSERT INTO recommendation_runs
               (started_at, finished_at, window_start, window_end, model_version, record_count)
               VALUES (%s, %s, %s, %s, %s, %s) RETURNING id""",
            (run["started_at"], datetime.now(timezone.utc), run["window_start"], run["window_end"],
             run["model_version"], run["record_count"])).fetchone()[0]
        with conn.cursor() as cursor:
            cursor.executemany(
                "INSERT INTO recommendation_findings (recommendation_run_id, ticket_id, category_code) VALUES (%s, %s, %s)",
                [(run_id, record_id, code) for record_id, codes in findings.items() for code in sorted(codes)])
            cursor.executemany(
                """INSERT INTO section_recommendations
                   (recommendation_run_id, market_section_id, category_code, category_name_english,
                    category_name_filipino, recommended_action, category_record_count, section_record_count,
                    risk_score, risk_level, pattern_confidence, peak_start_hour, hourly_counts, last_flagged_at)
                   VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)""",
                [(run_id, card["section_id"], card["category_code"], card["category_name_english"],
                  card["category_name_filipino"], card["recommended_action"], card["category_record_count"],
                  card["section_record_count"], card["risk_score"], card["risk_level"],
                  card["pattern_confidence"], card["peak_start_hour"], card["hourly_counts"],
                  card["last_flagged_at"]) for card in cards])
    return run_id


def main():
    started_at = datetime.now(timezone.utc)
    window_start = started_at - WINDOW
    model_version, classify, taxonomy = load_model(os.environ["MODEL_DIR"])
    with psycopg.connect() as conn:
        records = read_records(conn, window_start, started_at)
        conn.commit()
        descriptions = [record["description"] for record in records]
        found = classify(descriptions) if descriptions else []
        findings = {record["id"]: codes for record, codes in zip(records, found, strict=True) if codes}
        cards = summarize_sections(records, findings, taxonomy)
        run = {"started_at": started_at, "window_start": window_start, "window_end": started_at,
               "model_version": model_version, "record_count": len(records)}
        run_id = save(conn, run, findings, cards)
    print(f"Run {run_id}: {len(records)} records, {len(findings)} with findings, "
          f"{len(cards)} section recommendations.")


if __name__ == "__main__":
    main()
