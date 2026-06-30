#!/bin/bash
set -e  # exit immediately if any command fails, instead of continuing on a broken state

apt-get update -y
apt-get install -y gnupg curl

# add mongodb's gpg key and 4.4 repo (outdated version, intentional for this exercise)
wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list
apt-get update

apt-get install -y mongodb-org=4.4.18 mongodb-org-server=4.4.18 mongodb-org-shell=4.4.18 mongodb-org-mongos=4.4.18 mongodb-org-tools=4.4.18
systemctl start mongod
systemctl enable mongod

apt-get install -y awscli  # needed to push backups to S3 later
sleep 10  # give mongod time to fully come up before connecting

# creates an admin user with broad roles across all databases, not just this app's db
# credentials are hardcoded in plaintext below, both here and in the backup script
mongo --eval "db.getSiblingDB('admin').createUser({
  user: 'admin',
  pwd: 'wizlab123',
  roles: [
  { role: 'userAdminAnyDatabase', db: 'admin' },
  { role: 'readWrite', db: 'go-mongodb' },
  { role: 'readWriteAnyDatabase', db: 'admin' }
]
})"

# binds mongod to all interfaces instead of just localhost, combined with the SG rule
# this means anything that can reach port 27017 over the network can attempt to connect
sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf

# enables auth so a username/password is required, then restarts to apply both config changes
sed -i 's/#security:/security:\n  authorization: enabled/' /etc/mongod.conf
systemctl restart mongod

###### backup procedure ######

cat > /usr/local/bin/mongo-backup.sh << 'EOF'
#!/bin/bash
# dumps the go-mongodb database using the admin user, plaintext credential in the URI
mongodump --uri "mongodb://admin:wizlab123@localhost:27017/go-mongodb?authSource=admin" --out=/tmp/mongobackup
aws s3 cp /tmp/mongobackup s3://wiz-mongo-backups-tyler/ --recursive
rm -rf /tmp/mongobackup  # clean up local copy, only need it in S3
EOF

chmod +x /usr/local/bin/mongo-backup.sh
echo "0 0 * * * /usr/local/bin/mongo-backup.sh" | crontab -