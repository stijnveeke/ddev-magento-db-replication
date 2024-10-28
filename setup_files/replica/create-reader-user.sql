CREATE USER 'reader'@'%' IDENTIFIED BY 'reader';
GRANT SELECT on mydatabase.* to 'reader'@'%';
FLUSH PRIVILEGES;