CREATE USER 'canary'@'%' IDENTIFIED BY 'canary';
GRANT SELECT on mydatabase.* to 'canary'@'%';
GRANT INSERT, UPDATE, DELETE on mydatabase.setup_modules to 'canary'@'%';
FLUSH PRIVILEGES;