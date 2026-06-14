#!/usr/bin/env python3
"""Import learning-card JSON files into LabCore MySQL tables.

Usage examples:
  python3 import_learning_cards.py --json-dir ./juypter --output import_learning_cards.sql
  python3 import_learning_cards.py --json-dir ./juypter --db-name labcore_init_test --db-user root --db-password '***' --apply
"""

import argparse
import datetime as dt
import json
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile
import zlib


DIFFICULTY_MAP = {
    "入门": "简单",
    "简单": "简单",
    "中等": "中等",
    "中等偏难": "高级",
    "困难": "高级",
    "极难": "高级",
    "进阶": "高级",
    "高级": "高级",
}


def sql_quote(value):
    if value is None:
        return "NULL"
    if isinstance(value, (dict, list)):
        value = json.dumps(value, ensure_ascii=False)
    else:
        value = str(value)
    value = (
        value.replace("\\", "\\\\")
        .replace("\0", "\\0")
        .replace("\n", "\\n")
        .replace("\r", "\\r")
        .replace("\x1a", "\\Z")
        .replace("'", "''")
    )
    return "'" + value + "'"


def stable_json_id(title):
    checksum = zlib.crc32(title.encode("utf-8")) & 0xFFFFFFFF
    return 900000000 + checksum % 100000000


def normalize_card(raw, force_category):
    title = (raw.get("title") or "").strip()
    if not title:
        raise ValueError("JSON card is missing title")

    difficulty = (raw.get("difficulty") or "").strip()
    return {
        "json_id": int(raw.get("jsonId") or raw.get("json_id") or stable_json_id(title)),
        "title": title,
        "summary": raw.get("summary") or "",
        "category": force_category or raw.get("category") or "未分类",
        "difficulty": DIFFICULTY_MAP.get(difficulty, difficulty or "中等"),
        "duration": raw.get("duration") or "",
        "prerequisites": raw.get("prerequisites") or "",
        "objectives": raw.get("objectives") or [],
        "features": raw.get("features") or [],
        "steps": sorted(raw.get("steps") or [], key=lambda s: int(s.get("stepNo") or s.get("step_no") or 0)),
    }


def load_cards(json_dir):
    base = pathlib.Path(json_dir)
    if not base.exists():
        raise FileNotFoundError(f"JSON directory not found: {base}")
    files = sorted(base.glob("*.json"))
    if not files:
        raise FileNotFoundError(f"No .json files found in: {base}")

    cards = []
    for path in files:
        with path.open("r", encoding="utf-8") as fh:
            data = json.load(fh)
        if isinstance(data, list):
            for item in data:
                cards.append((path.name, item))
        elif isinstance(data, dict):
            cards.append((path.name, data))
        else:
            raise ValueError(f"Unsupported JSON root in {path}: {type(data).__name__}")
    return cards


def build_sql(cards, force_category="智能体", backup=True):
    timestamp = dt.datetime.now().strftime("%Y%m%d%H%M%S")
    lines = [
        "SET NAMES utf8mb4;",
        "SET FOREIGN_KEY_CHECKS = 1;",
    ]
    if backup:
        lines.extend(
            [
                f"CREATE TABLE IF NOT EXISTS learning_item_backup_{timestamp} AS SELECT * FROM learning_item;",
                f"CREATE TABLE IF NOT EXISTS learning_step_backup_{timestamp} AS SELECT * FROM learning_step;",
            ]
        )
    lines.append("START TRANSACTION;")

    normalized = []
    for source_name, raw in cards:
        card = normalize_card(raw, force_category)
        normalized.append((source_name, card))

        lines.append(f"-- {source_name}: {card['title']}")
        lines.append(
            "SET @item_pk := (SELECT item_pk FROM learning_item "
            f"WHERE title = {sql_quote(card['title'])} LIMIT 1);"
        )
        lines.append(
            "INSERT INTO learning_item "
            "(json_id, title, summary, category, difficulty, duration, prerequisites, objectives, features, "
            "status, template_path, author_id, published_at, created_at, updated_at) "
            "SELECT "
            f"{card['json_id']}, {sql_quote(card['title'])}, {sql_quote(card['summary'])}, "
            f"{sql_quote(card['category'])}, {sql_quote(card['difficulty'])}, {sql_quote(card['duration'])}, "
            f"{sql_quote(card['prerequisites'])}, CAST({sql_quote(card['objectives'])} AS JSON), "
            f"CAST({sql_quote(card['features'])} AS JSON), 'PUBLISHED', NULL, NULL, NOW(), NOW(), NOW() "
            "WHERE @item_pk IS NULL;"
        )
        lines.append("SET @item_pk := COALESCE(@item_pk, LAST_INSERT_ID());")
        lines.append(
            "UPDATE learning_item SET "
            f"json_id = {card['json_id']}, "
            f"summary = {sql_quote(card['summary'])}, "
            f"category = {sql_quote(card['category'])}, "
            f"difficulty = {sql_quote(card['difficulty'])}, "
            f"duration = {sql_quote(card['duration'])}, "
            f"prerequisites = {sql_quote(card['prerequisites'])}, "
            f"objectives = CAST({sql_quote(card['objectives'])} AS JSON), "
            f"features = CAST({sql_quote(card['features'])} AS JSON), "
            "status = 'PUBLISHED', "
            "published_at = COALESCE(published_at, NOW()), "
            "updated_at = NOW() "
            "WHERE item_pk = @item_pk;"
        )
        lines.append("DELETE FROM learning_step WHERE item_pk = @item_pk;")

        for index, step in enumerate(card["steps"], start=1):
            step_no = int(step.get("stepNo") or step.get("step_no") or index)
            lines.append(
                "INSERT INTO learning_step (item_pk, step_no, title, description, tip, code) VALUES "
                f"(@item_pk, {step_no}, {sql_quote(step.get('title') or '')}, "
                f"{sql_quote(step.get('description') or '')}, {sql_quote(step.get('tip'))}, "
                f"{sql_quote(step.get('code'))});"
            )

    lines.extend(
        [
            "COMMIT;",
            "SELECT category, COUNT(*) AS item_count FROM learning_item GROUP BY category ORDER BY item_count DESC, category;",
            "SELECT difficulty, COUNT(*) AS item_count FROM learning_item GROUP BY difficulty ORDER BY item_count DESC, difficulty;",
        ]
    )
    return "\n".join(lines) + "\n", normalized


def run_mysql(sql_path, args):
    mysql_bin = shutil.which("mysql")
    if not mysql_bin:
        raise RuntimeError("mysql command not found. Use --output and import the SQL file in your DB web console.")

    cmd = [
        mysql_bin,
        f"--host={args.db_host}",
        f"--port={args.db_port}",
        f"--user={args.db_user}",
        "--default-character-set=utf8mb4",
        args.db_name,
    ]
    env = os.environ.copy()
    if args.db_password:
        env["MYSQL_PWD"] = args.db_password

    with open(sql_path, "rb") as fh:
        subprocess.run(cmd, stdin=fh, env=env, check=True)


def main():
    parser = argparse.ArgumentParser(description="Import LabCore learning-card JSON files.")
    parser.add_argument("--json-dir", required=True, help="Directory containing learning-card *.json files")
    parser.add_argument("--category", default="智能体", help="Category written to all imported cards")
    parser.add_argument("--output", default="import_learning_cards.sql", help="SQL output path")
    parser.add_argument("--no-backup", action="store_true", help="Do not create backup tables before import")
    parser.add_argument("--apply", action="store_true", help="Apply SQL through local mysql command")
    parser.add_argument("--db-host", default="127.0.0.1")
    parser.add_argument("--db-port", default="3306")
    parser.add_argument("--db-name", default="labcore_init_test")
    parser.add_argument("--db-user", default="root")
    parser.add_argument("--db-password", default="")
    args = parser.parse_args()

    raw_cards = load_cards(args.json_dir)
    sql, cards = build_sql(raw_cards, force_category=args.category, backup=not args.no_backup)

    output = pathlib.Path(args.output)
    output.write_text(sql, encoding="utf-8", newline="\n")

    print(f"Prepared {len(cards)} learning cards from {args.json_dir}")
    for source_name, card in cards:
        print(f"- {source_name}: {card['title']} | {card['category']} | {card['difficulty']} | steps={len(card['steps'])}")
    print(f"SQL written to: {output.resolve()}")

    if args.apply:
        with tempfile.NamedTemporaryFile("w", encoding="utf-8", suffix=".sql", delete=False) as tmp:
            tmp.write(sql)
            tmp_path = tmp.name
        try:
            run_mysql(tmp_path, args)
            print("Import completed.")
        finally:
            try:
                os.remove(tmp_path)
            except OSError:
                pass
    else:
        print("Dry run only. Add --apply to import through mysql, or import the SQL file in your DB console.")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(1)
