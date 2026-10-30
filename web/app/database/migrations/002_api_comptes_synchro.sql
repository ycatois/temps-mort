-- Compte coach et synchronisation de l'app (docs/compte-et-synchro.md). MariaDB 10.6+ (o2switch).
-- Le serveur ne connaît ni les équipes ni les matchs : il garde le JSON envoyé par l'app, document par document.

CREATE TABLE IF NOT EXISTS coaches (
    id            INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    email         VARCHAR(190)    NOT NULL,
    password_hash VARCHAR(255)    NOT NULL,
    rev           BIGINT UNSIGNED NOT NULL DEFAULT 0,   -- dernière révision attribuée à ses documents
    created_at    DATETIME        NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_coach_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Un jeton par appareil connecté ; seule son empreinte SHA-256 est stockée.
CREATE TABLE IF NOT EXISTS devices (
    id           INT UNSIGNED NOT NULL AUTO_INCREMENT,
    coach_id     INT UNSIGNED NOT NULL,
    token_hash   CHAR(64)     NOT NULL,
    name         VARCHAR(100) NOT NULL,
    created_at   DATETIME     NOT NULL,
    last_seen_at DATETIME     NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_device_token (token_hash),
    KEY ix_device_coach (coach_id),
    CONSTRAINT fk_device_coach FOREIGN KEY (coach_id) REFERENCES coaches (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Code de réinitialisation du mot de passe : 6 chiffres, 10 minutes, empreinte HMAC.
CREATE TABLE IF NOT EXISTS reset_codes (
    email      VARCHAR(190) NOT NULL,
    code_hash  CHAR(64)     NOT NULL,
    expires_at DATETIME     NOT NULL,
    attempts   INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Limites de tentatives (connexion, envoi de codes) : une ligne par tentative, purgée au fil de l'eau.
CREATE TABLE IF NOT EXISTS rate_limits (
    id         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    bucket     CHAR(64)        NOT NULL,
    created_at DATETIME        NOT NULL,
    PRIMARY KEY (id),
    KEY ix_rate_bucket (bucket, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Documents de l'app : équipe, match, événements d'un match, composition type, schéma tactique.
-- Supprimé = pierre tombale : data effacée, seule la marque reste pour les autres appareils.
CREATE TABLE IF NOT EXISTS documents (
    coach_id   INT UNSIGNED    NOT NULL,
    -- Identifiants créés par l'app : comparés à l'octet près (« abc » et « ABC » sont deux documents).
    id         VARCHAR(100)    CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    kind       VARCHAR(20)     NOT NULL,
    rev        BIGINT UNSIGNED NOT NULL,
    deleted    TINYINT(1)      NOT NULL DEFAULT 0,
    data       MEDIUMTEXT      NULL,
    updated_at DATETIME        NOT NULL,
    PRIMARY KEY (coach_id, id),
    KEY ix_document_rev (coach_id, rev),
    CONSTRAINT fk_document_coach FOREIGN KEY (coach_id) REFERENCES coaches (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
