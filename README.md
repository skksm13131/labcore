# LabCore

LabCore 是一个面向课程学习与在线实验的学习平台。当前版本包含学习卡片、内容分类、后台内容管理、Notebook 模板管理，以及基于 JupyterLite 的在线练习入口。

## 当前版本重点

- 学习卡片支持按分类筛选，智能体内容归入独立分类。
- 学习卡片简介在首页做两行省略，避免卡片高度不一致。
- 后台支持 Notebook 模板管理，可为学习卡片上传或替换 `.ipynb` 模板。
- 在线练习使用 JupyterLite 打开学习卡片对应的 Notebook 模板。
- 实验页支持恢复默认模板，会重新从服务端模板覆盖用户本地浏览器中的旧副本。
- 新增 5 个智能体实验模板，覆盖日程规划、工具调用、对话记忆、代码沙箱、多智能体协作等主题。
- 新增作业提交模块：学生可上传文档/视频，管理员可查看、下载、评分和退回。

## 技术栈

- 后端：Spring Boot 2.7、Java 8、MyBatis-Plus、MySQL
- 前端：Vue 3、Vite、Element Plus、Pinia
- 在线实验：JupyterLite / Pyodide

## 目录说明

```text
src/main/java/                         后端源码
src/main/resources/db/labcore_full_init.sql    推荐使用的完整初始化/安全补丁脚本
src/main/resources/db/labcore_schema_clean.sql 干净建表脚本，不包含学习卡片种子数据
src/main/resources/db/assignment_module.sql    作业模块独立建表脚本
src/main/resources/db/labcore.sql              历史旧数据 dump，不建议作为新部署首选
src/main/resources/static/lite/         JupyterLite 静态运行环境
src/main/resources/static/experiments/  打包进后端静态资源的 Notebook 示例/备用资源
data/learning-templates/                学习卡片绑定的 Notebook 模板目录
web-study-1.0.1/package/                前端 Vue/Vite 项目
ops/                                    部署脚本、导入脚本和部署说明
```

### Notebook 模板来源

当前版本主要以 `data/learning-templates/` 作为学习卡片在线练习模板来源。

示例：

```text
data/learning-templates/item-53/template.ipynb
data/learning-templates/item-54/template.ipynb
```

这里的 `item-53` 对应数据库中的学习卡片 ID。后台上传模板后，系统会保存为类似 `item-{id}/template.ipynb` 的结构，并在数据库中记录模板路径。

`src/main/resources/static/experiments/` 是项目内置的静态 Notebook 示例或备用资源。它会随后端 jar 一起打包，但不建议同时维护两套不同内容的模板，避免“在线学习”和“在线练习”入口指向不一致。

## 本地配置

复制配置模板：

```powershell
Copy-Item src\main\resources\application.properties.example src\main\resources\application.properties
```

然后修改 `application.properties` 中的数据库连接、账号密码和 token secret。

关键配置：

```properties
spring.datasource.url=jdbc:mysql://localhost:3306/labcore?useUnicode=true&characterEncoding=utf8&useSSL=false&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true
spring.datasource.username=CHANGE_ME
spring.datasource.password=CHANGE_ME
labcore.learning.template-storage-dir=data/learning-templates
labcore.auth.access-token-secret=CHANGE_ME_TO_A_LONG_RANDOM_SECRET
```

## 本地启动

后端：

```powershell
mvn spring-boot:run
```

前端：

```powershell
cd web-study-1.0.1\package
npm install
npm run dev -- --host 127.0.0.1 --port 5173
```

默认访问：

```text
前端：http://127.0.0.1:5173
后端：http://127.0.0.1:8080
```

## 构建

前端构建：

```powershell
cd web-study-1.0.1\package
npm run build
```

后端构建：

```powershell
mvn -DskipTests package
```

## 部署说明

堡垒机环境不能联网时，优先在本地完成前端和后端构建，再上传打包产物。当前仓库保留了部署脚本和说明：

```text
ops/labcore-codeonly-20260614/README_DEPLOY.md
ops/labcore-codeonly-20260614/deploy-codeonly.sh
ops/labcore-hotfix-20260614/README_DEPLOY.md
ops/labcore-hotfix-20260614/deploy-update.sh
```

如果线上已经通过后台手动上传 Notebook 模板，部署时优先使用 code-only 方式，避免覆盖线上 `data/learning-templates/` 中已经调整过的模板。

线上 MySQL 如果使用项目内置目录，常见位置为：

```text
/opt/learning-platform/mysql/bin/mysql
```

示例命令：

```bash
/opt/learning-platform/mysql/bin/mysql -uroot -p -h127.0.0.1 -P3306
```

具体数据库名以线上 `SHOW DATABASES;` 和部署配置为准。

## 数据导入

学习卡片导入脚本位于：

```text
ops/import_learning_cards.py
ops/run_import_learning_cards.sh
ops/import_learning_cards.preview.sql
```

在堡垒机离线环境中，如果系统没有 `mysql` 命令，需要使用内置 MySQL 客户端的完整路径，例如：

```bash
/opt/learning-platform/mysql/bin/mysql -uroot -p -h127.0.0.1 -P3306 labcore < import_learning_cards.preview.sql
```

## 能力考核模块

能力考核模块入口：

```text
学生端：能力考核
管理员端：头像菜单 -> 考核管理
```

新增表结构保存在：

```text
src/main/resources/db/assignment_module.sql
```

数据库初始化或补丁升级可以分文件执行，推荐顺序：

```bash
# 1. 如果是全新空库，先建基础表；已有 labcore 旧库可以跳过这一步
mysql -uroot -p < src/main/resources/db/labcore_schema_clean.sql

# 2. 导入/更新 5 张智能体学习卡片及完整学习步骤
mysql -uroot -p < ops/import_learning_cards.preview.sql

# 3. 新增本次作业提交模块表
mysql -uroot -p < src/main/resources/db/assignment_module.sql
```

`ops/import_learning_cards.preview.sql` 会创建/使用 `labcore` 数据库，并写入 5 张智能体学习卡片、完整学习步骤和模板路径：

```text
53 Prompt Engineering — 大模型 API 调用与提示词设计
54 Tool Use — 让智能体具备外部工具调用能力
55 Memory — 让智能体记住对话上下文
56 Code Sandbox — 让智能体自己写代码、自己执行
57 Multi-Agent — 多智能体分工协作系统
```

对应 Notebook 模板路径为 `data/learning-templates/item-53/template.ipynb` 到 `item-57/template.ipynb`。

`src/main/resources/db/labcore_full_init.sql` 也保留为一体化脚本，内容等价于基础表 + 智能体卡片 + 作业表 + 默认管理员，适合需要一次性初始化时使用。

历史 `src/main/resources/db/labcore.sql` 是旧数据 dump，包含学习卡片历史数据。当前验证发现其中部分旧 INSERT 内容存在乱码/引号损坏，不建议作为全新部署的第一选择。

## Git 版本管理

当前仓库地址：

```text
https://github.com/skksm13131/labcore.git
```

建议每次完成一轮可运行版本后提交并推送：

```powershell
git status
git add .
git commit -m "Describe current change"
git push origin master
```

部署压缩包、jar、前端 dist、缓存目录和 Python 编译缓存已通过 `.gitignore` 排除，不应提交到仓库。
## 2026-06-23 配置与部署补充

- `src/main/resources/application.properties` 和 `application.properties.example` 现在都支持环境变量覆盖。常用变量包括：
  `LABCORE_DB_URL`、`LABCORE_DB_USERNAME`、`LABCORE_DB_PASSWORD`、`LABCORE_TOKEN_SECRET`、
  `LABCORE_CORS_ALLOWED_ORIGINS`、`LABCORE_ASSIGNMENT_MAX_FILES_PER_SUBMISSION`、
  `LABCORE_ASSIGNMENT_MAX_BYTES_PER_SUBMISSION`。
- `src/main/resources/application.properties` 中的 `123456` 仅用于本地或内网测试默认值，不应直接用于正式教学服务器。
- 默认管理员密码 `Admin@12345678` 仅用于初始化。首次部署后必须立即登录后台修改密码。
- 作业上传新增两项限制，默认值为：
  `labcore.assignment.max-files-per-submission=5`
  `labcore.assignment.max-bytes-per-submission=1073741824`
  即每个学生在单个考核下最多 5 个附件、总大小 1GB。
- 后端 CORS 地址已改为配置项 `labcore.cors.allowed-origins`，内网部署时直接按逗号分隔填写实际地址即可。
- `ops/labcore-codeonly-20260614/deploy-codeonly.sh` 仍然是默认推荐方式，不会覆盖 `data/`。
- `ops/labcore-hotfix-20260614/deploy-update.sh` 在检测到包内含 `data/learning-templates` 时，默认跳过覆盖。
  只有显式设置 `ALLOW_DATA_OVERWRITE=1`，或在交互终端中确认后，才会覆盖模板目录，并且会先备份现有模板目录。
