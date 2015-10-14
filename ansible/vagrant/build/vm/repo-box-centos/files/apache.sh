#!/bin/bash

# Prepare the box and install Apache
yum -y check-update

# Python bindings are required (because of selinux)
yum -y install libselinux-python

# Install createrepo to manage rpm repository
yum -y install createrepo

# Expect is crucial during package signing,
# because 'rpm' does not give any possibility
# of performing the process in an non-interactive way
yum -y install expect

# Now install Apache with SSL support
yum -y install httpd mod_ssl

# Prepare repo directory structure
if [ ! -f /var/www/repo ]
then
    echo 'Creating repo directory structure'
    cp -r /vagrant/files/repo /var/www
else
    echo 'Directory structure is already there.'
fi

# Create repositories
repo_root=/var/www/repo/stable/2.0/rhel
repo_dirs=($repo_root/el6/i386 $repo_root/el6/x86_64 \
           $repo_root/el7/x86_64)
for dir in ${repo_dirs[*]}
do
    createrepo $dir
done

# Copy public test signing key
cp /vagrant/files/keys/zato-rpm_pub.gpg /var/www/repo

# Replace default ssl.conf with custom one
echo 'Overwriting default Apache SSL configuration file.'
cp -r /vagrant/files/ssl/ssl.conf /etc/httpd/conf.d/ssl.conf
echo 'Done.'

# Copy certificate for our test repo
if [ ! -f /etc/pki/tls/certs/repo-box-centos.crt ]
then
    cp -r /vagrant/files/ssl/repo-box-centos.crt /etc/pki/tls/certs
else
    echo 'Certificate has been set up already.'
fi

# Copy key for our test repo
if [ ! -f /etc/pki/tls/private/repo-box-centos.csr ] \
   && [ ! -f /etc/pki/tls/private/repo-box-centos.key ]
then
    cp -r /vagrant/files/ssl/repo-box-centos.csr \
          /vagrant/files/ssl/repo-box-centos.key \
          /etc/pki/tls/private
else
    echo 'Keys have been set up already.'
fi

# Restart the service
service httpd start

# Set Apache to be launched at startup
chkconfig httpd on

# Configure rpm signing key
gpg --import /vagrant/files/keys/zato-rpm_pub.gpg
gpg --import /vagrant/files/keys/zato-rpm_sec.gpg
rpm --import /vagrant/files/keys/zato-rpm_pub.gpg
echo "%_gpg_name RHEL Repository" > /etc/rpm/macros
