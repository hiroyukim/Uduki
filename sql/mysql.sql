-- DROP   DATABASE if exists uduki;
-- CREATE DATABASE uduki DEFAULT CHARACTER SET utf8;
-- use uduki;

CREATE TABLE IF NOT EXISTS sessions (
    id           CHAR(72) PRIMARY KEY,
    session_data TEXT
);

CREATE TABLE diary (
    id           int(10) unsigned NOT NULL auto_increment,
    body         TEXT,
    created_on   date         NOT NULL,
    updated_at   TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE created_on (created_on)
) ENGINE=InnoDB DEFAULT CHARSET=utf8; 

CREATE TABLE tag (
    id     int(10)        unsigned NOT NULL auto_increment, 
    name   varchar(255)   NOT NULL,
    updated_at   TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE diary_tag (
    id       int(10)        unsigned NOT NULL auto_increment, 
    diary_id int(10)      NOT NULL,
    tag_id   int(10)      NOT NULL,
    updated_at   TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX tag_id (tag_id),
    UNIQUE diary_id_tag_id (diary_id,tag_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
