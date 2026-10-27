CREATE DATABASE IF NOT EXISTS tempsmort CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS wordpress CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'tempsmort'@'%' IDENTIFIED BY 'tempsmort';
GRANT ALL PRIVILEGES ON tempsmort.* TO 'tempsmort'@'%';
GRANT ALL PRIVILEGES ON wordpress.* TO 'tempsmort'@'%';
FLUSH PRIVILEGES;
