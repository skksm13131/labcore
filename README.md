# LabCore

LabCore 是一个面向课程学习、在线实验和能力考核的学习平台。当前版本包含学习卡片、内容分类、后台内容管理、Notebook 模板管理、JupyterLite 在线练习，以及能力考核作业提交模块。

## 当前版本重点

- 学习卡片支持按分类筛选，智能体相关内容归入独立分类。
- 后台支持 Notebook 模板管理，可为学习卡片上传或替换 `.ipynb` 模板。
- 在线练习使用 JupyterLite 打开学习卡片对应的 Notebook 模板。
- 实验页支持恢复默认模板，会从服务端模板覆盖浏览器本地旧副本。
- 内置 5 个智能体实验模板，覆盖 Prompt Engineering、Tool Use、Memory、Code Sandbox、Multi-Agent。
- 能力考核模块支持学生提交文本答案、文档、视频等附件，管理员可查看、下载、评分和退回。

## 技术栈

- 后端：Spring Boot 2.7、Java 8、MyBatis-Plus、MySQL
- 前端：Vue 3、Vite、Element Plus、Pinia
- 在线实验：JupyterLite / Pyodide

## 目录说明

```text
src/main/java/                         后端源码
src/main/resources/application.properties
                                        本地后端配置
src/main/resources/db/schema.sql        当前推荐的完整建表基线，不包含种子数据
src/main/resources/db/assignment_module.sql
                                        能力考核模块独立建表脚本，供旧部署补表
src/main/resources/db/seed_assessment_demo.sql
                                        能力考核本地演示数据
src/main/resources/db/migrations/       增量迁移脚本
src/main/resources/db/snapshots/        数据库完整快照，仅用于恢复或核对
src/main/resources/static/lite/         JupyterLite 静态运行环境
src/main/resources/static/experiments/  打包进后端静态资源的 Notebook 示例或备用资源
data/learning-templates/                学习卡片绑定的 Notebook 模板目录
web-study-1.0.1/package/                前端 Vue/Vite 项目
ops/                                    部署脚本、导入脚本和部署说明
```

## 本地配置

后端配置文件位于：

```text
src/main/resources/application.properties
```

关键配置示例：

```properties
spring.datasource.url=jdbc:mysql://localhost:3306/labcore?useUnicode=true&characterEncoding=utf8&useSSL=false&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true
spring.datasource.username=root
spring.datasource.password=123456
labcore.learning.template-storage-dir=data/learning-templates
labcore.auth.access-token-secret=CHANGE_ME_TO_A_LONG_RANDOM_SECRET
```

时区相关配置：

```properties
spring.jackson.time-zone=Asia/Shanghai
```

后端启动类也会设置 JVM 默认时区为 `Asia/Shanghai`，数据库连接串中也包含 `serverTimezone=Asia/Shanghai`。

## 数据库初始化

推荐的新环境初始化顺序：

```powershell
mysql -uroot -p -e "CREATE DATABASE IF NOT EXISTS labcore DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_unicode_ci"
mysql -uroot -p labcore < src/main/resources/db/schema.sql
mysql -uroot -p labcore < ops/import_learning_cards.preview.sql
mysql -uroot -p labcore < src/main/resources/db/seed_assessment_demo.sql
```

说明：

- `schema.sql` 是当前推荐的完整建表基线。
- `ops/import_learning_cards.preview.sql` 导入 5 张智能体学习卡片、学习步骤和模板路径。
- `seed_assessment_demo.sql` 导入能力考核演示数据，供本地测试使用。
- `src/main/resources/db/snapshots/` 中是完整数据库快照，仅用于恢复或核对现有库，不建议作为标准初始化脚本。
- 快照可能包含真实用户、密码哈希、refresh token 和学习记录，外部环境使用前需要谨慎处理。

## 能力考核模块

入口：

```text
学生端：能力考核
管理员端：头像菜单 -> 考核管理
```

核心表：

```text
assignment                  考核任务
assignment_question         考核题目
assignment_submission       学生提交记录，包含 answer_text 文本答案
assignment_submission_file  学生提交附件
assignment_material         考核材料
```

能力考核模块独立建表脚本：

```text
src/main/resources/db/assignment_module.sql
```

旧环境如果只缺能力考核表，可以在备份数据库后单独执行该脚本。新环境优先使用 `schema.sql`。

## Notebook 模板

当前版本主要使用：

```text
data/learning-templates/
```

示例：

```text
data/learning-templates/item-53/template.ipynb
data/learning-templates/item-54/template.ipynb
```

这里的 `item-53` 对应数据库中的学习卡片 ID。后台上传模板后，系统会保存为类似 `item-{id}/template.ipynb` 的结构，并在数据库中记录模板路径。

`src/main/resources/static/experiments/` 是项目内置的静态 Notebook 示例或备用资源，会随后端 jar 一起打包。不建议同时维护两套不同内容的模板，避免在线学习和在线练习入口指向不一致。

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

默认访问地址：

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

堡垒机或离线环境不能联网时，优先在本地完成前端和后端构建，再上传打包产物。

如果线上已经通过后台手动上传 Notebook 模板，部署时优先使用 code-only 方式，避免覆盖线上 `data/learning-templates/` 中已经调整过的模板。

常见内置 MySQL 客户端位置：

```text
/opt/learning-platform/mysql/bin/mysql
```

示例命令：

```bash
/opt/learning-platform/mysql/bin/mysql -uroot -p -h127.0.0.1 -P3306
```

具体数据库名以线上 `SHOW DATABASES;` 和部署配置为准。

## 配置安全

- `root / 123456` 仅用于本地或内网测试，不应直接用于正式教学服务器。
- `labcore.auth.access-token-secret` 必须在正式环境改成足够长的随机密钥。
- 默认管理员密码仅用于初始化，首次部署后应立即登录后台修改。
- 作业上传限制可通过配置项调整：

```properties
labcore.assignment.max-files-per-submission=5
labcore.assignment.max-bytes-per-submission=1073741824
```

默认表示每个学生在单个考核下最多 5 个附件，总大小最多 1GB。

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

部署压缩包、jar、前端 `dist`、缓存目录和 Python 编译缓存应通过 `.gitignore` 排除，不应提交到仓库。
