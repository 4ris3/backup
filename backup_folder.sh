#!/bin/bash

create_backup() {
    echo "Put folder path to backup:"
    read BACKUP_FOLDER_PATH

    if [ ! -d "$BACKUP_FOLDER_PATH" ]; then
        echo "Wrong path"
        return
    fi

    echo "Check your PATH: $BACKUP_FOLDER_PATH (y/n):"
    read YES_NO_CHECK_PATH
    YES_NO_CHECK_PATH=$(echo "$YES_NO_CHECK_PATH" | tr '[:upper:]' '[:lower:]')

    BACKUP_DATE=$(date +'%d-%m-%Y-%R')

    if [ "$YES_NO_CHECK_PATH" = "y" ]; then
        if [ -d "$BACKUP_FOLDER_PATH" ]; then
            echo "Directory exists, now we made some magic..."
            FOLDER_NAME=$(basename "$BACKUP_FOLDER_PATH")
            FULL_BACKUP_PATH="/backup/$FOLDER_NAME/$FOLDER_NAME-$BACKUP_DATE"

            if [ -d "$FULL_BACKUP_PATH" ]; then
                echo "Backup already exists. Wait one minute before you create next backup."
            else
                sudo mkdir -p "$FULL_BACKUP_PATH"
                sudo cp -r "$BACKUP_FOLDER_PATH"/* "$FULL_BACKUP_PATH"
                echo "Done! $FULL_BACKUP_PATH"
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
        FOLDER_NAME=\$(basename "\$line")
        BACKUP_FOLDER="/backup/\$FOLDER_NAME/\$FOLDER_NAME-\$DATE.auto"
        sudo mkdir -p "\$BACKUP_FOLDER"
        sudo cp -r "\$line"/* "\$BACKUP_FOLDER" 2>/dev/null
        echo "Backup completed for: \$line"
    else
        echo "Directory does not exist: \$line"
    fi
done < "\$BACKUP_TXT_FILE"

EOF_SCRIPT

    sudo mv /tmp/auto-backup.sh /backup/auto-backup/
    sudo chmod +x /backup/auto-backup/auto-backup.sh
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
    run_auto_backup
fi