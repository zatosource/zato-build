#!/bin/bash

zato stop ./env/qs-1/server1
zato stop ./env/qs-1/server2

if [ ! -d /opt/zato/zato-labs ]
then
    git clone https://github.com/zatosource/zato-labs.git
fi

cd /opt/zato/zato-labs/bst
make

ln -s $PWD/bst-env/lib/python2.7/site-packages/blockdiag /opt/zato/2.0.7/zato_extra_paths
ln -s $PWD/bst-env/lib/python2.7/site-packages/funcparserlib /opt/zato/2.0.7/zato_extra_paths
ln -s $PWD/bst-env/lib/python2.7/site-packages/PIL /opt/zato/2.0.7/zato_extra_paths
ln -s $PWD/bst-env/lib/python2.7/site-packages/webcolors.py /opt/zato/2.0.7/zato_extra_paths
ln -s $PWD/src/zato/bst/__init__.py /opt/zato/2.0.7/zato_extra_paths/zato_bst.py

cd /opt/zato/
mkdir -p ./env/qs-1/server1/config/repo/proc/bst
mkdir -p ./env/qs-1/server2/config/repo/proc/bst

cp /opt/zato/zato-labs/bst/sample.txt /opt/zato/env/qs-1/server1/config/repo/proc/bst
cp /opt/zato/zato-labs/bst/sample.txt /opt/zato/env/qs-1/server2/config/repo/proc/bst

zato start ./env/qs-1/server1
zato start ./env/qs-1/server2

cp /opt/zato/zato-labs/bst/src/zato/bst/services.py ./env/qs-1/server1/pickup-dir
cp /opt/zato/zato-labs/bst/src/zato/bst/services.py ./env/qs-1/server2/pickup-dir

sed -i '/startup_services_first_worker/a \
labs.proc.bst.definition.startup-setup=' \
/opt/zato/env/qs-1/server1/config/repo/server.conf

sed -i '/startup_services_first_worker/a \
labs.proc.bst.definition.startup-setup=' \
/opt/zato/env/qs-1/server2/config/repo/server.conf

# Generate a random password...
uuidgen > /opt/zato/random_password.txt
# ...and replace a variable with the password.
sed -i 's/$BST_PASSWORD/'"$(cat /opt/zato/random_password.txt)"'/g' \
       /opt/zato/zato-labs/bst/bst-enmasse.json

zato enmasse /opt/zato/env/qs-1/server1/ --input /opt/zato/zato-labs/bst/bst-enmasse.json --import --replace-odb-objects
zato enmasse /opt/zato/env/qs-1/server2/ --input /opt/zato/zato-labs/bst/bst-enmasse.json --import --replace-odb-objects

curl http://bst:`cat /opt/zato/random_password.txt`@localhost:11223/bst/get-definition-list
