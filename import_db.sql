DROP TABLE IF EXISTS question_likes;
DROP TABLE IF EXISTS replies;
DROP TABLE IF EXISTS questions_follows;
DROP TABLE IF EXISTS questions;
DROP TABLE IF EXISTS users;


PRAGMA foreign_keys = ON;

CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    fname TEXT NOT NULL,
    lname TEXT NOT NULL
);

CREATE TABLE questions (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    author_id INTEGER NOT NULL,

    FOREIGN KEY (author_id) REFERENCES users(id)
);

CREATE TABLE questions_follows (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    question_id INTEGER NOT NULL,

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (question_id) REFERENCES questions(id)
);

CREATE TABLE replies (
    id INTEGER PRIMARY KEY,
    question_id INTEGER NOT NULL,
    parent_reply_id INTEGER,
    user_id INTEGER NOT NULL,
    body TEXT,

    FOREIGN KEY (question_id) REFERENCES questions(id),
    FOREIGN KEY (parent_reply_id) REFERENCES replies(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE question_likes (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    question_id INTEGER NOT NULL,

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (question_id) REFERENCES questions(id)
);

INSERT INTO
    users (fname, lname)
VALUES
    ('Nicky', 'Li'),
    ('Casey', 'Brown'),
    ('Barack', 'Obama'),
    ('Connor', 'Baker');

INSERT INTO
    questions (title, body, author_id)
VALUES
    ('Being President', 'Whats it like being President?', (SELECT id FROM users WHERE fname = 'Connor')),
    ('Question about SQL', 'Connor, please help me', (SELECT id FROM users WHERE fname = 'Barack'));

INSERT INTO
    questions_follows (user_id, question_id)
VALUES
    (1, 2),
    (2, 2),
    (1, 1),
    (3, 1),
    (4,1);

INSERT INTO
    replies (question_id, parent_reply_id, user_id, body)
VALUES 
    ((SELECT id FROM questions WHERE title = 'Being President'), NULL, (SELECT id FROM users WHERE fname = 'Casey'), 'Also what it like not being president?');
INSERT INTO
    replies (question_id, parent_reply_id, user_id, body)
VALUES 
    ((SELECT id FROM questions WHERE title = 'Being President'), (SELECT id FROM replies WHERE body = 'Also what it like not being president?'), (SELECT id FROM users WHERE fname = 'Casey'), 'Also what it like not being president?');

INSERT INTO 
    question_likes ( user_id, question_id)
VALUES
    (1, 1),
    (2, 1),
    (3, 1),
    (3, 2),
    (4, 1),
    ((SELECT id FROM users WHERE fname = 'Nicky'), (SELECT id FROM questions WHERE title = 'Question about SQL'));
