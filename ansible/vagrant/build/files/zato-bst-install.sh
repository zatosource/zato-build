#!/bin/bash

zato stop /opt/zato/env/qs-1/server1
zato stop /opt/zato/env/qs-1/server2

if [ ! -d /opt/zato/zato-labs ]
then
    git clone https://github.com/zatosource/zato-labs.git
fi

cd /opt/zato/zato-labs/bst
make

ln -s /opt/zato/zato-labs/bst/bst-env/lib/python2.7/site-packages/blockdiag /opt/zato/2.0.7/zato_extra_paths
ln -s /opt/zato/zato-labs/bst/bst-env/lib/python2.7/site-packages/funcparserlib /opt/zato/2.0.7/zato_extra_paths
ln -s /opt/zato/zato-labs/bst/bst-env/lib/python2.7/site-packages/PIL /opt/zato/2.0.7/zato_extra_paths
ln -s /opt/zato/zato-labs/bst/bst-env/lib/python2.7/site-packages/webcolors.py /opt/zato/2.0.7/zato_extra_paths
ln -s /opt/zato/zato-labs/bst/src/zato/bst/__init__.py /opt/zato/2.0.7/zato_extra_paths/zato_bst.py

mkdir -p /opt/zato/env/qs-1/server1/config/repo/proc/bst
mkdir -p /opt/zato/env/qs-1/server2/config/repo/proc/bst

cp /opt/zato/zato-labs/bst/sample.txt /opt/zato/env/qs-1/server1/config/repo/proc/bst
cp /opt/zato/zato-labs/bst/sample.txt /opt/zato/env/qs-1/server2/config/repo/proc/bst

zato start /opt/zato/env/qs-1/server1
sleep 60
zato start /opt/zato/env/qs-1/server2
sleep 60

cp /opt/zato/zato-labs/bst/src/zato/bst/services.py /opt/zato/env/qs-1/server1/pickup-dir
sleep 30
cp /opt/zato/zato-labs/bst/src/zato/bst/services.py /opt/zato/env/qs-1/server2/pickup-dir
sleep 30

sed -i '/startup_services_first_worker/a \
labs.proc.bst.definition.startup-setup=' \
/opt/zato/env/qs-1/server1/config/repo/server.conf

sed -i '/startup_services_first_worker/a \
labs.proc.bst.definition.startup-setup=' \
/opt/zato/env/qs-1/server2/config/repo/server.conf

# Generate a random password...
uuidgen > /opt/zato/random_password.txt
# ...and replace a variable with the password.
sed -i 's/$BST_PASSWORD/'\"$(cat /opt/zato/random_password.txt)\"'/g' \
       /opt/zato/zato-labs/bst/bst-enmasse.json

zato enmasse /opt/zato/env/qs-1/server1/ --input /opt/zato/zato-labs/bst/bst-enmasse.json --import --replace-odb-objects
zato enmasse /opt/zato/env/qs-1/server2/ --input /opt/zato/zato-labs/bst/bst-enmasse.json --import --replace-odb-objects

curl http://bst:`cat /opt/zato/random_password.txt`@localhost:11223/bst/get-definition-list
