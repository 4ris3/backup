#!/bin/bash

if [[ "$1" == "-help" || "$1" == "--help" ]]; then
    echo
    echo "First usage: ./backup_folder.sh [PATH] [-auto]"
    echo "Next uses: backup_folder.sh [PATH] [-auto]"
    echo ""
    echo "Arguments:"
    echo "  [PATH]    - The path to the directory you want to archive."
    echo "  -auto     - Optional argument that enables automatic backup mode."
    echo
    echo ALWAYS USE FULL PATH IF YOU WANT USE -auto FLAG
    echo
    exit 0
fi

BACKUP_FOLDER_PATH="$1"
SECOND_ARGUMENT="$2"
BACKUP_DATE=$(date +'%d-%m-%Y-%R')
FOLDER_NAME=$(basename "$BACKUP_FOLDER_PATH")
FULL_BACKUP_PATH="/backup/$FOLDER_NAME/$FOLDER_NAME-$BACKUP_DATE"


create_backup() {
    if [ -z "$BACKUP_FOLDER_PATH" ]; then
        echo "No path provided, enter it manually:"
        read BACKUP_FOLDER_PATH
        echo "Check your PATH: $BACKUP_FOLDER_PATH (y/n):"
        read YES_NO_CHECK_PATH
        YES_NO_CHECK_PATH=$(echo "$YES_NO_CHECK_PATH" | tr '[:upper:]' '[:lower:]')
        if [ "$YES_NO_CHECK_PATH" = "y" ]; then
            if [ -d "$BACKUP_FOLDER_PATH" ]; then
                echo "Directory exists, now we made some magic..."
                INTERACT_FOLDER_NAME=$(basename "$BACKUP_FOLDER_PATH")
                INTERACT_FULL_BACKUP_PATH="/backup/$INTERACT_FOLDER_NAME/$INTERACT_FOLDER_NAME-$BACKUP_DATE"
                    if [ -d "$INTERACT_FULL_BACKUP_PATH" ]; then
                        echo "Backup already exists. Wait one minute before you create next backup."
                    else
                        sudo mkdir -p "$INTERACT_FULL_BACKUP_PATH"
                        sudo cp -r "$BACKUP_FOLDER_PATH"/* "$INTERACT_FULL_BACKUP_PATH"
                        echo "Done! $INTERACT_FULL_BACKUP_PATH"
                        echo
                        echo "Add a folder to auto-backup? (y/n)"
                        read YES_NO_AUTO_BACKUP
                        YES_NO_AUTO_BACKUP=$(echo "$YES_NO_AUTO_BACKUP" | tr '[:upper:]' '[:lower:]')
                            if [ "$YES_NO_AUTO_BACKUP" = "y" ]; then
                                if grep -Fxq "$BACKUP_FOLDER_PATH" /backup/auto-backup/auto-backup-list.txt; then
                                    echo "Folder is already in the auto-backup list."
                                else
                                    echo "$BACKUP_FOLDER_PATH" | sudo tee -a /backup/auto-backup/auto-backup-list.txt > /dev/null
                                    echo "Folder added to auto-backup list."
                                fi
                            else
                                echo "Copy that!"
                            fi
                        fi
                    fi
                elif [ "$YES_NO_CHECK_PATH" = "n" ]; then
                    echo "Canceled"
        else
            echo "Invalid input. Please enter 'y' or 'n'"
        fi
        
    elif [ ! -d "$BACKUP_FOLDER_PATH" ]; then
        echo "Wrong path"
        exit 1
    else
        if [ -d "$FULL_BACKUP_PATH" ]; then
            echo "Backup already exists. Wait one minute before you create next backup."
        else
            sudo mkdir -p "$FULL_BACKUP_PATH"
            sudo cp -r "$BACKUP_FOLDER_PATH"/* "$FULL_BACKUP_PATH"
            if [ "$SECOND_ARGUMENT" = "-auto" ]; then
                if grep -Fxq "$BACKUP_FOLDER_PATH" /backup/auto-backup/auto-backup-list.txt; then
                    echo "Folder is already in the auto-backup list."
                else
                    echo "$BACKUP_FOLDER_PATH" | sudo tee -a /backup/auto-backup/auto-backup-list.txt > /dev/null
                    echo "Folder added to auto-backup list."
                fi
            fi
        fi
    fi
}

create_auto_backup() {
    cat > /tmp/auto-backup.sh << EOF_SCRIPT
#!/bin/bash
BACKUP_TXT_FILE="/backup/auto-backup/auto-backup-list.txt"
DATE=\$(date +'%d-%m-%Y-%R')

while IFS= read -r line; do
    if [[ -z "\$line" ]]; then
        echo "Empty line encountered, ending backup process."
        exit 1
    fi

    if [[ -d "\$line" ]]; then
        AUTO_FOLDER_NAME=\$(basename "\$line")
        AUTO_BACKUP_FOLDER="/backup/\$AUTO_FOLDER_NAME/\$AUTO_FOLDER_NAME-\$DATE.auto"
        sudo mkdir -p "\$AUTO_BACKUP_FOLDER"
        sudo cp -r "\$line"/* "\$AUTO_BACKUP_FOLDER" 2>/dev/null
        echo "Backup completed for: \$line"
    else
        echo "Directory does not exist: \$line"
    fi
done < "\$BACKUP_TXT_FILE"

EOF_SCRIPT

    sudo mv /tmp/auto-backup.sh /backup/auto-backup/
    sudo chmod +x /backup/auto-backup/auto-backup.sh
}

create_systemd_files() {
touch /tmp/auto-backup.service
touch /tmp/auto-backup.timer

cat > /tmp/auto-backup.service << EOF_SERVICE
[Unit]
Description="Auto backup service"

[Service]
ExecStart=/backup/auto-backup/auto-backup.sh
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF_SERVICE

sudo mv /tmp/auto-backup.service /etc/systemd/system/auto-backup.service

cat > /tmp/auto-backup.timer << EOF_TIMER
[Unit]
Description=Timer for auto backup service

[Timer]
OnCalendar=*-*-* 08:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF_TIMER

sudo mv /tmp/auto-backup.timer /etc/systemd/system/auto-backup.timer

sudo systemctl enable auto-backup.service
sudo systemctl enable auto-backup.timer
sudo systemctl start auto-backup.service
sudo systemctl start auto-backup.timer

}

run_auto_backup() {
    sudo bash /backup/auto-backup/auto-backup.sh
}

AUTO_BACKUP_FOLDER_PATH="/backup/auto-backup"

if [ -d "$AUTO_BACKUP_FOLDER_PATH" ]; then
    create_backup
else
    sudo mkdir -p "$AUTO_BACKUP_FOLDER_PATH"
    sudo touch "$AUTO_BACKUP_FOLDER_PATH/auto-backup-list.txt"
    create_backup
    create_auto_backup
    create_systemd_files
    run_auto_backup
    sudo chmod +x backup_folder.sh
    sudo mv backup_folder.sh /usr/local/bin/backup_folder.sh
fi