CREATE USER 'reader'@'%' IDENTIFIED BY 'reader';
GRANT SELECT, UPDATE, INSERT, DELETE on mydatabase.* to 'reader'@'%';
FLUSH PRIVILEGES;