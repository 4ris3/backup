# Backup Script

This script is used for creating backups of specified folders and enables automatic backup of folders to a designated directory. It also allows adding folders to an auto-backup list for scheduled backups.

## Features

1. **Manual Backup Creation:**
   - The user inputs the path of the folder they want to back up.
   - If the folder exists, it creates a backup in the `/backup/` directory.
   - The backup is named with the date and time to avoid overwriting previous backups.

2. **Adding Folders to Auto-Backup List:**
   - The script allows adding a folder to the auto-backup list.
   - Folders in this list will automatically be backed up to `/backup/` at specified intervals.

3. **Automatic Backup Creation:**
   - The script creates a file `auto-backup-list.txt` containing a list of folders for auto-backup.
   - An auto-backup script (`auto-backup.sh`) is responsible for performing the backup of these folders on a regular basis (e.g., via cron jobs).

## Requirements

- Bash 4.0+
- Administrator (sudo) permissions to create directories in `/backup/`.
- The `/backup/` folder must exist or be created by the script.

## Installation

1. Copy the script to your system, for example, to the `~/backup-script/` directory.
2. Grant execute permissions to the script:
   ```bash
   chmod +x backup-script.sh