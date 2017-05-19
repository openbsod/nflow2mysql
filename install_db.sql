-- Create new database and use it
CREATE DATABASE `flow` CHARACTER SET utf16;
USE `flow`;
-- Create user netflow with password nerflow and grant privileges
CREATE USER 'netflow'@'localhost' IDENTIFIED BY PASSWORD '*993AA45E0B64915AFBD1A5BE5713FD509A8E6C2C';
GRANT ALL PRIVILEGES ON `flow` . * TO 'netflow'@'localhost' WITH GRANT OPTION;
-- Create table for templates
CREATE TABLE IF NOT EXISTS `devices` (
`device_id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
`device_header` VARCHAR(100),
`device_description` VARCHAR(100),
`device_data` VARCHAR(100)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `templates` (
`device_id` INT UNSIGNED NOT NULL,
`template_id` INT UNSIGNED NOT NULL,
`template_header` VARCHAR(100),
`template_data` VARCHAR(1000),
`template_format` VARCHAR(1000)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `v5` (
`id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
`device_id` INT UNSIGNED NOT NULL,
`datetime` INT UNSIGNED,
`sysuptime` INT UNSIGNED,
`srcaddr` INT UNSIGNED,
`dstaddr` INT UNSIGNED,
`nexthop` INT UNSIGNED,
`input` SMALLINT UNSIGNED,
`output` SMALLINT UNSIGNED,
`dpkts` INT UNSIGNED,
`doctets` INT UNSIGNED,
`first` INT UNSIGNED,
`last` INT UNSIGNED,
`srcport` SMALLINT UNSIGNED,
`dstport` SMALLINT UNSIGNED,
`pad1` TINYINT UNSIGNED,
`tcp_flags` TINYINT UNSIGNED,
`prot` TINYINT UNSIGNED,
`tos` TINYINT UNSIGNED,
`src_as` SMALLINT UNSIGNED,
`dst_as` SMALLINT UNSIGNED,
`src_mask` TINYINT UNSIGNED,
`dst_mask` TINYINT UNSIGNED,
`pad2` SMALLINT UNSIGNED
) ENGINE=InnoDB;
