# LabCore

LabCore 是一个面向课程学习与在线实验的学习平台。当前版本包含学习卡片、内容分类、后台内容管理、Notebook 模板管理，以及基于 JupyterLite 的在线练习入口。

## 当前版本重点

- 学习卡片支持按分类筛选，智能体内容归入独立分类。
- 学习卡片简介在首页做两行省略，避免卡片高度不一致。
- 后台支持 Notebook 模板管理，可为学习卡片上传或替换 `.ipynb` 模板。
- 在线练习使用 JupyterLite 打开学习卡片对应的 Notebook 模板。
- 实验页支持恢复默认模板，会重新从服务端模板覆盖用户本地浏览器中的旧副本。
- 新增 5 个智能体实验模板，覆盖日程规划、工具调用、对话记忆、代码沙箱、多智能体协作等主题。

## 技术栈

- 后端：Spring Boot 2.7、Java 8、MyBatis-Plus、MySQL
- 前端：Vue 3、Vite、Element Plus、Pinia
- 在线实验：JupyterLite / Pyodide

## 目录说明

```text
src/main/java/                         后端源码
src/main/resources/db/labcore.sql       数据库初始化脚本
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
/opt/learning-platform/mysql/bin/mysql -uroot -p123456 -h127.0.0.1 -P3306 labcore < import_learning_cards.preview.sql
```

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
