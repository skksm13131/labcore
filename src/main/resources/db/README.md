# LabCore database scripts

Use `schema.sql` as the canonical table definition for a fresh database:

```bash
mysql -uroot -p -e "CREATE DATABASE IF NOT EXISTS labcore DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_unicode_ci"
mysql -uroot -p labcore < src/main/resources/db/schema.sql
```

Recommended local seed order:

```bash
mysql -uroot -p labcore < src/main/resources/db/schema.sql
mysql -uroot -p labcore < ops/import_learning_cards.preview.sql
mysql -uroot -p labcore < src/main/resources/db/seed_assessment_demo.sql
```

`seed_assessment_demo.sql` creates a local `admin` account only when one does not already exist. The default password is `Admin@12345678`.

File roles:

- `schema.sql`: canonical schema only, no data, no hard-coded database name.
- `assignment_module.sql`: assessment-module-only schema for older deployment scripts.
- `seed_assessment_demo.sql`: local UI demo data only. Do not run on production unless demo records are intended.
- `migrations/`: one-off upgrade patches for older databases.
- `snapshots/`: full database exports for recovery or inspection. These may contain users, password hashes, refresh tokens, and historical records.
Full snapshots are not canonical initialization scripts. Restore them only into a disposable or recovery database, and restore matching `data/assignment-materials` and `data/assignment-submissions` directories if attachment download behavior matters.
