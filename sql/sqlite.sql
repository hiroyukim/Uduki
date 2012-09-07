CREATE TABLE IF NOT EXISTS sessions (
    id           CHAR(72) PRIMARY KEY,
    session_data TEXT
);

CREATE TABLE diary (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    body         TEXT,
    created_on   TEXT UNIQUE,
    updated_at   TEXT
);
