# LabCore 2026-06-14 deployment notes

Upload package:

- `labcore-hotfix-20260614.zip`

Suggested server upload directory:

- `/root/upload`

## 1. Deploy code and templates

```bash
cd /root/upload
unzip -o labcore-hotfix-20260614.zip -d labcore-hotfix-20260614
cd labcore-hotfix-20260614
chmod +x deploy-update.sh
bash deploy-update.sh /opt/learning-platform > /root/upload/deploy-result-20260614.txt 2>&1
```

If you really need to overwrite server-side templates:

```bash
ALLOW_DATA_OVERWRITE=1 bash deploy-update.sh /opt/learning-platform > /root/upload/deploy-result-20260614.txt 2>&1
```

If the deployment directory is not `/opt/learning-platform`, replace it with the real path.

The script always backs up the current jar, frontend dist, and `application.properties`.

For `data/learning-templates`:

- default behavior: skip overwrite
- overwrite only when `ALLOW_DATA_OVERWRITE=1` is set, or when you confirm in an interactive shell
- existing server templates are backed up before replacement

## 2. Verify

Open:

- `https://labcore.henu.edu.cn/`

Check:

- Login works.
- Knowledge center opens.
- Category dropdown contains `智能体`.
- Selecting `智能体` shows 5 cards.
- Click a card and enter online practice.
- The notebook opens without `Resource not found`.
- The toolbar shows `恢复默认模板`.
- After editing a notebook, clicking `恢复默认模板` reloads the default uploaded template.
- Admin content page shows `模板管理`, template status, template path, and replacement upload.

## 3. MySQL note for handoff

Bundled MySQL client path:

```bash
/opt/learning-platform/mysql/bin/mysql
```

Connection command:

```bash
/opt/learning-platform/mysql/bin/mysql -uroot -p123456 -h127.0.0.1 -P3306 labcore
```
