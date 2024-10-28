CREATE USER 'monitor'@'%' IDENTIFIED BY 'monitor';
GRANT SELECT on sys.* to 'monitor'@'%';
FLUSH PRIVILEGES;