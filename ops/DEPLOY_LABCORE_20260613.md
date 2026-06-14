# LabCore 2026-06-13 deployment notes

Upload package:

- `labcore-hotfix-20260613.zip`

Suggested server upload directory:

- `/root/upload`

## 1. Deploy code

```bash
cd /root/upload
unzip -o labcore-hotfix-20260613.zip -d labcore-hotfix-20260613
cd labcore-hotfix-20260613
chmod +x deploy-update.sh
bash deploy-update.sh /opt/learning-platform > /root/upload/deploy-result-20260613.txt 2>&1
```

If the deployment directory is not `/opt/learning-platform`, replace it with the real path.

The script backs up the current jar, frontend dist, and application.properties before replacement.

## 2. Import learning-card JSON data

If the server has `python3` and `mysql` command:

```bash
cd /root/upload/labcore-hotfix-20260613/import-data
chmod +x run_import_learning_cards.sh
bash run_import_learning_cards.sh > /root/upload/import-learning-cards-20260613.txt 2>&1
```

Before running, edit `run_import_learning_cards.sh` if production DB config differs:

- `DB_HOST`
- `DB_PORT`
- `DB_NAME`
- `DB_USER`
- `DB_PASSWORD`

If the server does not have the `mysql` command, generate SQL instead:

```bash
cd /root/upload/labcore-hotfix-20260613/import-data
python3 import_learning_cards.py --json-dir ./juypter --output import_learning_cards.sql
```

Then import `import_learning_cards.sql` through the DB web console.

## 3. Verify

Open:

- `https://labcore.henu.edu.cn/`

Check:

- Login works.
- Knowledge center opens.
- Category dropdown contains `智能体`.
- Selecting `智能体` shows 5 cards.
- Card summaries display at most two lines.
