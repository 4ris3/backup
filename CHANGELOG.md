# Changelog

All notable changes to this project will be documented in this file.

## [1.1.0] - 2024-01-30
### Added
- Systemd configuration (`auto-backup.service`, `auto-backup.timer`) to automate backup processes at 08:00 every day and restart the system. You can change it in `/etc/systemd/system/auto-backup.timer`. Enjoy :)

## [1.2.0] - 2024-02-12
### Added
- .gitignore
- -help flag
- Improved automation with $1 (path) and $2 (-auto)
### Change
- Backup_folder.sh now moves to /usr/local/bin/ after first use