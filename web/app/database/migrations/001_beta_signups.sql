-- Inscriptions à la bêta (site et blog). MariaDB 10.6+ (o2switch).
CREATE TABLE IF NOT EXISTS beta_signups (
    id                INT UNSIGNED NOT NULL AUTO_INCREMENT,
    email             VARCHAR(190) NOT NULL,
    source            VARCHAR(20)  NOT NULL DEFAULT 'site',
    consent_text      VARCHAR(255) NOT NULL,
    ip_hash           CHAR(64)     NOT NULL,
    unsubscribe_token CHAR(32)     NOT NULL,
    created_at        DATETIME     NOT NULL,
    unsubscribed_at   DATETIME     NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_beta_email (email),
    KEY ix_beta_ip_created (ip_hash, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
