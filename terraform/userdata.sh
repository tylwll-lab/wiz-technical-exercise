#!/bin/bash
# set -e sets it to where if any command fails, it exits. Prevents running a bad command and staying up indefinitely.
set -e 
# install packages required for mongodb repo setup
apt-get update -y
apt-get install -y gnupg curl
# adds gpg key so apt trusts the mongodb repo
wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | apt-key add -
# add mongodb 4.4 repo to apt sources
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list
apt-get update
#install mongo with outdated versions to meet the exercise requirement.
apt-get install -y mongodb-org=4.4.18 mongodb-org-server=4.4.18 mongodb-org-shell=4.4.18 mongodb-org-mongos=4.4.18 mongodb-org-tools=4.4.18
systemctl start mongod
systemctl enable mongod
# Install aws cli so that it can copy the mongo backup to the s3 bucket later on
apt-get install -y awscli
sleep 10
# creates admin user with extreme permissions for the exercise.
# application code will access the database with the admin user to update it. Has it via environment variable.
mongo --eval "db.getSiblingDB('admin').createUser({
  user: 'admin',
  pwd: 'wizlab123',
  roles: [
  { role: 'userAdminAnyDatabase', db: 'admin' },
  { role: 'readWrite', db: 'go-mongodb' },
  { role: 'readWriteAnyDatabase', db: 'admin' }
]
})"
# runs the sed command to modify an already set file, changes local host (which mdb listens on by default) to 0.0.0.0
sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf
# enables auth to DB so that a user/pass is required and restarts
sed -i 's/#security:/security:\n  authorization: enabled/' /etc/mongod.conf
systemctl restart mongod

# this is the mongodb dump command to run a backup.
# It then copies the mongo backup to the s3 bucket via the aws plugin, and removes any current backups to save storage space.
cat > /usr/local/bin/mongo-backup.sh << 'EOF'
#!/bin/bash
mongodump --uri "mongodb://admin:wizlab123@localhost:27017/go-mongodb?authSource=admin" --out=/tmp/mongobackup
aws s3 cp /tmp/mongobackup s3://wiz-mongo-backups-tyler/ --recursive
rm -rf /tmp/mongobackup
EOF
# assigns permissions, then echo's a crontab statement into linux so it runs the backup script everyday at midnight.
chmod +x /usr/local/bin/mongo-backup.sh
echo "0 0 * * * /usr/local/bin/mongo-backup.sh" | crontab -
