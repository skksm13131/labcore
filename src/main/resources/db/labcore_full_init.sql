-- LabCore full database initialization and safe upgrade script.
-- Target database used by local development and the deployed server: labcore.
-- This script is intended to be runnable directly with mysql:
--   mysql -uroot -p < labcore_full_init.sql

CREATE DATABASE IF NOT EXISTS `labcore`
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE `labcore`;

CREATE TABLE IF NOT EXISTS `sys_user` (
  `user_id` bigint NOT NULL AUTO_INCREMENT,
  `username` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `display_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `real_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `grade` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `role` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'USER',
  `status` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'ACTIVE',
  `last_login_time` datetime DEFAULT NULL,
  `created_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `username` (`username`),
  KEY `idx_username` (`username`),
  KEY `idx_status` (`status`),
  KEY `idx_role` (`role`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `learning_item` (
  `item_pk` bigint NOT NULL AUTO_INCREMENT,
  `json_id` bigint NOT NULL,
  `title` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `summary` text COLLATE utf8mb4_unicode_ci,
  `category` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `difficulty` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `duration` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `prerequisites` text COLLATE utf8mb4_unicode_ci,
  `objectives` json DEFAULT NULL,
  `features` json DEFAULT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'PUBLISHED',
  `template_path` varchar(255) DEFAULT NULL,
  `author_id` bigint DEFAULT NULL,
  `published_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`item_pk`),
  KEY `idx_json_id` (`json_id`),
  KEY `idx_learning_status` (`status`),
  KEY `idx_learning_category` (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `learning_step` (
  `step_id` bigint NOT NULL AUTO_INCREMENT,
  `item_pk` bigint NOT NULL,
  `step_no` int NOT NULL DEFAULT 0,
  `title` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `tip` text COLLATE utf8mb4_unicode_ci,
  `code` longtext COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`step_id`),
  KEY `idx_step_item` (`item_pk`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `learning_record` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL,
  `item_pk` bigint NOT NULL,
  `first_learn_time` datetime DEFAULT NULL,
  `complete_time` datetime DEFAULT NULL,
  `complete_remark` text COLLATE utf8mb4_unicode_ci,
  `learn_duration_sec` bigint unsigned NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_item` (`user_id`, `item_pk`),
  KEY `idx_user` (`user_id`),
  KEY `idx_item` (`item_pk`),
  KEY `idx_complete_time` (`complete_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `refresh_tokens` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL,
  `token` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `expires_at` datetime NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `revoked_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `token` (`token`),
  KEY `idx_refresh_user` (`user_id`),
  KEY `idx_refresh_expires` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Safe upgrades for older labcore databases.
SET @schema_name := DATABASE();
SET @sql := (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `learning_item` ADD COLUMN `status` varchar(20) NOT NULL DEFAULT ''PUBLISHED''', 'SELECT 1') FROM information_schema.columns WHERE table_schema = @schema_name AND table_name = 'learning_item' AND column_name = 'status');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql := (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `learning_item` ADD COLUMN `template_path` varchar(255) DEFAULT NULL', 'SELECT 1') FROM information_schema.columns WHERE table_schema = @schema_name AND table_name = 'learning_item' AND column_name = 'template_path');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql := (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `learning_item` ADD COLUMN `author_id` bigint DEFAULT NULL', 'SELECT 1') FROM information_schema.columns WHERE table_schema = @schema_name AND table_name = 'learning_item' AND column_name = 'author_id');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql := (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `learning_item` ADD COLUMN `published_at` datetime DEFAULT NULL', 'SELECT 1') FROM information_schema.columns WHERE table_schema = @schema_name AND table_name = 'learning_item' AND column_name = 'published_at');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql := (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `learning_item` ADD COLUMN `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP', 'SELECT 1') FROM information_schema.columns WHERE table_schema = @schema_name AND table_name = 'learning_item' AND column_name = 'created_at');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql := (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `learning_item` ADD COLUMN `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP', 'SELECT 1') FROM information_schema.columns WHERE table_schema = @schema_name AND table_name = 'learning_item' AND column_name = 'updated_at');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql := (SELECT IF(COUNT(*) = 0, 'ALTER TABLE `learning_step` ADD COLUMN `step_no` int NOT NULL DEFAULT 0 AFTER `item_pk`', 'SELECT 1') FROM information_schema.columns WHERE table_schema = @schema_name AND table_name = 'learning_step' AND column_name = 'step_no');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

CREATE TABLE IF NOT EXISTS `assignment` (
  `assignment_id` bigint NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `category` varchar(100) DEFAULT NULL,
  `deadline` datetime DEFAULT NULL,
  `total_score` decimal(6,2) NOT NULL DEFAULT 100.00,
  `status` varchar(20) NOT NULL DEFAULT 'DRAFT',
  `created_by` bigint DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`assignment_id`),
  KEY `idx_assignment_status` (`status`),
  KEY `idx_assignment_deadline` (`deadline`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `assignment_question` (
  `question_id` bigint NOT NULL AUTO_INCREMENT,
  `assignment_id` bigint NOT NULL,
  `title` varchar(255) NOT NULL,
  `content` text DEFAULT NULL,
  `score` decimal(6,2) NOT NULL DEFAULT 0.00,
  `sort_order` int NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`question_id`),
  KEY `idx_assignment_question_assignment` (`assignment_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `assignment_submission` (
  `submission_id` bigint NOT NULL AUTO_INCREMENT,
  `assignment_id` bigint NOT NULL,
  `student_id` bigint NOT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'DRAFT',
  `answer_text` text DEFAULT NULL,
  `submitted_at` datetime DEFAULT NULL,
  `graded_at` datetime DEFAULT NULL,
  `score` decimal(6,2) DEFAULT NULL,
  `feedback` text DEFAULT NULL,
  `graded_by` bigint DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`submission_id`),
  UNIQUE KEY `uk_assignment_student` (`assignment_id`, `student_id`),
  KEY `idx_assignment_submission_assignment` (`assignment_id`),
  KEY `idx_assignment_submission_student` (`student_id`),
  KEY `idx_assignment_submission_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `assignment_submission_file` (
  `file_id` bigint NOT NULL AUTO_INCREMENT,
  `submission_id` bigint NOT NULL,
  `file_type` varchar(20) NOT NULL,
  `original_name` varchar(255) NOT NULL,
  `stored_path` varchar(500) NOT NULL,
  `mime_type` varchar(100) DEFAULT NULL,
  `file_size` bigint NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`file_id`),
  KEY `idx_assignment_file_submission` (`submission_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Default admin account: admin / Admin@12345678.
INSERT INTO `sys_user` (`username`, `password`, `display_name`, `role`, `status`, `created_time`, `updated_time`)
VALUES ('admin', '$2a$10$q/sC6nZS7QzHX.n6YAa3VeiXPXhIoAKopzHOPjoUH2A1HNJXc6DrS', '管理员', 'ADMIN', 'ACTIVE', NOW(), NOW())
ON DUPLICATE KEY UPDATE
  `password` = VALUES(`password`),
  `display_name` = '管理员',
  `role` = 'ADMIN',
  `status` = 'ACTIVE',
  `updated_time` = NOW();

-- Five agent learning cards generated from new_card/*.json.
-- Reserve the expected template-bound ids. The online practice templates use item-53..item-57.
-- learning-card-project1.json: Prompt Engineering — 大模型 API 调用与提示词设计
SET @existing_item_pk := (SELECT `item_pk` FROM `learning_item` WHERE `title` = 'Prompt Engineering — 大模型 API 调用与提示词设计' LIMIT 1);
DELETE FROM `learning_step` WHERE `item_pk` = @existing_item_pk AND @existing_item_pk IS NOT NULL AND @existing_item_pk <> 53;
DELETE FROM `learning_item` WHERE `item_pk` = @existing_item_pk AND @existing_item_pk IS NOT NULL AND @existing_item_pk <> 53;
INSERT INTO `learning_item` (`item_pk`, `json_id`, `title`, `summary`, `category`, `difficulty`, `duration`, `prerequisites`, `objectives`, `features`, `status`, `template_path`, `author_id`, `published_at`, `created_at`, `updated_at`) VALUES (53, 919911767, 'Prompt Engineering — 大模型 API 调用与提示词设计', '从 Transformer 架构与 token 的基本概念出发，系统讲解大语言模型的 API 调用方式。深入剖析 System Prompt 的设计方法论，涵盖 Zero-shot、Few-shot 等提示策略，掌握 temperature/top_p 等采样参数对输出行为的调控原理，最终实现用结构化提示词精确控制模型输出。', '智能体', '简单', '3小时', 'Python 基础语法（函数、字典、列表）、了解 HTTP 请求的基本概念', CAST('["理解 Transformer 架构中 token 的概念与文本 tokenize 的过程","掌握 chat completions 接口中各参数的含义、取值范围与调优方法","理解 system/user/assistant 三种消息角色的设计意图与协作机制","掌握 System Prompt 的四要素设计法与 Few-shot 提示技巧","能够设计提示词方案让模型稳定输出 JSON、Markdown 等结构化格式","理解 API 响应结构并实现基本的错误处理"]' AS JSON), CAST('[{"title":"Token 与 API 调用","description":"从 token 的基本概念出发，学习使用 OpenAI SDK 调用 DeepSeek API，理解请求与响应的完整数据结构。"},{"title":"消息角色与提示策略","description":"深入理解 system/user/assistant 三种角色的设计意图，掌握 Zero-shot、Few-shot、CoT 等提示策略的原理与适用场景。"},{"title":"输出控制与工程实践","description":"通过采样参数控制模型行为，学习 API 错误处理、环境变量管理等工程实践，构建可复用的调用基础设施。"}]' AS JSON), 'PUBLISHED', 'item-53/template.ipynb', NULL, NOW(), NOW(), NOW()) ON DUPLICATE KEY UPDATE `json_id` = VALUES(`json_id`), `title` = VALUES(`title`), `summary` = VALUES(`summary`), `category` = VALUES(`category`), `difficulty` = VALUES(`difficulty`), `duration` = VALUES(`duration`), `prerequisites` = VALUES(`prerequisites`), `objectives` = VALUES(`objectives`), `features` = VALUES(`features`), `status` = VALUES(`status`), `template_path` = VALUES(`template_path`), `published_at` = COALESCE(`published_at`, VALUES(`published_at`)), `updated_at` = NOW();
DELETE FROM `learning_step` WHERE `item_pk` = 53;
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (53, 1, '理解 Transformer 与 Token 的概念', '大语言模型（LLM）基于 Transformer 架构，其核心是自注意力机制（Self-Attention），能够捕捉序列中任意两个位置之间的依赖关系。模型在海量文本上训练后，学会了根据上文预测下一个 token 的概率分布。

Token 是模型处理文本的基本单位，不等于字也不等于词。对于英文，一个 token 大约是 3/4 个单词（如 ''hello'' 是 1 个 token，''unbelievable'' 是 4 个 token）。对于中文，一个汉字通常是 1-2 个 token。例如''你好世界''大约 4-5 个 token。理解 token 很重要，因为 API 的计费、上下文窗口限制、输出长度限制都以 token 为单位。

模型本身是''无状态''的——每次 API 调用都是独立的推理过程，模型不''记住''任何之前的对话。它只看到当前传入的 token 序列，根据训练中学到的统计规律自回归地（autoregressive）逐个生成后续 token。', '可以用 tokenizer 工具查看文本的 token 数量：DeepSeek 兼容 OpenAI 的 tiktoken 库。理解 token 有助于后续项目中合理控制上下文长度和 API 成本。', '# 使用 tiktoken 查看 token 数量（DeepSeek 兼容 OpenAI 的编码）
import tiktoken

encoder = tiktoken.get_encoding(''cl100k_base'')

text_en = ''Hello, how are you?''
text_zh = ''你好，今天天气怎么样？''

print(f''英文 token 数: {len(encoder.encode(text_en))}'')  # 约 6 个
print(f''中文 token 数: {len(encoder.encode(text_zh))}'')  # 约 13 个');
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (53, 2, '掌握 API 客户端初始化与核心参数', 'DeepSeek API 兼容 OpenAI SDK 格式，通过修改 base_url 即可切换服务商。核心调用接口是 chat.completions.create()，关键参数如下：

- api_key：身份认证凭证，格式为 sk- 开头的字符串。API Key 对应一个账户额度，每次调用会消耗 token 配额。
- base_url：API 服务端点地址。DeepSeek 为 https://api.deepseek.com，OpenAI 为 https://api.openai.com/v1。这个设计让你可以用同一套代码切换不同模型提供商。
- model：选择具体模型。deepseek-chat 用于通用对话（类似 GPT-4 级别），deepseek-reasoner 用于深度推理（类似 o1 级别，会先输出思维链再给答案）。
- messages：消息列表，是核心输入参数，决定模型''看到''什么内容。
- temperature：采样温度，0.0~2.0，控制输出随机性。
- max_tokens：限制模型最多生成多少 token。如果设置过小，回复会被截断（finish_reason 返回 ''length'' 而非 ''stop''）。', 'api_key 永远不要硬编码在代码中提交到 Git。在实验室服务器上可以用环境变量：终端执行 set DEEPSEEK_API_KEY=sk-xxx（Windows）或 export DEEPSEEK_API_KEY=sk-xxx（Linux/Mac），代码中用 os.getenv() 读取。', 'import os
from openai import OpenAI

client = OpenAI(
    api_key=os.getenv("DEEPSEEK_API_KEY", "sk-xxx"),
    base_url="https://api.deepseek.com",
)

response = client.chat.completions.create(
    model="deepseek-chat",
    messages=[
        {"role": "user", "content": "你好"}
    ],
    temperature=0.7,
    max_tokens=500
)

print(response.choices[0].message.content)');
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (53, 3, '解析 API 响应结构', 'API 返回的 response 对象包含丰富的信息，理解其结构对于调试和监控至关重要。顶层字段包括：id（请求唯一标识）、model（实际使用的模型）、usage（token 用量统计）和 choices（候选回复列表）。

choices[0] 包含：message（模型回复，含 role 和 content）、finish_reason（停止原因，''stop'' 表示正常结束，''length'' 表示达到 max_tokens 限制被截断，''content_filter'' 表示被安全过滤）。

usage 包含三个字段：prompt_tokens（输入 token 数）、completion_tokens（输出 token 数）、total_tokens（总计）。这些信息对于监控 API 消耗和优化 prompt 长度很有价值。通常输入 token 单价较低，输出 token 单价较高（约 4 倍），所以控制输出长度是节省成本的关键。', '如果 finish_reason 是 ''length''，说明回复被截断了，需要增大 max_tokens 重试。这是新手常犯的错误——以为模型''不想回答''，其实是输出被截断了。', 'response = client.chat.completions.create(
    model="deepseek-chat",
    messages=[{"role": "user", "content": "用 200 字介绍深度学习"}],
    max_tokens=500
)

# 解析回复内容
result = response.choices[0].message
print(f"回复内容: {result.content}")
print(f"停止原因: {response.choices[0].finish_reason}")

# 查看 token 用量
print(f"\n--- Token 用量 ---")
print(f"输入 tokens: {response.usage.prompt_tokens}")
print(f"输出 tokens: {response.usage.completion_tokens}")
print(f"总计 tokens: {response.usage.total_tokens}")');
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (53, 4, '深入理解三种消息角色', 'messages 列表中每条消息有 role 和 content 两个字段。role 有三种取值，各自承担不同职责：

system（系统消息）：设定 AI 的行为规则、角色身份和输出格式。模型在训练时被强化了对 system 消息的遵循——它被训练为将 system 内容视为不可违背的行为准则。因此 system prompt 适合放置全局性的指令，如''你是一个翻译助手，只输出翻译结果''。

user（用户消息）：用户输入的问题或指令。这是对话的主要内容，模型对此进行响应。

assistant（助手消息）：模型之前的回复。在多轮对话中，将之前的 assistant 消息保留在 messages 列表中，模型就能''看到''自己之前说了什么，从而维持对话连贯性。这也是项目三 Memory 机制的基础。

一条关键原则：System Prompt 与 User Prompt 的分离不仅是格式要求，更是控制力的分层——system 层提供稳定的行为框架，user 层处理变化的具体输入。', '把所有指令都放在 User Prompt 里也能工作，但当用户输入较长或包含干扰信息时，模型可能''忘记''遵循指令。将关键指令放在 System Prompt 中更稳定。', '# 单轮对话：只有 system + user
messages_single = [
    {"role": "system", "content": "你是一个专业的翻译助手，只输出翻译结果。"},
    {"role": "user", "content": "请把''你好世界''翻译成英文"}
]

# 多轮对话：包含历史 assistant 消息
messages_multi = [
    {"role": "system", "content": "你是一个友好的助手。"},
    {"role": "user", "content": "我叫小明"},
    {"role": "assistant", "content": "你好小明！很高兴认识你。"},
    {"role": "user", "content": "我叫什么名字？"}  # 模型能通过历史记录回答
]');
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (53, 5, '掌握采样参数：temperature 与 top_p', '模型生成每个 token 时，会计算词表中所有 token 的概率分布，然后从中采样。采样参数决定了''如何选择''：

temperature（温度）：控制概率分布的''锐度''。temperature → 0 时，分布变得极其尖锐，模型几乎总是选概率最高的 token（贪心解码）；temperature 升高，分布变平坦，低概率 token 也有机会被选中。temperature = 0 或极小时输出最确定，1.5 以上输出高度随机。

top_p（核采样）：只从累积概率达到 p 的最小 token 集合中采样。top_p = 0.1 意味着只从概率最高的那几个 token 中选择。与 temperature 的区别在于：top_p 动态调整候选集大小——当模型很确定时候选少，不确定时候选多。

通常只调其中一个。需要稳定输出（数据提取、日程规划）时设 temperature=0.0~0.3；一般对话设 0.7~1.0；创意写作设 1.2~1.5。', '如果日程规划助手的 temperature 设为 1.5，同样的输入可能每次输出完全不同的时间表格式。结构化任务务必用低 temperature。', '# 贪心解码：temperature=0，输出最确定
resp_greedy = client.chat.completions.create(
    model="deepseek-chat",
    messages=[{"role": "user", "content": "中国的首都是？"}],
    temperature=0.0  # 多次调用结果几乎完全相同
)

# 核采样：top_p=0.1，只从最可能的 token 中选择
resp_topp = client.chat.completions.create(
    model="deepseek-chat",
    messages=[{"role": "user", "content": "给公司起个名字"}],
    top_p=0.1  # 候选集动态调整
)');
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (53, 6, 'System Prompt 的四要素设计法', 'System Prompt 是 Prompt Engineering 的核心，它决定了模型的行为模式。一个有效的 System Prompt 应包含四个要素：

1. 角色定义（Role）：你是谁。如''你是一个专业的日程规划助手''。角色定义帮助模型进入''专家模式''，激活与角色相关的训练知识。

2. 任务描述（Task）：你要做什么。如''将用户杂乱的日程描述整理为清晰的时间表''。任务描述要具体明确，避免模糊表述。

3. 输出格式（Format）：按什么格式输出。如''使用 Markdown 无序列表，时间用 24 小时制''。明确格式要求是获得结构化输出的关键。

4. 约束条件（Constraint）：不能做什么。如''不要输出多余的解释，只输出时间表''。约束条件划定行为边界，防止模型''话多''。

此外，在 System Prompt 中给出输出示例（Few-shot）比纯抽象描述更有效——模型对示例的遵循度通常高于对规则描述的理解。', '一个好的检验标准：把 System Prompt 给一个完全不了解项目的人看，他能否准确预测模型的输出格式？如果不能，说明 prompt 还不够清晰。', 'system_prompt = """你是一个专业的日程规划助手。

【任务】将用户杂乱的日程描述整理为清晰的时间表。

【输出格式】
1. 使用 Markdown 无序列表格式
2. 时间统一使用 24 小时制 HH:MM 格式
3. 按时间先后排序
4. 每条格式为：- HH:MM 事项描述

【约束】
- 只输出时间表，不要附加任何解释或问候语
- 如果用户没有指定具体时间的事项，放在列表末尾并标注''待定''

【示例】
输入：明天上午九点开会，下午有空写报告
输出：
- 09:00 开会
- 待定 写报告"""');
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (53, 7, '掌握 Few-shot Prompting 技巧', 'Few-shot Prompting 是在提示中提供几个输入-输出示例，让模型''照样子''生成回答。这利用了模型的上下文学习（In-context Learning）能力——模型虽然不会因为你的示例而更新权重，但它会根据示例中的模式来推断你期望的输出格式和风格。

根据示例数量分为：Zero-shot（无示例，只给指令）、One-shot（1 个示例）、Few-shot（2-5 个示例）。通常 2-3 个示例就能显著提高输出格式的稳定性。示例过多反而会浪费 token 并可能导致模型''过拟合''到示例内容。

示例的选择原则：覆盖典型场景、格式一致、包含边界情况。如果示例之间有递进关系（从简单到复杂），效果更好。', 'Few-shot 示例放在 System Prompt 中（作为系统指令的一部分）还是 User Prompt 中（作为用户输入的一部分）都可以，但放在 System Prompt 中通常更稳定。', '# Zero-shot：只给指令
system_zero = "你是一个情绪分析器，输出 JSON 格式的情绪分析结果。"

# Few-shot：给指令 + 示例
system_fewshot = """你是一个情绪分析器。分析用户输入文本的情绪，输出 JSON 格式。

示例 1：
输入：太棒了！我今天拿到了 offer！
输出：{"emotion": "开心", "confidence": "高"}

示例 2：
输入：哎，又下雨了...
输出：{"emotion": "悲伤", "confidence": "中"}

示例 3：
输入：这个 bug 改了三遍还是不对！！！
输出：{"emotion": "愤怒", "confidence": "高"}

请分析以下输入："""');
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (53, 8, 'API 错误处理与重试机制', '在实际调用中，API 请求可能因各种原因失败：网络超时、速率限制（rate limit，短时间内请求过多，返回 429 状态码）、服务端错误（500）、余额不足等。健壮的程序需要处理这些异常。

常见的错误类型：openai.APIConnectionError（网络连接失败）、openai.RateLimitError（触发速率限制）、openai.APIStatusError（其他 HTTP 错误）。对于网络超时和速率限制，通常采用指数退避（exponential backoff）重试策略：第一次等 1 秒重试，第二次等 2 秒，第三次等 4 秒，以此类推。

openai SDK 内置了重试机制，默认会重试 2 次。也可以手动实现更精细的控制。', '在实验室批量调用 API 时很容易触发速率限制。DeepSeek 的速率限制可以在控制台查看，建议每次请求之间加 time.sleep(0.5) 间隔。', 'import time
from openai import OpenAI, APIConnectionError, RateLimitError

client = OpenAI(
    api_key=os.getenv("DEEPSEEK_API_KEY"),
    base_url="https://api.deepseek.com",
)

def call_with_retry(system_prompt, user_input, max_retries=3):
    """带指数退避重试的 API 调用"""
    for attempt in range(max_retries):
        try:
            response = client.chat.completions.create(
                model="deepseek-chat",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_input},
                ],
                temperature=0.2,
            )
            return response.choices[0].message.content
        except RateLimitError:
            wait_time = 2 ** attempt  # 指数退避：1s, 2s, 4s
            print(f"触发速率限制，等待 {wait_time}s 后重试...")
            time.sleep(wait_time)
        except APIConnectionError:
            print(f"网络错误，第 {attempt+1} 次重试...")
            time.sleep(1)
    return "API 调用失败，请稍后重试"');
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (53, 9, '封装可复用的调用基础设施', '在实际项目中，应将 API 调用封装为可复用的函数或类。封装的好处：统一管理配置（model、base_url 等）、集中处理错误、方便后续项目复用。这个封装函数是后续四个项目的基础设施。

好的封装应该：接受 system_prompt 和 user_input 作为必要参数，temperature 和 max_tokens 作为可选参数（有合理默认值），内部处理错误和重试，返回干净的字符串结果。也可以进一步封装为类，支持保存调用历史、统计 token 消耗等功能。', '将这段代码保存为 utils.py 或 common.py，后续项目中直接 import 使用，避免每个 notebook 重复写初始化代码。', 'import os
from openai import OpenAI

client = OpenAI(
    api_key=os.getenv("DEEPSEEK_API_KEY", "sk-xxx"),
    base_url="https://api.deepseek.com",
)

def call_deepseek(system_prompt, user_input, temperature=0.2, max_tokens=500):
    """
    调用 DeepSeek API 的通用函数。
    
    参数:
        system_prompt: 系统提示词，定义 AI 的角色和行为
        user_input: 用户输入的内容
        temperature: 创造性控制 (0.0~2.0)，默认 0.2
        max_tokens: 最大输出 token 数，默认 500
    返回:
        str: 模型的回复内容
    """
    response = client.chat.completions.create(
        model="deepseek-chat",
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_input},
        ],
        temperature=temperature,
        max_tokens=max_tokens,
    )
    return response.choices[0].message.content


# 测试
result = call_deepseek(
    system_prompt="你是一个友好的助手，用一句话回答问题。",
    user_input="简短介绍一下深度学习？"
)
print(result)');

-- learning-card-project2.json: Tool Use — 让智能体具备外部工具调用能力
SET @existing_item_pk := (SELECT `item_pk` FROM `learning_item` WHERE `title` = 'Tool Use — 让智能体具备外部工具调用能力' LIMIT 1);
DELETE FROM `learning_step` WHERE `item_pk` = @existing_item_pk AND @existing_item_pk IS NOT NULL AND @existing_item_pk <> 54;
DELETE FROM `learning_item` WHERE `item_pk` = @existing_item_pk AND @existing_item_pk IS NOT NULL AND @existing_item_pk <> 54;
INSERT INTO `learning_item` (`item_pk`, `json_id`, `title`, `summary`, `category`, `difficulty`, `duration`, `prerequisites`, `objectives`, `features`, `status`, `template_path`, `author_id`, `published_at`, `created_at`, `updated_at`) VALUES (54, 954905328, 'Tool Use — 让智能体具备外部工具调用能力', '从大语言模型的根本局限性出发，讲解 Function Calling 机制的设计原理与实现细节。深入理解 JSON Schema 工具定义、tool_calls 消息解析、tool 角色消息回传的完整协议，掌握单工具调用、多工具路由、并行工具调用以及工具调用错误处理的工程实践。', '智能体', '中等', '3小时', '项目一完成（掌握 API 调用与 messages 结构）、JSON 格式基础、Python 字典与列表操作', CAST('["理解大模型的四类根本局限以及 Tool Use 的解决思路","掌握 Function Calling 协议的完整六步流程及其背后的设计动机","能够用 JSON Schema 精确定义工具的名称、描述、参数类型与约束","理解 assistant（带 tool_calls）和 tool 两种新消息角色的格式要求","实现单工具、多工具路由与并行工具调用的智能体","掌握工具调用中的错误处理与边界情况应对"]' AS JSON), CAST('[{"title":"Function Calling 协议","description":"DeepSeek/OpenAI 提供的标准化工具调用协议。模型通过返回 tool_calls 字段表达调用意图，由系统执行后将结果回传模型，模型再据此生成最终回答。"},{"title":"工具定义与注册","description":"使用 JSON Schema 格式描述工具的 name、description、parameters，模型据此判断何时调用哪个工具以及传递什么参数。工具描述的质量直接决定调用的准确性。"},{"title":"多工具路由与并行调用","description":"通过工具注册表实现多工具路由分发，支持模型在一次回复中并行调用多个工具，以及处理工具调用中的各种异常情况。"}]' AS JSON), 'PUBLISHED', 'item-54/template.ipynb', NULL, NOW(), NOW(), NOW()) ON DUPLICATE KEY UPDATE `json_id` = VALUES(`json_id`), `title` = VALUES(`title`), `summary` = VALUES(`summary`), `category` = VALUES(`category`), `difficulty` = VALUES(`difficulty`), `duration` = VALUES(`duration`), `prerequisites` = VALUES(`prerequisites`), `objectives` = VALUES(`objectives`), `features` = VALUES(`features`), `status` = VALUES(`status`), `template_path` = VALUES(`template_path`), `published_at` = COALESCE(`published_at`, VALUES(`published_at`)), `updated_at` = NOW();
DELETE FROM `learning_step` WHERE `item_pk` = 54;
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (54, 1, '理解大模型的根本局限与 Tool Use 的设计动机', '大语言模型有四个根本局限，理解这些局限是理解 Tool Use 设计动机的前提：

1. 知识截止：模型的知识停留在训练数据的截止日期，无法获取实时信息（如今日天气、最新论文）。
2. 计算不可靠：模型通过概率分布生成 token，不擅长精确算术。1234×5678 模型可能''猜''一个接近的答案，但不保证正确。
3. 无法访问外部系统：模型不能查数据库、读文件、调 API，它的世界就是训练数据和输入 prompt。
4. 幻觉问题：模型可能自信地编造不存在的事实，因为它本质上是在做''合理的续写''而非''事实检索''。

Tool Use 的核心思想是''模型负责决策，工具负责执行''——模型像一个被关在房间里的智者，可以思考推理但无法直接观察外界。工具就是房间开的小窗口：模型判断需要外界信息时，递一张纸条出去（输出工具调用指令），外面的助手执行操作后把结果递回来（tool 消息），模型再根据结果组织回答。', '关键理解：模型本身并不执行工具。它只是输出一个''我想调用 get_weather(city=''Beijing'')''的结构化指令，真正的函数执行发生在我们本地的 Python 代码中。模型的角色是''决策者''而非''执行者''。', '');
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (54, 2, '定义本地工具函数', '工具调用的第一步是定义真正执行功能的本地 Python 函数。这些函数与模型无关，是纯粹的业务逻辑。以天气查询为例，我们使用免费的 wttr.in API 获取真实天气数据——这是一个开源天气服务，返回 JSON 格式数据，无需注册 API Key，适合学习使用。

函数设计要点：参数类型要明确（str、int 等），返回值统一为字符串（因为最终要作为 tool 消息的 content 发给模型），要有异常处理（网络请求可能失败），返回信息要有意义（模型需要据此生成自然语言回答）。', '工具函数的返回值会被模型''阅读''并据此生成回答，所以返回值应该是信息丰富的自然语言字符串，而不是原始的数据结构。', 'import requests

def get_weather(city: str) -> str:
    """查询指定城市的实时天气（使用 wttr.in 免费 API）"""
    try:
        resp = requests.get(
            f"https://wttr.in/{city}?format=j1&lang=zh",
            timeout=10
        )
        data = resp.json()
        current = data["current_condition"][0]
        temp = current["temp_C"]
        humidity = current["humidity"]
        desc = current["lang_zh"][0]["value"]
        feels_like = current["FeelsLikeC"]
        wind_speed = current["windspeedKmph"]
        
        return f"{city}当前天气：{desc}，气温 {temp}°C，体感 {feels_like}°C，湿度 {humidity}%，风速 {wind_speed}km/h"
    except Exception as e:
        return f"获取 {city} 天气失败：{e}"


def calculate_days(date1: str, date2: str) -> str:
    """计算两个日期之间相差多少天"""
    from datetime import datetime
    d1 = datetime.strptime(date1, "%Y-%m-%d")
    d2 = datetime.strptime(date2, "%Y-%m-%d")
    diff = abs((d2 - d1).days)
    return f"{date1} 到 {date2} 相差 {diff} 天"


# 测试工具函数
print(get_weather("Kaifeng"))
print(calculate_days("2025-01-01", "2025-10-01"))');
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (54, 3, '用 JSON Schema 定义工具描述', '工具描述是给模型看的''说明书''，使用 JSON Schema 格式。它不是执行函数，而是告诉模型''你有哪些工具可以用，每个工具需要什么参数''。每个工具描述包含三部分：

name：工具名称，模型据此指定调用哪个工具。命名要清晰，如 get_weather 比 tool_1 更好。

description：工具功能描述，模型据此判断何时应该调用。这是最关键的字段——描述不准确会导致模型在该调用时不调用，或不该调用时乱调用。描述中应包含使用场景和返回内容的说明。

parameters：参数定义，使用 JSON Schema 的 type/properties/required 结构。每个参数需要有 type（类型）、description（描述，含示例值）。required 数组指定必填参数。支持的参数类型包括 string、number、integer、boolean、array、object。

对于枚举类型的参数，可以使用 enum 字段限制取值范围，如 {"type": "string", "enum": ["celsius", "fahrenheit"]}。', 'description 中给出参数示例（如''城市英文名，例如 Beijing、Shanghai''）能显著提高模型传参的准确性。模糊的描述（如''城市名称''）可能导致模型传中文名而非拼音。', 'weather_tool = {
    "type": "function",
    "function": {
        "name": "get_weather",
        "description": "根据城市名称查询当前的实时天气情况，包括温度、天气状况、湿度和风速。当用户询问任何与天气相关的问题时应调用此工具。",
        "parameters": {
            "type": "object",
            "properties": {
                "city": {
                    "type": "string",
                    "description": "要查询天气的城市英文名（拼音），例如：Beijing、Shanghai、Guangzhou"
                }
            },
            "required": ["city"]
        }
    }
}

# 带枚举参数的工具示例
unit_tool = {
    "type": "function",
    "function": {
        "name": "convert_temperature",
        "description": "在摄氏度和华氏度之间转换温度",
        "parameters": {
            "type": "object",
            "properties": {
                "value": {"type": "number", "description": "温度数值"},
                "from_unit": {
                    "type": "string",
                    "enum": ["celsius", "fahrenheit"],
                    "description": "原始温度单位"
                },
                "to_unit": {
                    "type": "string",
                    "enum": ["celsius", "fahrenheit"],
                    "description": "目标温度单位"
                }
            },
            "required": ["value", "from_unit", "to_unit"]
        }
    }
}');
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (54, 4, '理解两种新的消息角色', 'Tool Use 在 system/user/assistant 基础上引入了两种新的消息结构：

第一种：带 tool_calls 的 assistant 消息。当模型判断需要调用工具时，返回的 content 为空字符串，取而代之的是 tool_calls 数组。每个 tool_call 包含：id（本次调用的唯一标识符，如 ''call_abc123''）、type（固定为 ''function''）、function.name（要调用的函数名）和 function.arguments（JSON 格式的参数字符串）。注意 arguments 是字符串而非字典，需要用 json.loads() 解析。

第二种：tool 消息。工具执行完成后，通过 role: ''tool'' 的消息将结果返回给模型。其中 tool_call_id 必须与 assistant 消息中对应 tool_call 的 id 完全匹配——这是 API 用来关联请求和响应的机制。

重要规则：每个 tool_call 都必须有一条对应的 tool 消息，数量必须一一对应。如果模型返回了 3 个 tool_calls，就必须有 3 条 tool 消息，否则 API 会报错 ''insufficient tool messages following tool_calls message''。assistant 消息中 content 必须是空字符串 "" 而不是 None。', '最常见的错误是 tool_call_id 不匹配或 tool 消息数量不对。调试时建议打印 messages 列表，检查每条 tool 消息的 tool_call_id 是否与 assistant 中的 id 一一对应。', '# 完整的消息流转示例

# 第 1 次 API 调用：用户提问
messages = [
    {"role": "user", "content": "北京今天天气怎么样？"}
]
# → 模型返回 assistant 消息，包含 tool_calls：
# {
#     "role": "assistant",
#     "content": "",
#     "tool_calls": [{
#         "id": "call_abc123",
#         "type": "function",
#         "function": {
#             "name": "get_weather",
#             "arguments": "{\"city\": \"Beijing\"}"
#         }
#     }]
# }

# 第 2 次 API 调用：带上完整历史
messages = [
    {"role": "user", "content": "北京今天天气怎么样？"},
    {"role": "assistant", "content": "", "tool_calls": [...]},
    {"role": "tool", "tool_call_id": "call_abc123", "content": "Beijing当前天气：晴，气温 28°C"},
]
# → 模型根据工具结果，生成最终回答："北京今天天气晴朗，气温28°C..."');
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (54, 5, '实现单工具调用的完整流程', '单工具智能体的完整流程是一个循环：

第 1 步：将用户消息和 tools 参数一起发送给模型。tools 参数告诉模型''你有这个工具可以用''。
第 2 步：检查返回的 assistant 消息是否包含 tool_calls。如果没有，说明模型判断不需要工具（如用户问''你好''），直接返回 content。
第 3 步：如果有 tool_calls，需要把 assistant 消息（含 tool_calls）追加到 messages 中。这里需要将 SDK 返回的对象转为字典格式。
第 4 步：遍历每个 tool_call，解析函数名和参数，执行对应的本地函数。
第 5 步：将每个工具的执行结果作为 tool 消息追加到 messages 中，tool_call_id 必须与对应的 tool_call.id 匹配。
第 6 步：再次调用 API。模型看到工具结果后，可能生成最终回答，也可能继续调用工具（多轮工具调用）。因此整个流程用 while 循环包裹。

设置最大轮次限制（如 5 轮）防止无限循环。', 'messages 列表的完整性至关重要。模型需要通过完整的消息历史来理解工具调用的上下文和结果。不要在中途丢弃任何消息。', 'def weather_agent(user_query):
    """天气查询智能体：支持多轮工具调用"""
    print(f"用户提问：{user_query}\n")
    messages = [{"role": "user", "content": user_query}]
    
    round_num = 0
    while True:
        round_num += 1
        print(f"--- 第 {round_num} 轮 API 调用 ---")
        
        response = client.chat.completions.create(
            model="deepseek-chat",
            messages=messages,
            tools=[weather_tool],
        )
        assistant_msg = response.choices[0].message
        
        # 没有工具调用 → 最终回答
        if not assistant_msg.tool_calls:
            print(f"最终回答：{assistant_msg.content}")
            return assistant_msg.content
        
        # 有工具调用 → 构建 assistant 消息
        print(f"模型决定调用 {len(assistant_msg.tool_calls)} 个工具")
        tool_calls_dict = [{
            "id": tc.id, "type": "function",
            "function": {"name": tc.function.name, "arguments": tc.function.arguments}
        } for tc in assistant_msg.tool_calls]
        messages.append({"role": "assistant", "content": "", "tool_calls": tool_calls_dict})
        
        # 执行每个工具并添加 tool 消息
        for tc in assistant_msg.tool_calls:
            args = json.loads(tc.function.arguments)
            print(f"  调用工具：{tc.function.name}({args})")
            result = get_weather(**args)
            print(f"  执行结果：{result}")
            messages.append({"role": "tool", "tool_call_id": tc.id, "content": result})
        
        if round_num >= 5:
            print("达到最大轮次限制")
            break');
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (54, 6, '实现多工具协作与工具注册表', '当智能体拥有多个工具时，需要一个路由机制来根据模型返回的函数名调用不同的本地函数。推荐使用工具注册表（TOOL_REGISTRY）——一个字典，将工具名字符串映射到实际的 Python 函数对象。

相比 if-else 链，注册表的优势：新增工具只需两行代码（定义函数 + 注册映射），不需要修改路由逻辑；可以用循环统一处理所有工具，代码更简洁；可以动态注册/注销工具（如根据用户权限决定可用工具集）。

将所有工具的描述放入 tools 列表传给 API，模型会根据用户意图自动选择合适的工具。模型选择工具的依据主要来自 description 字段——所以每个工具的描述要有足够的区分度，让模型能区分何时该用哪个。', '工具注册表是生产环境中的标准做法，它让代码符合开闭原则（对扩展开放，对修改关闭）。当工具数量超过 10 个时，建议将工具描述也自动生成（从函数的 docstring 提取），减少手动维护。', 'from datetime import datetime

# 本地工具函数
def get_weather(city: str) -> str:
    """查询天气..."""
    # ... 同前面的实现 ...
    pass

def calculate_days(date1: str, date2: str) -> str:
    """计算日期差..."""
    d1 = datetime.strptime(date1, "%Y-%m-%d")
    d2 = datetime.strptime(date2, "%Y-%m-%d")
    return f"{date1} 到 {date2} 相差 {abs((d2-d1).days)} 天"

# 工具描述列表
tools = [weather_tool_description, calculate_days_tool_description]

# 工具注册表：名字 → 函数对象的映射
TOOL_REGISTRY = {
    "get_weather": get_weather,
    "calculate_days": calculate_days,
}

# 统一路由
for tc in assistant_msg.tool_calls:
    function_name = tc.function.name
    arguments = json.loads(tc.function.arguments)
    
    if function_name in TOOL_REGISTRY:
        result = TOOL_REGISTRY[function_name](**arguments)
    else:
        result = f"错误：未知工具 {function_name}"
    
    print(f"调用：{function_name}({arguments}) → {result}")');
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (54, 7, '处理并行工具调用', '模型可以在一次回复中返回多个 tool_calls，表示需要并行调用多个工具。典型场景：用户问''上海和北京哪个更热？''，模型会同时返回两个 get_weather 调用（一个查上海，一个查北京）。

处理并行调用的关键：必须为每个 tool_call 都执行本地函数并返回对应的 tool 消息。所有 tool 消息在同一次 API 调用中一起发给模型，模型会综合所有工具结果生成回答。

在构建 messages 时，一个 assistant 消息（含 N 个 tool_calls）后面必须紧跟 N 条 tool 消息，顺序不强制要求与 tool_calls 一致，但 tool_call_id 必须一一对应。建议按相同顺序构建，便于调试。', '并行工具调用是模型''聪明''的体现——它知道需要两个城市的数据才能比较，于是一次性请求两个工具调用，而不是分两轮。这减少了 API 调用次数，提高了效率。', 'def smart_agent(user_query):
    """多工具智能体：支持并行工具调用"""
    print(f"用户提问：{user_query}\n")
    
    response = client.chat.completions.create(
        model="deepseek-chat",
        messages=[{"role": "user", "content": user_query}],
        tools=tools,
    )
    assistant_msg = response.choices[0].message
    
    if assistant_msg.tool_calls:
        tool_results = []
        
        # 执行所有工具调用（可能并行）
        for tc in assistant_msg.tool_calls:
            args = json.loads(tc.function.arguments)
            print(f"调用工具：{tc.function.name}({args})")
            result = TOOL_REGISTRY[tc.function.name](**args)
            print(f"执行结果：{result}")
            tool_results.append((tc.id, result))
        
        # 构建完整 messages
        messages = [{"role": "user", "content": user_query}]
        tool_calls_dict = [{
            "id": tc.id, "type": "function",
            "function": {"name": tc.function.name, "arguments": tc.function.arguments}
        } for tc in assistant_msg.tool_calls]
        messages.append({"role": "assistant", "content": "", "tool_calls": tool_calls_dict})
        for tool_id, result in tool_results:
            messages.append({"role": "tool", "tool_call_id": tool_id, "content": result})
        
        # 模型综合所有工具结果生成回答
        final = client.chat.completions.create(
            model="deepseek-chat", messages=messages
        )
        print(f"最终回答：{final.choices[0].message.content}")
        return final.choices[0].message.content');
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (54, 8, '工具调用的错误处理与边界情况', '工具调用中有多种可能的错误场景需要处理：

1. 工具执行异常：本地函数抛出异常（如网络超时、文件不存在）。应在函数内部 try-except 捕获，返回错误信息字符串而非让程序崩溃。错误信息会被模型看到，模型可能会换个参数重试或告知用户。

2. 未知工具名：模型返回了一个不在注册表中的函数名（罕见但可能，尤其在工具描述有歧义时）。应返回友好的错误提示。

3. 参数解析失败：arguments 不是合法 JSON，或参数类型不匹配（如模型传了字符串但函数期望数字）。用 try-except 包裹 json.loads() 和函数调用。

4. 模型幻觉工具：模型可能''发明''一个不存在的工具名。通过注册表的 existence check 可以拦截。

5. 无限循环：模型反复调用工具而不给出最终回答。通过设置最大轮次限制来防止。

这些错误处理不仅是工程需要，也影响智能体的可靠性——一个能优雅处理错误的智能体比一个遇到异常就崩溃的智能体实用得多。', '建议将工具执行逻辑封装为统一的 dispatch 函数，集中处理所有错误情况，而不是在每个工具函数中重复写 try-except。', 'def dispatch_tool_call(tc) -> tuple:
    """
    统一工具调度函数，处理所有错误情况。
    返回 (tool_call_id, result_string)
    """
    function_name = tc.function.name
    
    # 检查工具是否存在
    if function_name not in TOOL_REGISTRY:
        return tc.id, f"错误：未知工具 ''{function_name}''。可用工具：{list(TOOL_REGISTRY.keys())}"
    
    # 解析参数
    try:
        arguments = json.loads(tc.function.arguments)
    except json.JSONDecodeError as e:
        return tc.id, f"错误：参数解析失败 - {e}。原始参数：{tc.function.arguments}"
    
    # 执行工具
    try:
        result = TOOL_REGISTRY[function_name](**arguments)
        return tc.id, str(result)
    except Exception as e:
        return tc.id, f"工具执行出错：{type(e).__name__}: {e}"');

-- learning-card-project3.json: Memory — 让智能体记住对话上下文
SET @existing_item_pk := (SELECT `item_pk` FROM `learning_item` WHERE `title` = 'Memory — 让智能体记住对话上下文' LIMIT 1);
DELETE FROM `learning_step` WHERE `item_pk` = @existing_item_pk AND @existing_item_pk IS NOT NULL AND @existing_item_pk <> 55;
DELETE FROM `learning_item` WHERE `item_pk` = @existing_item_pk AND @existing_item_pk IS NOT NULL AND @existing_item_pk <> 55;
INSERT INTO `learning_item` (`item_pk`, `json_id`, `title`, `summary`, `category`, `difficulty`, `duration`, `prerequisites`, `objectives`, `features`, `status`, `template_path`, `author_id`, `published_at`, `created_at`, `updated_at`) VALUES (55, 982907259, 'Memory — 让智能体记住对话上下文', '从大语言模型''无状态''的架构本质出发，系统讲解短期记忆的实现原理与管理策略。深入分析全量记忆、滑动窗口、摘要压缩三种方案的 token 开销与信息保留的权衡，探讨 Token 预算管理方法，以及 Memory 与 Tool Use 组合使用时的消息完整性约束。', '智能体', '高级', '3小时', '项目一完成（掌握 API 调用）、项目二完成（理解 messages 结构与 tool 消息）', CAST('["从模型架构层面理解''无状态''的本质以及为什么需要 Memory 机制","掌握通过 messages 列表维护对话上下文的核心方法与实现细节","理解全量记忆、滑动窗口、摘要压缩三种策略的原理、优劣与适用场景","能够估算对话的 token 消耗并设计合理的 Token 预算","实现带记忆的工具调用智能体，正确处理 tool 消息的截断约束","了解长期记忆的概念与实现思路"]' AS JSON), CAST('[{"title":"短期记忆机制","description":"将对话历史存储在 messages 列表中，每次调用 API 时把完整上下文一起发给模型。这是所有记忆策略的基础。"},{"title":"记忆管理策略","description":"滑动窗口只保留最近 N 轮，摘要压缩将早期对话总结为概要，两者结合在 token 消耗和信息保留之间取得平衡。"},{"title":"Token 预算管理","description":"估算对话各部分的 token 消耗，为记忆、工具描述、输出预留分别分配额度，实现可控的资源管理。"}]' AS JSON), 'PUBLISHED', 'item-55/template.ipynb', NULL, NOW(), NOW(), NOW()) ON DUPLICATE KEY UPDATE `json_id` = VALUES(`json_id`), `title` = VALUES(`title`), `summary` = VALUES(`summary`), `category` = VALUES(`category`), `difficulty` = VALUES(`difficulty`), `duration` = VALUES(`duration`), `prerequisites` = VALUES(`prerequisites`), `objectives` = VALUES(`objectives`), `features` = VALUES(`features`), `status` = VALUES(`status`), `template_path` = VALUES(`template_path`), `published_at` = COALESCE(`published_at`, VALUES(`published_at`)), `updated_at` = NOW();
DELETE FROM `learning_step` WHERE `item_pk` = 55;
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (55, 1, '从模型架构理解''无状态''的本质', '大模型的 API 是无状态（Stateless）的——每次调用都是独立的推理过程，模型不会自动记住上次聊了什么。这不是 API 的设计缺陷，而是 Transformer 架构的固有特性。

从技术层面看：模型的''知识''编码在神经网络的权重参数中（训练阶段确定），推理时权重是冻结的、只读的。模型没有可写的''记忆区域''——没有类似传统计算机的 RAM 或寄存器。每次调用，输入序列经过 Transformer 的多层自注意力计算，产生输出概率分布，整个过程是纯函数（pure function）：相同输入必然产生相同输出，不依赖任何外部状态。

这意味着：如果两次调用传入完全相同的 messages，会得到（几乎）相同的回复。模型不会因为''上次聊过''就改变行为。每次 API 调用，模型只看到当前传入的 messages 列表，除此之外一无所知。

无状态也是优势：API 调用之间互不影响，易于水平扩展（可以负载均衡到不同服务器）、故障恢复简单（重试即可）、并行处理方便。', '这个''纯函数''特性在调试时很有用——你可以把 messages 列表保存下来，在任何时候重放同一次调用，复现模型的行为。', '');
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (55, 2, '通过 messages 列表实现短期记忆', '既然模型没有记忆，我们就主动把之前的对话记录告诉它。短期记忆的本质是：把对话历史存在一个 Python 列表里，每次调用时把完整的历史一起发给模型。

具体实现：维护一个 messages 列表，初始包含 system prompt。每次用户说话时追加 user 消息，调用 API 获取回复，再把 assistant 消息追加进去。下次调用时，模型看到完整的对话历史，就能''记住''之前聊了什么。

这个方案简单有效，但有一个隐含的成本：每轮对话增加 2 条消息（user + assistant），API 调用的输入 token 数随对话轮次线性增长。这意味着响应变慢、费用增加，最终可能超出上下文窗口限制。', 'messages 列表就是智能体的''工作记忆''。你可以把它理解为：智能体的''大脑''在云端（模型），''记事本''在本地（messages 列表）。每次思考前，先把记事本上的内容念给大脑听。', 'class SimpleMemoryAgent:
    """最简单的记忆智能体：把所有对话历史都记住"""
    
    def __init__(self, system_prompt="你是一个友好的助手。"):
        self.messages = [
            {"role": "system", "content": system_prompt}
        ]
    
    def chat(self, user_text):
        # 1. 把用户消息加入历史
        self.messages.append({"role": "user", "content": user_text})
        
        # 2. 把完整历史发给模型
        response = client.chat.completions.create(
            model="deepseek-chat",
            messages=self.messages
        )
        reply = response.choices[0].message.content
        
        # 3. 把模型的回复也加入历史
        self.messages.append({"role": "assistant", "content": reply})
        
        return reply
    
    def show_memory(self):
        """查看当前记忆内容"""
        print(f"当前记忆中有 {len(self.messages)} 条消息：")
        for i, msg in enumerate(self.messages):
            print(f"  [{i}] {msg[''role'']}: {msg[''content''][:50]}...")


# 测试
agent = SimpleMemoryAgent("你是一个友好的中文助手，请用简短的话回答。")
print(agent.chat("我叫小明，我是一名研究生"))
print(agent.chat("我叫什么名字？我是做什么的？"))  # 模型能记住
agent.show_memory()');
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (55, 3, '理解上下文窗口与 Token 预算', '直接把所有历史都塞给模型会遇到三个问题：

1. 上下文窗口限制：deepseek-chat 最大 64K token（约 4-5 万汉字），超过限制 API 会报错。假设每轮对话约 200 token（user 100 + assistant 100），聊 300 轮就是 60K token，接近上限。

2. 延迟增加：Transformer 的自注意力计算复杂度是 O(n²)，其中 n 是输入 token 数。输入越长，推理越慢。64K token 的推理时间可能是 1K token 的几十倍。

3. 费用增加：API 按 token 计费，输入 token 越多越贵。而且存在''注意力稀释''问题——当上下文过长时，模型可能''忽略''中间部分的信息（''Lost in the Middle''现象）。

因此需要 Token 预算管理：为 system prompt、对话历史、工具描述、输出预留分别分配 token 额度。例如：system prompt 预留 500 token，工具描述预留 500 token，对话历史预留 4000 token，输出预留 1000 token，总计 6000 token 的预算。', '实际项目中，输出 token 的单价通常是输入 token 的 3-4 倍。所以控制输入长度（记忆管理）和控制输出长度（max_tokens）同样重要。', 'import tiktoken

def count_tokens(text, model="gpt-4"):  # DeepSeek 兼容 cl100k_base 编码
    """估算文本的 token 数量"""
    encoder = tiktoken.get_encoding(''cl100k_base'')
    return len(encoder.encode(text))

def count_messages_tokens(messages):
    """估算 messages 列表的总 token 数"""
    total = 0
    for msg in messages:
        # 每条消息有固定的 overhead（role、分隔符等）约 4 token
        total += 4
        total += count_tokens(msg.get("content", ""))
    return total

# 示例：监控对话的 token 消耗
agent = SimpleMemoryAgent()
for i in range(5):
    agent.chat(f"这是第 {i+1} 轮对话的内容")
    tokens = count_messages_tokens(agent.messages)
    print(f"第 {i+1} 轮后，messages 总 token 数约: {tokens}")');
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (55, 4, '掌握滑动窗口策略', '滑动窗口是最简单的记忆管理策略：只保留最近 N 轮对话，丢弃更早的历史。实现方式是在 messages 列表中维护一个 recent_messages 子列表，当对话轮数超过窗口大小时，截断最早的消息。

优点：实现简单，token 消耗稳定（不随对话增长），适合实时性强的场景（如客服对话，用户很少引用很早之前的内容）。

缺点：会丢失早期信息。如果用户第一轮说了名字，聊了 20 轮后问''我叫什么''，模型答不上来。这在需要''长期跟踪''的场景中是致命缺陷。

窗口大小的选择需要权衡：太小（如 2 轮）会丢失必要的上下文（模型可能''忘记''用户刚才说的需求），太大（如 20 轮）会增加 token 消耗。通常 3-5 轮是一个合理的起点，具体取决于对话的''上下文依赖密度''——每轮对话中包含多少需要跨轮引用的信息。', '一个实用的技巧：在截断时保留 system prompt 和最近一轮对话，而不是机械地按窗口大小截断。这样至少模型能处理当前话题。', 'class SlidingWindowAgent:
    """滑动窗口记忆智能体"""
    
    def __init__(self, system_prompt, window_size=4):
        self.system_prompt = system_prompt
        self.window_size = window_size  # 保留最近几轮对话
        self.recent_messages = []
    
    def chat(self, user_text):
        self.recent_messages.append({"role": "user", "content": user_text})
        
        # 超过窗口大小时，截断最早的消息
        max_messages = self.window_size * 2  # 每轮有 user + assistant 两条
        if len(self.recent_messages) > max_messages:
            # 保留最近的 max_messages 条
            self.recent_messages = self.recent_messages[-max_messages:]
        
        # 构建发给模型的 messages
        messages = [{"role": "system", "content": self.system_prompt}]
        messages.extend(self.recent_messages)
        
        response = client.chat.completions.create(
            model="deepseek-chat",
            messages=messages
        )
        reply = response.choices[0].message.content
        self.recent_messages.append({"role": "assistant", "content": reply})
        
        return reply
    
    def show_memory(self):
        print(f"窗口大小: {self.window_size} 轮")
        print(f"当前保留: {len(self.recent_messages) // 2} 轮对话")
        for msg in self.recent_messages:
            print(f"  {msg[''role'']}: {msg[''content''][:50]}...")');
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (55, 5, '掌握摘要压缩策略', '摘要压缩策略在滑动窗口的基础上，将早期对话总结成一段摘要保留，兼顾 token 效率与信息保留。

具体做法：当对话超过窗口大小时，把最早的几轮对话发给模型（一次额外的 API 调用），让它生成 1-2 句话的摘要，然后用摘要替换掉那些早期对话。摘要累积追加——如果之前已有摘要，新摘要接在旧摘要后面。

最终发给模型的 messages 结构为：system prompt + 摘要消息（如果有）+ 最近 N 轮对话。摘要作为 system 角色的消息，因为它是''背景信息''而非''对话内容''。

优缺点：比纯滑动窗口保留了更多信息（关键事实存在于摘要中），但摘要是模型生成的，可能丢失细节或引入偏差。摘要本身也消耗 token（一次额外的 API 调用），可以定期批量压缩（如每积累 5 轮压缩一次）来降低开销。', '摘要生成时 temperature 应设低（0.1~0.3），因为需要忠实于原始对话内容，不需要创造性。', 'class SmartMemoryAgent:
    """滑动窗口 + 摘要压缩的记忆智能体"""
    
    def __init__(self, system_prompt, window_size=4):
        self.system_prompt = system_prompt
        self.window_size = window_size
        self.summary = ""              # 早期对话的摘要
        self.recent_messages = []      # 最近 N 轮对话
    
    def _summarize(self, old_messages):
        """把旧对话压缩成摘要（消耗一次 API 调用）"""
        old_text = "\n".join(
            f"{m[''role'']}: {m[''content'']}" for m in old_messages
        )
        summary_prompt = [
            {"role": "system", "content": "你是一个摘要助手。请用 1-2 句话总结以下对话中的关键信息，包括人名、数字、重要决定等。"},
            {"role": "user", "content": f"请总结以下对话：\n{old_text}"}
        ]
        response = client.chat.completions.create(
            model="deepseek-chat",
            messages=summary_prompt,
            temperature=0.3  # 低温度，忠实于原文
        )
        return response.choices[0].message.content
    
    def _build_messages(self):
        """构建发给模型的完整 messages 列表"""
        messages = [{"role": "system", "content": self.system_prompt}]
        if self.summary:
            messages.append({
                "role": "system",
                "content": f"以下是之前对话的摘要：{self.summary}"
            })
        messages.extend(self.recent_messages)
        return messages
    
    def chat(self, user_text):
        self.recent_messages.append({"role": "user", "content": user_text})
        
        max_messages = self.window_size * 2
        if len(self.recent_messages) > max_messages:
            old_msgs = self.recent_messages[:2]  # 取出最早的 1 轮
            self.recent_messages = self.recent_messages[2:]
            
            new_summary = self._summarize(old_msgs)
            if self.summary:
                self.summary += "\n" + new_summary
            else:
                self.summary = new_summary
            print(f"[记忆压缩] 当前摘要：{self.summary}")
        
        messages = self._build_messages()
        response = client.chat.completions.create(
            model="deepseek-chat", messages=messages
        )
        reply = response.choices[0].message.content
        self.recent_messages.append({"role": "assistant", "content": reply})
        return reply');
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (55, 6, 'Token 预算管理实战', '在实际项目中，需要对 token 消耗进行精细管理。一个实用的方案是设定 Token 预算，将总预算分配给各个部分：

- system prompt：固定开销，通常 200-500 token
- 工具描述（tools）：如果使用了 Tool Use，工具描述也占 token，通常 200-800 token
- 对话历史（记忆）：可变开销，是记忆管理的主要目标
- 输出预留（max_tokens）：通常 500-2000 token

总预算 = system + tools + history + output ≤ context_window

因此 history 的可用预算 = context_window - system - tools - output

例如：64K 窗口 - 500(system) - 500(tools) - 2000(output) = 61000 token 可用于对话历史。但如果希望响应快速（低延迟），可能将历史预算控制在 4000 token 以内。

实现时可以在每次追加消息前检查当前 token 数，超过预算时触发压缩或截断。', '在生产环境中，建议记录每次 API 调用的实际 token 消耗（response.usage），用于校准估算模型和优化预算分配。', 'class TokenBudgetManager:
    """Token 预算管理器"""
    
    def __init__(self, total_budget=8000, system_tokens=500, 
                 tool_tokens=500, output_tokens=1000):
        self.total_budget = total_budget
        self.system_tokens = system_tokens
        self.tool_tokens = tool_tokens
        self.output_tokens = output_tokens
        # 对话历史的可用预算
        self.history_budget = total_budget - system_tokens - tool_tokens - output_tokens
    
    def check_and_trim(self, messages, trim_func):
        """检查 token 是否超预算，超过时调用 trim_func 进行截断"""
        current_tokens = count_messages_tokens(messages)
        if current_tokens > self.history_budget:
            print(f"[Token 预算] 当前 {current_tokens} > 预算 {self.history_budget}，触发截断")
            messages = trim_func(messages)
        return messages
    
    def report(self, messages):
        """报告当前 token 使用情况"""
        current = count_messages_tokens(messages)
        print(f"Token 使用: {current}/{self.history_budget} "
              f"({current/self.history_budget*100:.1f}%)")');
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (55, 7, '结合 Memory 与 Tool Use', '在实际应用中，Memory 和 Tool Use 经常组合使用。带记忆的工具调用智能体需要同时维护 messages 列表（用于记忆）和 tools 参数（用于工具调用）。这引入了额外的复杂性：

消息完整性约束：截断记忆时不能破坏 tool 消息的完整性。role 为 tool 的消息必须与其对应的 assistant 消息（含 tool_calls）一起保留或一起删除。如果只删除了 assistant 消息而留下了 tool 消息（或反过来），API 会报错。

建议以''交互轮次''为单位进行截断：一个完整的交互轮次包括 user 消息 → assistant 消息（可能含 tool_calls）→ tool 消息（可能有多个）→ assistant 最终回复。截断时以这个完整单元为粒度。

System prompt 中的工具描述始终保留，不计入对话历史的截断范围。工具描述在每次 API 调用时通过 tools 参数传入，不占用 messages 列表的空间。', '设计带记忆的工具智能体时，建议在 messages 中用''分隔标记''或数据结构来标识每个交互轮次的边界，便于按轮次截断。', 'class MemoryToolAgent:
    """带记忆 + 工具调用的智能体"""
    
    def __init__(self, system_prompt, tools, tool_registry, window_size=5):
        self.system_prompt = system_prompt
        self.tools = tools
        self.tool_registry = tool_registry
        self.window_size = window_size
        self.messages = [{"role": "system", "content": system_prompt}]
    
    def chat(self, user_text):
        self.messages.append({"role": "user", "content": user_text})
        
        # 调用 API（带 tools 参数）
        response = client.chat.completions.create(
            model="deepseek-chat",
            messages=self.messages,
            tools=self.tools
        )
        assistant_msg = response.choices[0].message
        
        # 处理工具调用
        if assistant_msg.tool_calls:
            # 添加 assistant 消息（含 tool_calls）
            tool_calls_dict = [{
                "id": tc.id, "type": "function",
                "function": {"name": tc.function.name, "arguments": tc.function.arguments}
            } for tc in assistant_msg.tool_calls]
            self.messages.append({"role": "assistant", "content": "", "tool_calls": tool_calls_dict})
            
            # 执行工具并添加 tool 消息
            for tc in assistant_msg.tool_calls:
                args = json.loads(tc.function.arguments)
                result = self.tool_registry[tc.function.name](**args)
                self.messages.append({"role": "tool", "tool_call_id": tc.id, "content": result})
            
            # 再次调用 API 获取最终回复
            response = client.chat.completions.create(
                model="deepseek-chat",
                messages=self.messages,
                tools=self.tools
            )
            reply = response.choices[0].message.content
        else:
            reply = assistant_msg.content
        
        self.messages.append({"role": "assistant", "content": reply})
        
        # 截断记忆（以完整轮次为单位）
        self._trim_memory()
        return reply
    
    def _trim_memory(self):
        """按完整轮次截断记忆，保持 tool 消息的完整性"""
        # system prompt 始终保留
        non_history = 1  # system prompt 占 1 条
        history = self.messages[non_history:]
        
        # 按轮次分组：一个轮次 = user + (可选的 assistant[tool_calls] + tool[]) + assistant
        # 简单实现：统计 user 消息数量，超过 window_size 时截断
        user_count = sum(1 for m in history if m["role"] == "user")
        if user_count > self.window_size:
            # 找到第 (user_count - window_size + 1) 个 user 消息的位置
            user_indices = [i for i, m in enumerate(history) if m["role"] == "user"]
            cut_point = user_indices[user_count - self.window_size]
            self.messages = self.messages[:non_history] + history[cut_point:]');
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (55, 8, '长期记忆简介', '本项目聚焦的是短期记忆（单次会话内的上下文），但实际应用中还可能需要长期记忆——跨会话的持久化知识。例如：用户上周告诉助手自己对花粉过敏，这周问''推荐一个周末活动''时，助手应该记住这个信息。

长期记忆的常见实现方式：

1. 键值存储：将用户的关键信息（姓名、偏好、历史订单等）提取后存入数据库（如 Redis、SQLite），下次会话时读取并注入 system prompt。简单但需要手动设计存储结构。

2. 向量数据库：将对话历史用 Embedding 模型转为向量，存入向量数据库（如 Chroma、FAISS）。新对话开始时，根据用户当前输入做语义检索，找到最相关的历史片段注入上下文。这就是 RAG（Retrieval-Augmented Generation）的思路。

3. 摘要持久化：将每次会话的最终摘要保存到文件，下次会话时加载。这是本项目摘要压缩策略的自然延伸。

长期记忆的核心挑战是''记什么''和''何时检索''——不是所有对话内容都值得记住，也不是所有历史信息在每次对话中都有用。', '如果你后续想深入学习，可以关注 RAG 技术——它是当前工业界实现长期记忆的主流方案，结合了信息检索和文本生成的优势。', '# 长期记忆的简单示例：基于文件的摘要持久化
import json
import os

class PersistentMemoryAgent:
    """带持久化记忆的简单示例"""
    
    def __init__(self, system_prompt, memory_file="memory.json"):
        self.system_prompt = system_prompt
        self.memory_file = memory_file
        self.long_term_memory = self._load_memory()
        self.messages = self._build_initial_messages()
    
    def _load_memory(self):
        """从文件加载长期记忆"""
        if os.path.exists(self.memory_file):
            with open(self.memory_file, "r", encoding="utf-8") as f:
                return json.load(f)
        return {"user_info": "", "key_facts": []}
    
    def _save_memory(self):
        """保存长期记忆到文件"""
        with open(self.memory_file, "w", encoding="utf-8") as f:
            json.dump(self.long_term_memory, f, ensure_ascii=False, indent=2)
    
    def _build_initial_messages(self):
        """构建初始 messages，注入长期记忆"""
        messages = [{"role": "system", "content": self.system_prompt}]
        if self.long_term_memory["user_info"]:
            messages.append({
                "role": "system",
                "content": f"关于用户的已知信息：{self.long_term_memory[''user_info'']}"
            })
        return messages');

-- learning-card-project4.json: Code Sandbox — 让智能体自己写代码、自己执行
SET @existing_item_pk := (SELECT `item_pk` FROM `learning_item` WHERE `title` = 'Code Sandbox — 让智能体自己写代码、自己执行' LIMIT 1);
DELETE FROM `learning_step` WHERE `item_pk` = @existing_item_pk AND @existing_item_pk IS NOT NULL AND @existing_item_pk <> 56;
DELETE FROM `learning_item` WHERE `item_pk` = @existing_item_pk AND @existing_item_pk IS NOT NULL AND @existing_item_pk <> 56;
INSERT INTO `learning_item` (`item_pk`, `json_id`, `title`, `summary`, `category`, `difficulty`, `duration`, `prerequisites`, `objectives`, `features`, `status`, `template_path`, `author_id`, `published_at`, `created_at`, `updated_at`) VALUES (56, 994792822, 'Code Sandbox — 让智能体自己写代码、自己执行', '从 Code Interpreter 的核心原理出发，系统讲解如何让大模型生成代码、在沙箱中执行、捕获输出并返回模型。深入理解 exec() 与 eval() 的区别、io.StringIO 输出捕获机制、正则代码提取、自我修正循环的实现，以及代码执行超时控制与生产环境安全隔离方案。', '智能体', '高级', '3.5小时', '项目一完成（掌握 API 调用）、Python 基础（了解 exec/eval 概念、异常处理）', CAST('["理解 Code Sandbox 的核心思想：模型写代码 → 系统执行 → 结果回传","掌握 Python 的 exec() 和 io.StringIO 实现代码执行与输出捕获","能够用正则表达式从模型回复中精确提取代码块","实现带自我修正的代码智能体，理解错误反馈循环的工作机制","掌握代码执行超时控制方法","理解生产环境中代码沙箱的安全隔离要求与实现方案"]' AS JSON), CAST('[{"title":"代码执行与输出捕获","description":"使用 exec() 执行字符串代码，通过 io.StringIO 重定向 sys.stdout 来捕获 print 输出，实现代码执行结果的程序化获取。"},{"title":"代码提取与格式化","description":"使用正则表达式从模型返回的自然语言+代码混合内容中精确提取代码块，处理多种格式变体。"},{"title":"自我修正与安全隔离","description":"当代码执行出错时将错误信息返回给模型进行修正，同时理解生产环境中沙箱隔离的必要性。"}]' AS JSON), 'PUBLISHED', 'item-56/template.ipynb', NULL, NOW(), NOW(), NOW()) ON DUPLICATE KEY UPDATE `json_id` = VALUES(`json_id`), `title` = VALUES(`title`), `summary` = VALUES(`summary`), `category` = VALUES(`category`), `difficulty` = VALUES(`difficulty`), `duration` = VALUES(`duration`), `prerequisites` = VALUES(`prerequisites`), `objectives` = VALUES(`objectives`), `features` = VALUES(`features`), `status` = VALUES(`status`), `template_path` = VALUES(`template_path`), `published_at` = COALESCE(`published_at`, VALUES(`published_at`)), `updated_at` = NOW();
DELETE FROM `learning_step` WHERE `item_pk` = 56;
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (56, 1, '理解 Code Sandbox 的核心思想', 'Code Sandbox 的本质是让大模型变成程序员：写代码 → 执行 → 看结果 → 有问题就改。这个流程模拟了人类程序员的日常工作方式。

与直接让模型回答相比，代码执行有三大优势：
1. 计算结果 100% 准确：模型可能算错 1234×5678（因为它在''猜''下一个 token），但 Python 代码的乘法运算不会出错。
2. 能处理真实数据：CSV 解析、JSON 处理、数据库查询等，模型可以直接操作真实世界的数据格式。
3. 可复现可验证：代码是确定性的，同样的输入产生同样的输出，结果可以被第三方验证。

从架构角度看，Code Sandbox 是 Tool Use 的一个特例——''代码执行器''本身就是一个工具。区别在于：普通工具（如天气查询）是预定义的固定函数，而代码执行器能执行模型动态生成的任意代码，灵活性更高。

这个流程涉及三个关键环节：代码生成（模型根据任务写代码）、代码执行（在受控环境中运行）、结果反馈（把输出或错误返回给模型）。', 'Code Sandbox 是 OpenAI Code Interpreter 功能的核心原理。ChatGPT 的''数据分析''功能就是让你在对话框里上传 CSV，它在后台用 Python 处理——本质上就是一个 Code Sandbox。', '');
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (56, 2, '掌握 exec() 与 eval() 的区别', 'Python 提供了两个内置函数来动态执行代码字符串：

exec(code_string)：执行一段代码语句，可以包含任意 Python 语句（赋值、循环、函数定义、类定义等）。exec() 的返回值始终是 None，它的效果体现在对命名空间的修改（如定义了新变量）和副作用（如 print 输出）。

eval(expression)：只执行单个表达式，并返回表达式的值。如 eval(''2+3'') 返回 5。eval() 不能包含赋值语句、循环等复杂语句。

对于 Code Sandbox，我们需要 exec()，因为模型生成的代码通常包含多行语句、变量赋值、函数定义等。exec() 有两个可选参数：globals（全局命名空间字典）和 locals（局部命名空间字典），可以控制代码执行时可访问的变量和函数。

重要安全提示：exec() 执行的代码拥有与主程序相同的权限，可以访问所有变量、导入模块、读写文件。这就是为什么生产环境需要沙箱隔离。', 'exec() 的 globals 参数可以用来限制代码能使用的内置函数。例如 exec(code, {''__builtins__'': {}}) 会禁用所有内置函数（包括 print、len 等），exec(code, {''__builtins__'': {''print'': print}}) 只允许使用 print。', '# exec() vs eval() 的区别
print(exec("x = 2 + 3"))      # 输出 None（exec 无返回值）
print(eval("2 + 3"))           # 输出 5（eval 返回 表达式结果）

# exec() 可以执行复杂语句
exec("""
result = 0
for i in range(1, 101):
    result += i
print(f''1到100的和是: {result}'')
""")

# exec() 的命名空间控制
custom_globals = {"__builtins__": {"print": print, "len": len, "range": range}}
exec("print(''只能使用 print、len、range'')", custom_globals)');
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (56, 3, '实现输出捕获机制', 'exec() 执行的代码中的 print() 输出默认打印到控制台（sys.stdout），无法被程序捕获。我们需要将输出重定向到一个内存缓冲区中。

实现方法：使用 io.StringIO 创建一个''虚拟输出流''（行为类似文件对象，但数据存在内存中），临时替换 sys.stdout 和 sys.stderr。执行流程为：

1. 创建 StringIO 缓冲区
2. 保存原始 sys.stdout 和 sys.stderr
3. 将 sys.stdout 和 sys.stderr 都指向缓冲区
4. 执行代码（exec）
5. 在 finally 块中恢复原始 stdout/stderr（确保即使出错也能恢复）
6. 从缓冲区读取输出内容

返回值设计为一个字典：success（是否成功）、output（捕获的 print 输出）、error（异常信息，成功时为 None）。这种统一格式便于后续处理。', '必须用 try-finally 确保 sys.stdout 被恢复。如果 exec 抛出异常但没有 finally 块，sys.stdout 会永久指向缓冲区，后续所有 print 都''消失''了。', 'import io
import sys

def run_code(code_string):
    """
    在本地执行一段 Python 代码，并捕获其输出。
    
    参数:
        code_string: 要执行的 Python 代码字符串
    返回:
        dict: {"success": bool, "output": str, "error": str|None}
    """
    output_buffer = io.StringIO()
    old_stdout = sys.stdout
    old_stderr = sys.stderr
    sys.stdout = output_buffer
    sys.stderr = output_buffer
    
    try:
        exec(code_string)
        return {
            "success": True,
            "output": output_buffer.getvalue().strip(),
            "error": None
        }
    except Exception as e:
        return {
            "success": False,
            "output": output_buffer.getvalue().strip(),
            "error": f"{type(e).__name__}: {e}"
        }
    finally:
        # 无论如何都要恢复 stdout/stderr
        sys.stdout = old_stdout
        sys.stderr = old_stderr


# 测试
result = run_code("print(''Hello''); print(2 + 3)")
print(f"成功: {result[''success'']}")
print(f"输出: {result[''output'']}")

result_err = run_code("x = 1 / 0")
print(f"成功: {result_err[''success'']}")
print(f"错误: {result_err[''error'']}")');
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (56, 4, '用正则表达式提取代码块', '大模型返回的回复通常是自然语言+代码块混合的格式，如''好的，我来帮你计算：\n```python\n...\n```\n计算完成！''。我们需要从中提取出纯代码。

使用正则表达式匹配 ```python 和 ``` 之间的内容。正则模式 r''```(?:python)?\s*\n(.*?)```'' 的含义：(?:python)? 匹配可选的 ''python'' 标记（非捕获组），\s*\n 匹配标记后的空白和换行，(.*?) 非贪婪匹配代码内容，re.DOTALL 让 . 能匹配换行符。

需要注意的边界情况：模型可能返回不带 python 标记的代码块（只有 ```）、可能返回多个代码块、可能在代码块前后有解释文字。提取后使用 strip() 去除首尾空白。

如果模型没有返回代码块（直接回答了问题），extract_code 返回 None，调用方应直接返回模型的文本回复。', '如果模型返回多个代码块，findall 会返回所有匹配。对于数据分析任务，通常取第一个；对于复杂任务，可能需要合并所有代码块。', 'import re

def extract_code(response_text):
    """
    从大模型的回复中提取 Python 代码块。
    支持 ```python ... ``` 和 ``` ... ``` 两种格式。
    
    返回:
        str|None: 提取的代码，如果没有代码块则返回 None
    """
    pattern = r''```(?:python)?\s*\n(.*?)```''
    matches = re.findall(pattern, response_text, re.DOTALL)
    
    if matches:
        return matches[0].strip()
    return None


# 测试各种格式
samples = [
    # 带 python 标记
    "好的：\n```python\nprint(''hello'')\n```",
    # 不带标记
    "代码如下：\n```\nx = 42\nprint(x)\n```",
    # 多个代码块
    "第一步：\n```python\na = 1\n```\n第二步：\n```python\nb = 2\n```",
]

for s in samples:
    code = extract_code(s)
    print(f"提取结果: {repr(code)}\n")');
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (56, 5, '实现数据分析助手', '数据分析助手的完整流程分为三步：

第一步，设计 System Prompt 让模型只返回代码块（用 ```python 包裹），不要多余解释。Prompt 中明确要求''代码必须用 print() 输出结果''和''不要使用 matplotlib 等画图库''，因为我们需要纯文本输出。

第二步，提取代码并用 run_code() 执行，捕获输出。

第三步，如果执行成功，把输出结果返回给模型，让它用自然语言总结分析结果。这样用户既能得到精确的计算结果（来自代码执行），又能得到易读的文字解释（来自模型总结）。

这个''代码执行 + 自然语言总结''的两阶段模式是 Code Sandbox 的典型应用模式——代码保证准确性，模型保证可读性。', 'System Prompt 中明确要求''只返回代码块''可以大大提高代码提取的成功率。如果模型返回了自然语言+代码混合内容，extract_code 仍然能正确提取。', 'def data_analysis_agent(task, data_context=""):
    """数据分析助手：生成代码 → 执行 → 总结"""
    system_prompt = """你是一个数据分析专家。用户会给你一段数据和任务，你需要：
1. 编写 Python 代码来完成任务
2. 代码必须用 print() 输出结果
3. 只返回代码块（用 ```python 包裹），不要多余的解释
4. 不要使用 matplotlib 等画图库，只用纯文本输出
5. 如果需要处理数据，直接在代码中定义数据"""
    
    user_prompt = f"任务：{task}"
    if data_context:
        user_prompt += f"\n\n数据：\n{data_context}"
    
    # 1. 让模型生成代码
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_prompt}
    ]
    response = client.chat.completions.create(
        model="deepseek-chat",
        messages=messages,
        temperature=0.3  # 低温度，代码更确定
    )
    raw_response = response.choices[0].message.content
    print(f"[模型生成]\n{raw_response}\n")
    
    # 2. 提取并执行代码
    code = extract_code(raw_response)
    if code is None:
        return f"模型未返回代码块。回复内容：{raw_response}"
    
    print(f"[执行代码]\n{code}\n")
    result = run_code(code)
    
    if result["success"]:
        print(f"[执行结果]\n{result[''output'']}\n")
        # 3. 把结果返回给模型做总结
        messages.append({"role": "assistant", "content": raw_response})
        messages.append({"role": "user", "content": f"代码执行成功，输出如下：\n{result[''output'']}\n\n请用自然语言总结分析结果。"})
        summary = client.chat.completions.create(
            model="deepseek-chat",
            messages=messages,
            temperature=0.5
        )
        return summary.choices[0].message.content
    else:
        return f"代码执行出错: {result[''error'']}"');
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (56, 6, '实现自我修正循环', '模型生成的代码不一定一次就跑对。常见的错误类型包括：语法错误（缩进不对、括号不匹配）、运行时错误（除零、类型错误、索引越界）、逻辑错误（算法不对但能运行）、使用了被禁止的库（如 matplotlib）。

自我修正智能体实现了一个自动纠错循环：生成代码 → 执行 → 如果出错，把错误信息和之前的代码一起返回给模型，让它分析原因并修改 → 重新执行，最多重试 N 次。

关键在于 messages 列表的维护：每次重试时，模型需要看到之前的代码（assistant 消息）和错误信息（user 消息），才能有针对性地修改。这种''让模型看报错并修正''的方法，本质上是利用了模型的推理能力来调试代码——模型能理解错误信息的含义并推断修复方案。

实践建议：设置最大重试次数（如 3 次）防止无限循环；每次重试时 temperature 可以略微提高（如 0.3 → 0.5），增加模型尝试不同解法的概率；在错误提示中明确告诉模型''请分析错误原因''，引导它进行反思而非盲目修改。', '自我修正的成功率与错误类型有关：语法错误和简单运行时错误修正率高（>80%），逻辑错误修正率低（模型可能反复犯同样的逻辑错误）。', 'def self_fixing_agent(task, max_retries=3):
    """自我修正代码智能体"""
    system_prompt = """你是一个 Python 编程专家。请编写代码完成任务：
1. 代码必须用 print() 输出结果
2. 只返回代码块（用 ```python 包裹）
3. 不要使用 matplotlib 或网络请求
4. 确保代码没有语法错误"""
    
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": f"请完成以下任务：{task}"}
    ]
    
    for attempt in range(1, max_retries + 1):
        print(f"\n--- 第 {attempt}/{max_retries} 次尝试 ---")
        
        response = client.chat.completions.create(
            model="deepseek-chat",
            messages=messages,
            temperature=0.3
        )
        raw_response = response.choices[0].message.content
        
        code = extract_code(raw_response)
        if code is None:
            print("模型未返回代码块")
            return raw_response
        
        print(f"代码:\n{code}")
        result = run_code(code)
        
        if result["success"]:
            print(f"执行成功！输出: {result[''output'']}")
            # 让模型总结结果
            messages.append({"role": "assistant", "content": raw_response})
            messages.append({"role": "user", "content": f"代码执行成功，输出：\n{result[''output'']}\n\n请用自然语言总结结果。"})
            summary = client.chat.completions.create(
                model="deepseek-chat",
                messages=messages,
                temperature=0.5
            )
            return summary.choices[0].message.content
        else:
            print(f"执行失败: {result[''error'']}")
            # 把错误信息返回给模型修正
            messages.append({"role": "assistant", "content": raw_response})
            messages.append({"role": "user", "content": f"代码执行出错了：\n错误信息: {result[''error'']}\n\n请分析错误原因，修改代码后重新提交。"})
    
    return "任务失败：多次尝试后代码仍然出错。"');
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (56, 7, '代码执行超时控制', '模型生成的代码可能包含无限循环或极耗时的操作（如递归过深、大数据排序）。如果不加限制，exec() 会一直阻塞，导致整个智能体挂起。

Python 中实现超时控制有几种方法：

1. signal 模块（仅 Linux/Mac）：使用 signal.alarm() 设置定时器，超时后抛出 TimeoutError。简单但仅限 Unix 系统。

2. threading 模块（跨平台）：在子线程中执行代码，主线程用 join(timeout) 等待。超时后无法强制终止子线程（Python 的限制），但可以放弃等待并标记为超时。

3. subprocess 模块（推荐）：将代码写入临时文件，用 subprocess.run() 执行，设置 timeout 参数。这是最可靠的跨平台方案，因为子进程可以被强制终止。

本项目使用 signal 方案（简单直观），但提醒生产环境应使用 subprocess 或容器隔离方案。', '在 Windows 上 signal.SIGALRM 不可用。跨平台方案建议用 subprocess：将代码写入临时 .py 文件，用 subprocess.run([''python'', tmpfile], timeout=10, capture_output=True) 执行。', 'import signal

class TimeoutError(Exception):
    pass

def timeout_handler(signum, frame):
    raise TimeoutError("代码执行超时")

def run_code_with_timeout(code_string, timeout_seconds=10):
    """带超时控制的代码执行（仅 Linux/Mac）"""
    output_buffer = io.StringIO()
    old_stdout = sys.stdout
    old_stderr = sys.stderr
    sys.stdout = output_buffer
    sys.stderr = output_buffer
    
    # 设置超时定时器
    old_handler = signal.signal(signal.SIGALRM, timeout_handler)
    signal.alarm(timeout_seconds)
    
    try:
        exec(code_string)
        signal.alarm(0)  # 取消定时器
        return {"success": True, "output": output_buffer.getvalue().strip(), "error": None}
    except TimeoutError:
        return {"success": False, "output": "", "error": f"执行超时（{timeout_seconds}秒限制）"}
    except Exception as e:
        return {"success": False, "output": output_buffer.getvalue().strip(), "error": f"{type(e).__name__}: {e}"}
    finally:
        signal.alarm(0)
        signal.signal(signal.SIGALRM, old_handler)
        sys.stdout = old_stdout
        sys.stderr = old_stderr');
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (56, 8, '理解生产环境中的安全隔离', '本项目使用 exec() 执行代码，仅用于学习演示。在生产环境中，这是极其危险的——模型生成的代码可以：

- 删除或修改文件系统上的任意文件（os.system(''rm -rf /'')）
- 读取敏感信息（如环境变量中的 API Key、数据库密码）
- 发起网络请求（requests.post 向恶意服务器发送数据）
- 消耗大量 CPU/内存导致系统崩溃（如 while True: pass 或分配 100GB 内存）

生产级 Code Sandbox 必须使用隔离环境：

1. Docker 容器（最常用）：每个代码执行任务在一个独立容器中运行，提供进程级隔离、文件系统隔离、网络隔离。容器执行完毕后销毁。
2. gVisor / Firecracker：更轻量级的沙箱方案。gVisor 是 Google 开发的应用内核，拦截系统调用；Firecracker 是 AWS 开发的微型虚拟机，Lambda 和 Fargate 底层都用的它。
3. 云函数（AWS Lambda / 阿里云函数计算）：利用云平台的隔离机制，每次执行在独立环境中运行。

隔离环境应限制：文件系统访问（只读或限定目录）、网络访问（白名单或完全禁止）、CPU/内存使用（cgroup 限制）、执行时间（超时自动终止）。', '即使是''可信''的模型生成的代码也可能包含意外行为（如模型''幻觉''出不存在的 API 导致无限重试），生产环境中永远不要直接用 exec() 执行 LLM 生成的代码。', '# 生产环境的 Docker 沙箱示例（概念代码）
import subprocess
import tempfile
import os

def run_code_in_docker(code_string, timeout=30):
    """在 Docker 容器中执行代码（需要预构建沙箱镜像）"""
    # 将代码写入临时文件
    with tempfile.NamedTemporaryFile(mode=''w'', suffix=''.py'', delete=False) as f:
        f.write(code_string)
        tmpfile = f.name
    
    try:
        # 在 Docker 容器中执行
        result = subprocess.run(
            [
                "docker", "run", "--rm",
                "--network=none",           # 禁止网络访问
                "--memory=256m",            # 限制内存 256MB
                "--cpus=0.5",               # 限制 CPU 使用
                "-v", f"{tmpfile}:/code.py:ro",  # 只读挂载代码文件
                "python-sandbox",           # 沙箱镜像名
                "python", "/code.py"
            ],
            capture_output=True,
            text=True,
            timeout=timeout
        )
        return {
            "success": result.returncode == 0,
            "output": result.stdout.strip(),
            "error": result.stderr.strip() if result.returncode != 0 else None
        }
    except subprocess.TimeoutExpired:
        return {"success": False, "output": "", "error": f"执行超时（{timeout}秒限制）"}
    finally:
        os.unlink(tmpfile)  # 清理临时文件');

-- learning-card-project5.json: Multi-Agent — 多智能体分工协作系统
SET @existing_item_pk := (SELECT `item_pk` FROM `learning_item` WHERE `title` = 'Multi-Agent — 多智能体分工协作系统' LIMIT 1);
DELETE FROM `learning_step` WHERE `item_pk` = @existing_item_pk AND @existing_item_pk IS NOT NULL AND @existing_item_pk <> 57;
DELETE FROM `learning_item` WHERE `item_pk` = @existing_item_pk AND @existing_item_pk IS NOT NULL AND @existing_item_pk <> 57;
INSERT INTO `learning_item` (`item_pk`, `json_id`, `title`, `summary`, `category`, `difficulty`, `duration`, `prerequisites`, `objectives`, `features`, `status`, `template_path`, `author_id`, `published_at`, `created_at`, `updated_at`) VALUES (57, 990035195, 'Multi-Agent — 多智能体分工协作系统', '从单智能体的局限性出发，讲解多智能体系统的核心思想：让多个专业 AI 角色分工合作。深入理解角色定义、消息传递、协作流程三个核心要素，系统掌握串行流水线、辩论模式、主从模式三种经典协作架构的实现方法与适用场景，探讨智能体间上下文传递设计与错误传播问题。', '智能体', '高级', '3.5小时', '项目一至四完成（掌握 Prompt、Tool Use、Memory、Code Sandbox）', CAST('["理解单智能体在复杂任务中的局限性以及多智能体的优势","掌握多智能体系统的三个核心要素：角色定义、消息传递、协作流程编排","能够设计智能体的角色分工与 System Prompt，定义清晰的输入输出接口","实现串行流水线、辩论模式、主从模式三种协作架构","理解智能体间上下文传递的设计方法与错误传播问题","掌握多智能体系统的设计原则与最佳实践"]' AS JSON), CAST('[{"title":"角色分工机制","description":"每个智能体有独立的身份、职责和 System Prompt，专注单一任务比''全能选手''更可靠。角色定义的质量直接决定协作效果。"},{"title":"消息传递与上下文设计","description":"智能体之间通过''消息''通信，一个智能体的输出作为另一个智能体的输入。上下文传递的格式设计是系统可靠性的关键。"},{"title":"协作流程编排","description":"定义智能体的执行顺序和数据流向，包括串行流水线、辩论模式、主从模式等多种架构及其组合。"}]' AS JSON), 'PUBLISHED', 'item-57/template.ipynb', NULL, NOW(), NOW(), NOW()) ON DUPLICATE KEY UPDATE `json_id` = VALUES(`json_id`), `title` = VALUES(`title`), `summary` = VALUES(`summary`), `category` = VALUES(`category`), `difficulty` = VALUES(`difficulty`), `duration` = VALUES(`duration`), `prerequisites` = VALUES(`prerequisites`), `objectives` = VALUES(`objectives`), `features` = VALUES(`features`), `status` = VALUES(`status`), `template_path` = VALUES(`template_path`), `published_at` = COALESCE(`published_at`, VALUES(`published_at`)), `updated_at` = NOW();
DELETE FROM `learning_step` WHERE `item_pk` = 57;
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (57, 1, '理解单智能体的局限性', '单个智能体在处理复杂任务时面临三个核心问题：

1. 角色混乱（Role Confusion）：一个模型又要写文案、又要写代码、又要审核，容易''分心''。System Prompt 越长、要求越多，模型的遵循度越低。实验表明，当 System Prompt 超过 1000 token 时，模型对后期指令的遵循度明显下降。

2. 质量下降（Quality Degradation）：没有''第二双眼睛''检查，错误容易被忽略。单智能体生成的代码没有 review 环节，生成的文案没有校对环节。

3. 难以扩展（Scalability）：任务越复杂，单个 Prompt 越难覆盖所有需求。如果要同时处理需求分析、代码生成、测试编写、文档撰写，一个 Prompt 几乎不可能做好所有事情。

多智能体的核心思想是''分而治之''（Divide and Conquer）——就像一家公司有产品经理、程序员、测试员分工协作。每个智能体专注一个角色，System Prompt 更短更精准，输出质量更高。此外，多智能体系统更容易扩展——新增一个角色只需定义一个新的 Agent 实例，不影响现有角色。', '多智能体不是万能的——简单任务用单智能体更高效（省去了多次 API 调用的延迟和费用）。只有当任务足够复杂、需要多种专业能力时，多智能体的优势才显现。判断标准：如果一个 System Prompt 超过 500 token 还不能清晰描述任务，就该考虑拆分了。', '');
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (57, 2, '设计智能体基类与角色定义', '多智能体系统有三个核心要素：

1. 角色（Role）：每个智能体有自己的身份、职责和 System Prompt。角色定义应包含：身份描述（你是谁）、能力范围（你能做什么）、输出要求（你的输出格式是什么）、边界约束（你不做什么）。

2. 消息传递（Message Passing）：智能体之间通过''消息''通信。一个智能体的输出被格式化为另一个智能体的输入。消息格式的设计至关重要——如果上游输出的格式不符合下游的期望，整个链路就会断裂。

3. 协作流程（Workflow）：定义智能体的执行顺序和数据流向。如''需求→开发→审核→交付''就是一个串行流程。

首先设计一个通用的 Agent 基类，封装 API 调用逻辑。每个具体角色通过不同的 name 和 system_prompt 来实例化。基类的 run() 方法接收任务文本，返回结果文本。', '设计多智能体系统时，先明确任务流程中有哪些''角色''，再定义每个角色的输入输出接口（格式和内容），最后编排执行顺序。接口定义比实现更重要。', 'class Agent:
    """通用智能体基类"""
    
    def __init__(self, name, system_prompt, temperature=0.7):
        self.name = name
        self.system_prompt = system_prompt
        self.temperature = temperature
    
    def run(self, task):
        """接收任务，返回结果"""
        print(f"  [{self.name}] 正在处理...")
        response = client.chat.completions.create(
            model="deepseek-chat",
            messages=[
                {"role": "system", "content": self.system_prompt},
                {"role": "user", "content": task}
            ],
            temperature=self.temperature
        )
        result = response.choices[0].message.content
        print(f"  [{self.name}] 完成。")
        return result
    
    def run_with_history(self, task, history=None):
        """支持传入历史消息的增强版本"""
        messages = [{"role": "system", "content": self.system_prompt}]
        if history:
            messages.extend(history)
        messages.append({"role": "user", "content": task})
        
        response = client.chat.completions.create(
            model="deepseek-chat",
            messages=messages,
            temperature=self.temperature
        )
        return response.choices[0].message.content');
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (57, 3, '实现串行流水线模式', '串行流水线是最基础的多智能体协作模式：A → B → C，依次处理，上游输出是下游输入。

典型场景是软件开发流水线：用户想法 → 产品经理（拆解需求） → 程序员（编写代码） → 输出结果。每个智能体的 System Prompt 要精确定义其职责和输出格式——产品经理输出结构化的需求文档（Markdown 格式），程序员根据需求文档编写代码。

流水线设计的关键是''接口对齐''：上游的输出格式必须与下游的期望输入匹配。如果产品经理输出的需求文档格式不固定，程序员解析起来就很困难。解决方法是在 System Prompt 中明确定义输出格式，甚至给出输出模板。

流水线的质量瓶颈通常在第一个环节——如果产品经理的需求文档不清晰，后续所有环节都会受影响（''垃圾进，垃圾出''）。因此第一个环节的 System Prompt 要最精心设计。', '串行流水线中''上游影响下游''。一个实用的调试技巧：先单独测试每个智能体（给固定输入，检查输出是否符合预期），再串联起来测试整个流水线。', '# 产品经理：负责拆解需求
pm_agent = Agent(
    name="产品经理",
    system_prompt="""你是一个资深产品经理。你的职责是：
1. 接收用户的产品想法
2. 分析核心需求，拆解为具体的功能点
3. 输出一份结构化的技术需求文档

输出格式（严格遵守）：
## 产品概述
（一句话描述）

## 核心功能
1. 功能1：描述
2. 功能2：描述

## 技术方案
- 编程语言：
- 关键算法：

## 输入输出示例
- 输入：xxx
- 输出：xxx""",
    temperature=0.5
)

# 程序员：负责根据需求文档编写代码
dev_agent = Agent(
    name="程序员",
    system_prompt="""你是一个 Python 编程专家。你的职责是：
1. 接收产品经理的需求文档
2. 根据文档中的功能列表，编写完整的 Python 代码
3. 代码要有清晰的函数/类结构
4. 包含测试用例（用 print 输出结果）
5. 只返回代码（用 ```python 包裹）""",
    temperature=0.3
)

# 流水线
def software_pipeline(user_idea):
    """串行流水线：需求 → 开发"""
    print("=" * 50)
    print(f"用户需求：{user_idea}")
    print("=" * 50)
    
    # 1. 产品经理拆解需求
    print("\n[阶段 1] 需求分析")
    spec_doc = pm_agent.run(user_idea)
    print(f"\n需求文档：\n{spec_doc}\n")
    
    # 2. 程序员根据需求文档编写代码
    print("[阶段 2] 代码开发")
    code_result = dev_agent.run(f"请根据以下需求文档编写代码：\n\n{spec_doc}")
    print(f"\n代码结果：\n{code_result}\n")
    
    return spec_doc, code_result');
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (57, 4, '实现辩论模式', '辩论模式适用于需要多角度分析的问题：两个智能体分别扮演正方和反方，进行多轮交锋，最后由''裁判''智能体总结。

与串行流水线不同，辩论模式的数据流是双向的（A ↔ B）。每个智能体需要看到对方的论点才能进行有针对性的反驳。实现关键是维护一个 debate_history 变量，记录所有发言，让每轮辩论都能参考之前的内容。

辩论模式的设计要点：
1. 第一轮是''立论''，各方独立阐述自己的观点；后续轮是''反驳''，需要针对对方的具体论点进行回应。
2. 裁判不参与辩论，只看到完整记录后做最终评审。裁判的 System Prompt 应强调''客观公正''和''综合评价''。
3. 辩论轮数不宜过多（2-3 轮足够），否则容易陷入重复论证。

辩论模式的价值在于''对抗性思考''——通过让模型扮演对立角色，可以发现单向思考容易忽略的问题和漏洞。这在学术讨论、方案评审、决策分析等场景中特别有用。', '辩论模式中，正反方的 System Prompt 应有足够的''立场坚定性''——明确告诉它''你必须为正方/反方辩护，即使你个人不这么认为''，否则模型可能很快''倒戈''。', 'for_agent = Agent(
    name="正方",
    system_prompt="""你是正方辩手。你必须为辩题进行正面论证。
要求：
1. 论点清晰，有逻辑性
2. 用事实和数据支撑
3. 每轮发言控制在 200 字以内
4. 后续轮次必须针对反方的具体论点进行反驳""",
    temperature=0.8
)

against_agent = Agent(
    name="反方",
    system_prompt="""你是反方辩手。你必须为辩题进行反面论证。
要求：
1. 论点清晰，有逻辑性
2. 用事实和数据支撑
3. 每轮发言控制在 200 字以内
4. 后续轮次必须针对正方的具体论点进行反驳""",
    temperature=0.8
)

judge_agent = Agent(
    name="裁判",
    system_prompt="""你是辩论赛的裁判。请客观评价双方的论点。
输出格式：
1. 正方主要论点及评价
2. 反方主要论点及评价
3. 综合判断：哪方论证更有说服力，为什么
4. 最终结论""",
    temperature=0.3
)


def debate(topic, rounds=2):
    """辩论模式：正反方交锋 + 裁判总结"""
    print(f"辩题：{topic}\n")
    debate_history = f"辩题：{topic}\n"
    
    for i in range(1, rounds + 1):
        print(f"--- 第 {i} 轮辩论 ---")
        
        # 正方发言
        if i == 1:
            for_input = f"辩题是：{topic}。请作为正方进行立论。"
        else:
            for_input = f"辩题是：{topic}。\n\n之前的辩论记录：\n{debate_history}\n\n请针对反方的观点进行反驳。"
        
        for_statement = for_agent.run(for_input)
        debate_history += f"\n【正方第{i}轮】\n{for_statement}\n"
        print(f"正方：{for_statement[:80]}...")
        
        # 反方发言
        against_input = f"辩题是：{topic}。\n\n之前的辩论记录：\n{debate_history}\n\n请针对正方的观点进行反驳。"
        against_statement = against_agent.run(against_input)
        debate_history += f"\n【反方第{i}轮】\n{against_statement}\n"
        print(f"反方：{against_statement[:80]}...")
    
    # 裁判总结
    print("\n--- 裁判评审 ---")
    verdict = judge_agent.run(f"以下是完整的辩论记录：\n{debate_history}\n\n请进行评审总结。")
    print(f"\n裁判结论：{verdict}")
    return verdict');
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (57, 5, '实现主从模式与投票模式', '主从模式（Master-Worker）：一个''主管''智能体负责分析任务并分配给多个''下属''智能体，下属各自完成后向主管汇报，主管汇总输出。

主从模式适用于可以并行分解的任务（如同时分析多个维度）。主管的 System Prompt 需要定义任务分解策略和汇总格式。下属之间互不通信，只与主管交互。

投票模式（Voting）：多个智能体各自独立回答同一问题，通过某种机制选出最优答案。常见投票策略：多数投票（选出现次数最多的答案）、评分投票（每个智能体给所有答案打分，选最高分）。投票模式适用于需要高可靠性的决策——单个模型可能出错，但多个独立模型同时犯同样错误的概率很低。

选择协作模式的依据：有明确先后顺序用流水线，需要多角度分析用辩论，需要并行处理用主从，需要高可靠性用投票。', '投票模式中的''多样性''很重要——如果用相同的 temperature 和相同的 System Prompt，多个智能体可能给出高度相似的答案，投票就失去了意义。应该让各智能体有不同的 temperature 或不同的角色视角。', '# 主从模式
def master_worker_pipeline(task, worker_prompts):
    """主从模式：主管分配任务，下属各自完成，主管汇总"""
    master = Agent(name="主管", system_prompt="""你是项目主管。请将以下任务分解为子任务，
分配给不同的团队成员。输出格式：
【成员1-任务名】具体任务描述
【成员2-任务名】具体任务描述""",
        temperature=0.5)
    
    # 1. 主管分解任务
    print("[主管] 分解任务...")
    assignments = master.run(task)
    print(f"任务分配：\n{assignments}\n")
    
    # 2. 各下属独立完成任务
    results = []
    for i, worker_prompt in enumerate(worker_prompts):
        worker = Agent(name=f"成员{i+1}", system_prompt=worker_prompt, temperature=0.5)
        result = worker.run(f"请完成以下任务：\n{task}\n\n你的具体分工见主管分配：\n{assignments}")
        results.append(result)
        print(f"[成员{i+1}] 完成\n")
    
    # 3. 主管汇总
    combined = "\n\n".join([f"成员{i+1}的结果：\n{r}" for i, r in enumerate(results)])
    final = master.run(f"以下是各成员的工作结果：\n{combined}\n\n请汇总为最终报告。")
    return final


# 投票模式
def voting_agent(question, num_voters=3):
    """投票模式：多个智能体独立回答，选最优"""
    voters = []
    for i in range(num_voters):
        voter = Agent(
            name=f"投票者{i+1}",
            system_prompt=f"你是一个独立思考的顾问（视角{i+1}）。请独立回答问题，给出你的答案和理由。",
            temperature=0.5 + i * 0.2  # 不同 temperature 增加多样性
        )
        voters.append(voter)
    
    # 各自独立回答
    answers = [voter.run(question) for voter in voters]
    
    # 用裁判智能体评选最优
    judge = Agent(name="裁判", system_prompt="""请评价以下多个独立回答，选出最佳答案。
输出格式：
最佳回答编号：X
理由：...
最终答案：综合所有回答给出最佳答案""",
        temperature=0.3)
    
    combined_answers = "\n\n".join([f"回答{i+1}：\n{a}" for i, a in enumerate(answers)])
    verdict = judge.run(f"问题：{question}\n\n{combined_answers}")
    return verdict');
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (57, 6, '智能体间上下文传递设计', '多智能体系统中，智能体之间的上下文传递是一个容易被忽视但极其重要的设计问题。

核心挑战：每个智能体只看到自己的 System Prompt 和收到的消息，它不知道其他智能体的存在，也不知道整个系统的目标。因此，传递的消息必须包含足够的上下文信息。

设计原则：
1. 自包含（Self-contained）：每条消息应包含接收方完成任务所需的全部信息，不要假设接收方''已经知道''什么。
2. 格式明确：使用结构化格式（如 Markdown 标题、编号列表）组织传递内容，便于接收方解析。
3. 角色透明：在消息中说明''这条消息来自谁''（如''以下是产品经理的需求文档：''），帮助接收方理解上下文。
4. 信息过滤：不要传递无关信息。如果流水线有 5 个环节，第 3 个环节不需要看到第 1 个环节的所有细节——只传递它需要的部分。

在辩论模式中，上下文传递更复杂——每个智能体需要看到完整的历史记录。但历史记录会随轮次增长，需要控制长度（如只保留最近 2 轮的发言）。', '一个实用的检验方法：把传递给下游智能体的消息单独拿出来，给一个完全不了解系统的人看，他能否理解任务要求？如果不能，说明上下文不够。', '# 上下文传递的好 vs 坏示例

# 坏的传递：信息不足
bad_handoff = "请根据需求写代码"  # 程序员不知道需求是什么

# 好的传递：自包含、格式明确
good_handoff = """以下是产品经理整理的需求文档：

## 产品概述
开发一个命令行计算器工具

## 核心功能
1. 支持加减乘除四则运算
2. 支持括号优先级
3. 支持小数运算

请根据以上需求编写 Python 代码。"""


# 带上下文的流水线
def pipeline_with_context(user_idea):
    """带完整上下文传递的流水线"""
    # 1. 产品经理
    spec = pm_agent.run(user_idea)
    
    # 2. 传递给程序员时，包含完整上下文
    dev_task = f"""你是程序员，负责根据产品经理的需求文档编写代码。

以下是产品经理的需求文档：
{spec}

请编写完整的 Python 代码实现以上需求。"""
    code = dev_agent.run(dev_task)
    
    return spec, code');
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (57, 7, '错误传播与恢复机制', '多智能体系统中的一个严重问题是错误传播（Error Propagation）：上游智能体的错误会沿着流水线放大。

例如：产品经理误解了用户需求（错误1） → 程序员根据错误需求写了错误的代码（错误2） → 最终产出完全偏离用户期望。每一步的错误不是简单的叠加，而是可能被放大。

应对策略：
1. 中间检查点：在流水线的关键环节加入''审核''智能体，检查上游输出是否合理。如产品经理输出需求后，先让一个''技术顾问''审核需求的可行性，再传给程序员。
2. 反馈回路：下游发现问题时，可以将问题反馈给上游重新处理。如程序员发现需求文档有歧义，可以要求产品经理澄清。
3. 异常处理：每个智能体的 run() 方法应包含错误处理，避免一个智能体出错导致整个系统崩溃。
4. 超时保护：为每个智能体设置超时，避免某个环节卡住导致整个流水线停滞。

在实际系统中，错误恢复的成本（额外的 API 调用）需要与产出质量之间取得平衡。', '设计多智能体系统时，建议先实现最简单的两智能体协作，验证流程后再增加更多角色。每增加一个角色，系统的复杂度和出错概率都会增加。', 'class RobustAgent(Agent):
    """带错误处理的健壮智能体"""
    
    def run(self, task, timeout_retries=2):
        for attempt in range(timeout_retries):
            try:
                print(f"  [{self.name}] 第 {attempt+1} 次尝试...")
                response = client.chat.completions.create(
                    model="deepseek-chat",
                    messages=[
                        {"role": "system", "content": self.system_prompt},
                        {"role": "user", "content": task}
                    ],
                    temperature=self.temperature
                )
                result = response.choices[0].message.content
                
                # 检查输出是否为空或过短
                if not result or len(result) < 10:
                    print(f"  [{self.name}] 输出过短，重试...")
                    continue
                
                return result
            except Exception as e:
                print(f"  [{self.name}] 出错: {e}")
                if attempt == timeout_retries - 1:
                    return f"[{self.name}] 处理失败: {e}"
        return f"[{self.name}] 多次重试后仍失败"


def pipeline_with_review(user_idea):
    """带审核环节的流水线"""
    # 1. 产品经理
    spec = pm_agent.run(user_idea)
    
    # 2. 审核员检查需求文档
    reviewer = RobustAgent(name="审核员",
        system_prompt="""你是技术审核员。请检查以下需求文档：
1. 需求是否清晰明确？
2. 功能列表是否完整？
3. 是否有歧义或遗漏？

如果通过审核，输出：【通过】
如果有问题，输出：【修改建议】+ 具体建议""",
        temperature=0.3)
    
    review = reviewer.run(f"请审核以下需求文档：\n{spec}")
    
    if "【通过】" in review:
        # 3. 审核通过，继续流水线
        code = dev_agent.run(f"请根据以下需求编写代码：\n{spec}")
        return spec, code
    else:
        # 4. 审核未通过，让产品经理修改
        print(f"审核意见：{review}")
        revised_spec = pm_agent.run(f"原始需求：\n{spec}\n\n审核意见：{review}\n\n请根据审核意见修改需求文档。")
        code = dev_agent.run(f"请根据以下需求编写代码：\n{revised_spec}")
        return revised_spec, code');
INSERT INTO `learning_step` (`item_pk`, `step_no`, `title`, `description`, `tip`, `code`) VALUES (57, 8, '多智能体设计原则与最佳实践', '设计多智能体系统应遵循以下原则：

1. 单一职责（Single Responsibility）：每个智能体只负责一件事。System Prompt 要精准定义角色边界，避免一个智能体承担过多职责。判断标准：能否用一句话描述这个智能体的职责？如果不能，说明职责太宽泛。

2. 明确接口（Clear Interfaces）：定义清楚每个智能体的输入格式和输出格式，确保上下游能正确对接。接口定义应包含：输入是什么（文本？JSON？代码？）、输出格式是什么（Markdown？纯文本？代码块？）、输出的长度限制。

3. 错误隔离（Error Isolation）：一个智能体出错不应导致整个系统崩溃。在每个智能体的 run() 方法中加入异常处理，返回有意义的错误信息。

4. 可观测性（Observability）：记录每个智能体的输入输出，便于调试和优化。在 run() 方法中打印日志，或将中间结果保存到文件。

5. 渐进式扩展（Incremental Scaling）：先实现最简单的两个智能体协作，验证流程后再增加更多角色。每增加一个角色，都要单独测试它的输入输出是否符合预期。

6. 成本意识（Cost Awareness）：多智能体意味着多次 API 调用。3 个智能体的流水线至少需要 3 次 API 调用（可能更多，如果有审核/重试环节）。在设计时要考虑 token 消耗和延迟。', '多智能体系统的调试比单智能体复杂得多。建议：(1) 每个智能体单独测试；(2) 在 run() 方法中打印详细的中间结果；(3) 用固定的测试用例验证整个流水线；(4) 记录每次调用的 token 消耗用于成本分析。', '# 完整的多智能体系统示例：带日志记录
class LoggedAgent(Agent):
    """带日志记录的智能体"""
    
    def __init__(self, name, system_prompt, log_file="agent_log.txt"):
        super().__init__(name, system_prompt)
        self.log_file = log_file
    
    def run(self, task):
        print(f"\n{''=''*40}")
        print(f"[{self.name}] 收到任务:")
        print(f"  输入: {task[:100]}...")
        
        result = super().run(task)
        
        print(f"  输出: {result[:100]}...")
        print(f"{''=''*40}\n")
        
        # 记录日志
        with open(self.log_file, "a", encoding="utf-8") as f:
            f.write(f"\n[{self.name}]\n输入: {task}\n输出: {result}\n")
        
        return result


# 使用示例
print("=== 多智能体协作系统 ===")
print("角色: 产品经理 → 审核员 → 程序员")

result = pipeline_with_review("做一个命令行计算器，支持加减乘除")
print(f"\n最终产出:\n{result[1]}")');

ALTER TABLE `learning_item` AUTO_INCREMENT = 58;
