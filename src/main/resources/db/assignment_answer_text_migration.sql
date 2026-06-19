-- Add text-answer support for ability assessments.
-- Run this on existing deployments before starting the updated application.

USE `labcore`;

SET @has_answer_text = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'assignment_submission'
    AND COLUMN_NAME = 'answer_text'
);

SET @ddl = IF(
  @has_answer_text = 0,
  'ALTER TABLE `assignment_submission` ADD COLUMN `answer_text` text DEFAULT NULL AFTER `status`',
  'SELECT ''assignment_submission.answer_text already exists'' AS message'
);

PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
