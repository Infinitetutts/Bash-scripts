#!/bin/bash

###############################################
### Description: Basic web server backups   ###
### Author: Infinite                        ###
###############################################

# Crontab --->   0 5 */2  *  * bash /home/ubuntu/web_backup/backup.sh
# Deletes backups older than 16 days


BACKUP_DIR="/home/ubuntu/web_backups/backups"
WEB_DIR="/var/www/"
APACHE_DIR="/etc/apache2/sites-available/"
DROPBOX_UPLOADER="/home/ubuntu/Dropbox-Uploader/dropbox_uploader.sh"
DROPBOX_CLOUD_DIR="server_backups/iandi"
DBUSER="root"
DBPASS="nsaproofpass"
DB="jahdb"


# Run backups
mysqldump -u $DBUSER -p$DBPASS $DB > $BACKUP_DIR/wikimedia.$(date +%Y-%m-%d).sql
cd $BACKUP_DIR && tar -zcvf www.$(date +%Y-%m-%d).tar.gz $WEB_DIR $APACHE_DIR

# Upload to dropbox
bash $BACKUP_DIR/*.sql server_backups/iandi
bash $DROPBOX_UPLOADER upload $BACKUP_DIR/*.tar.gz $DROPBOX_CLOUD_DIR

# Get directory listings
mapfile -t DROPBOX_LIST < <(bash $DROPBOX_UPLOADER list $DROPBOX_CLOUD_DIR)
mapfile -t OLD_BACKUPS < <(find $BACKUP_DIR -type f \( -name "*.sql" -o -name "*.tar.gz" \) -mtime +16)
echo "Old Backups"
echo ${OLD_BACKUPS[*]}

# Remove First element in array [Unwanted Dropboxtext]
DROPBOX_LIST=("${DROPBOX_LIST[@]:1}")
echo -e "\nDropbox List"
echo ${DROPBOX_LIST[*]}

# Remove old backups from Dropbox

# Format Dropbox directory listenings
COUNT=0
DROPBOX_FILES=""
DROPBOX_DATES=""

for i in "${DROPBOX_LIST[@]}"
do
    # Filter file names only
    DROPBOX_FILES[$COUNT]=$(echo $i | awk '{print $3}')
    DROPBOX_DATES[$COUNT]=$(echo $i | awk '{print $3}'|cut -d . -f 2)

	((COUNT++))
done

# Delete old backups on Dropbox
echo -e "\n\nOld FIles\n\n"
OLD_FILE=""
COUNT=0

for i in "${OLD_BACKUPS[@]}"
do
    OLD_FILE[$COUNT]=$(echo $i | cut -d / -f 5)
    bash $DROPBOX_UPLOADER delete $DROPBOX_CLOUD_DIR/${OLD_FILE[$COUNT]}
    rm $i

	((COUNT++))
done

