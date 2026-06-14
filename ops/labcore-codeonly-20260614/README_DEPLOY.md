# LabCore code-only deploy package 2026-06-14

This package updates only:

- backend jar
- frontend dist

It intentionally does not copy `data/learning-templates`, so notebooks uploaded through the admin page on the server are preserved.

Deploy:

```bash
cd /root/upload
unzip -o labcore-codeonly-20260614.zip -d labcore-codeonly-20260614
cd labcore-codeonly-20260614
chmod +x deploy-codeonly.sh
bash deploy-codeonly.sh /opt/learning-platform > /root/upload/deploy-codeonly-20260614.txt 2>&1
```

Verify:

- Online practice opens the correct notebook.
- `恢复默认模板` is visible in the experiment toolbar.
- Admin page has `模板管理`.

If old notebook content still appears, use `恢复默认模板` once, or clear JupyterLite site data for the domain.
