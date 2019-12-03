#!/bin/sh

#pkg install
pkg install subversion libxml2 libxslt rubygem-thin rubygem-puma rubygem-pkg-config rubygem-bundler nano

#svn co redmine41
cd /usr/local/www && svn co -q --trust-server-cert --non-interactive https://svn.redmine.org/redmine/branches/4.1-stable redmine-4.1

# Enable the service
chmod +x /usr/local/etc/rc.d/redmine41
sysrc -f /etc/rc.conf mysql_enable="YES"
sysrc -f /etc/rc.conf redmine_enable="YES"
sysrc -f /etc/rc.conf nginx_enable="YES"

INSTALLPATH="/usr/local/www/redmine-4.1"

if [ ! -d "$INSTALLPATH" ] ; then
  mkdir -p ${INSTALLPATH}
fi

chown -R www:www ${INSTALLPATH}

# Start the service
service mysql-server start 2>/dev/null
service redmine41 start 2>/dev/null
service nginx start 2>/dev/null

USER="redmine41"
DB="redmine41"

# Save the config values
echo "$DB" > /root/dbname
echo "$USER" > /root/dbuser
export LC_ALL=C
cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1 > /root/dbpassword
PASS=`cat /root/dbpassword`

echo "Database Name: $DB"
echo "Database User: $USER"
echo "Database Password: $PASS"

# Configure mysql
mysql -u root <<-EOF
UPDATE mysql.user SET Password=PASSWORD('${PASS}') WHERE User='root';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';
CREATE DATABASE ${DB} CHARACTER SET utf8;
CREATE USER '${USER}'@'localhost' IDENTIFIED BY '${PASS}';
GRANT ALL PRIVILEGES ON ${DB}.* TO '${USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

sed -e 's|["'\'']||g' ${INSTALLPATH}/config/database.yml.example > ${INSTALLPATH}/config/database.yml

# Set db password for redmine
sed -i '' "s|root|${USER}|g" ${INSTALLPATH}/config/database.yml
sed -i '' "s|password: |password: ${PASS}|g" ${INSTALLPATH}/config/database.yml

# Precompile the assets
cd ${INSTALLPATH}
bundle config build.nokogiri --use-system-libraries
bundle install --without development test
bundle exec rake generate_secret_token
bundle exec rake db:migrate RAILS_ENV=production

chmod o-rwx ${INSTALLPATH}

service redmine41 restart 2>/dev/null
service nginx restart 2>/dev/null

echo "Database Name: $DB" > /root/PLUGIN_INFO
echo "Database User: $USER" >> /root/PLUGIN_INFO
echo "Database Password: $PASS" >> /root/PLUGIN_INFO
echo "Please open the URL and Login with Username: admin, Password: admin" >> /root/PLUGIN_INFO

