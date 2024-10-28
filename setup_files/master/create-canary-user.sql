CREATE USER 'canary'@'%' IDENTIFIED BY 'canary';
GRANT SELECT, INSERT, UPDATE, DELETE on mydatabase.* to 'canary'@'%';
# REVOKE ALL PRIVILEGES on mydatabase.setup_modules from 'canary'@'%';
FLUSH PRIVILEGES;