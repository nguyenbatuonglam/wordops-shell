# nBrand - Backup Server and Upload to Cloud
#!/bin/bash

echo '';
echo 'Starting Backup Script to Google Drive by nBrand team';

TASKNAME=nBrand_VPS

SERVER_NAME=gdrive:$TASKNAME

TIMESTAMP=$(date +"%m-%d-%Y")
WWW_DIR="/var/www"

BACKUP_ROOT="/home/$TASKNAME"

BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"

MYSQL=/usr/bin/mysql
MYSQLDUMP=/usr/bin/mysqldump
SECONDS=0

mkdir -p "$BACKUP_DIR/mysql"

echo "Starting Backup Database";
databases=`$MYSQL -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|mysql)"`

for db in $databases; do
	$MYSQLDUMP --force --opt $db | gzip > "$BACKUP_DIR/mysql/$db.gz" -v
done
echo "Finished";
echo '';

mkdir -p "$BACKUP_DIR/www"

echo "Starting Backup Website";
# Loop through /home directory
for D in $WWW_DIR/*; do
	if [ -d "${D}" ]; then #If a directory
			domain=${D##*/} # Domain name
			echo "- "$domain;
			# zip root of domain
			echo "--- Create "$domain".zip";
				if [ "$domain" == "22222" ] || [ "$domain" == "html" ]; then
				   echo "---- Cancel";
				else
				   zip -r -y $BACKUP_DIR/www/$domain.zip $WWW_DIR/$domain/ -q -x $WWW_DIR/$domain/htdocs/wp-content/cache/**\*
				   echo "---- Done";
				fi
	fi
done
echo "Finished";
echo '';

echo "Starting Backup Nginx Configuration";
cp -r /etc/nginx/ $BACKUP_DIR/nginx/
echo "Finished";
echo '';

echo "Starting Backup Shell Scripts";
mkdir -p "$BACKUP_DIR/shell"
for filename in /root/*.sh; do
        cp $filename $BACKUP_DIR/shell
done

echo "Finished";
echo '';

size=$(du -sh $BACKUP_DIR | awk '{ print $1}')

echo "Starting Uploading Backup to "$SERVER_NAME;
set -x;
rclone copy $BACKUP_DIR $SERVER_NAME/$TIMESTAMP --drive-chunk-size 64M -P -v
set +x;
# echo COMMAND_OUTPUT;
# rclone sync gdrive:179.zip /home/tuonglam --create-empty-src-dirs -P

echo "Clean up Backup directory: "$BACKUP_DIR;
# Clean up
rm -rf $BACKUP_DIR

echo "Clean up Cloud directory";
# find /home/nBrand_backup/* -mtime +6 -type fd -delete
rclone -q --min-age 2w delete "$SERVER_NAME" #Remove all backups older than 2 week
rclone -q --min-age 2w rmdirs "$SERVER_NAME" #Remove all empty folders older than 2 week
# rclone cleanup "$SERVER_NAME" #Cleanup Trash
echo "Finished";
echo '';

duration=$SECONDS
echo "Total $size, $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
echo '';
