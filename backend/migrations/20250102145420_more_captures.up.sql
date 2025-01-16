-- Add up migration script here
CREATE TYPE TRIGGER_KIND AS ENUM ('webhook', 'http', 'websocket', 'kafka', 'email');
ALTER TABLE capture ADD COLUMN is_flow BOOLEAN NOT NULL DEFAULT TRUE, ADD COLUMN trigger_kind TRIGGER_KIND NOT NULL DEFAULT 'webhook', ADD COLUMN trigger_extra JSONB;
ALTER TABLE capture ALTER COLUMN is_flow DROP DEFAULT, ALTER COLUMN trigger_kind DROP DEFAULT;
ALTER TABLE capture DROP CONSTRAINT capture_pkey;
ALTER TABLE capture ADD COLUMN id BIGINT PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY;

DROP POLICY see_own ON capture;
DROP POLICY see_member ON capture;
DROP POLICY see_folder_extra_perms_user ON capture;

CREATE POLICY see_from_allowed_runnables ON capture FOR ALL TO windmill_user
USING (
    (capture.is_flow AND EXISTS (
        SELECT 1
        FROM flow
        WHERE flow.workspace_id = capture.workspace_id
        AND flow.path = capture.path
    ))
    OR (NOT capture.is_flow AND EXISTS (
        SELECT 1
        FROM script
        WHERE script.workspace_id = capture.workspace_id
        AND script.path = capture.path
    ))
);


CREATE TABLE capture_config (
    workspace_id VARCHAR(50) NOT NULL,
    path VARCHAR(255) NOT NULL,
    is_flow BOOLEAN NOT NULL,
    trigger_kind TRIGGER_KIND NOT NULL,
    trigger_config JSONB NULL,
    owner VARCHAR(50) NOT NULL,
    email VARCHAR(255) NOT NULL,
    server_id VARCHAR(50) NULL,
    last_client_ping TIMESTAMPTZ NULL,
    last_server_ping TIMESTAMPTZ NULL,
    error TEXT NULL,
    PRIMARY KEY (workspace_id, path, is_flow, trigger_kind),
    FOREIGN KEY (workspace_id) REFERENCES workspace(id) ON DELETE CASCADE
);

ALTER TABLE capture_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY see_from_allowed_runnables ON capture_config FOR ALL TO windmill_user
USING (
    (capture_config.is_flow AND EXISTS (
        SELECT 1
        FROM flow
        WHERE flow.workspace_id = capture_config.workspace_id
        AND flow.path = capture_config.path
    ))
    OR (NOT capture_config.is_flow AND EXISTS (
        SELECT 1
        FROM script
        WHERE script.workspace_id = capture_config.workspace_id
        AND script.path = capture_config.path
    ))
);


GRANT ALL ON capture_config TO windmill_user;
GRANT ALL ON capture_config TO windmill_admin;