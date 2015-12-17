#!/bin/bash -eux

# Install BST dependencies
pip install virtualenv
apt-get -y install libjpeg-dev zlib1g-dev

# Clone zato-labs repository
cd /opt/zato
su - zato -c "git clone https://github.com/zatosource/zato-labs.git"

# Compile BST
BST_ROOT=/opt/zato/zato-labs/bst
cd "$BST_ROOT"
su - zato -c "cd $BST_ROOT && make"

# Symlink Python dependencies
su - zato -c "ln -s $BST_ROOT/bst-env/lib/python2.7/site-packages/blockdiag /opt/zato/2.0.7/zato_extra_paths"
su - zato -c "ln -s $BST_ROOT/bst-env/lib/python2.7/site-packages/funcparserlib /opt/zato/2.0.7/zato_extra_paths"
su - zato -c "ln -s $BST_ROOT/bst-env/lib/python2.7/site-packages/PIL /opt/zato/2.0.7/zato_extra_paths"
su - zato -c "ln -s $BST_ROOT/bst-env/lib/python2.7/site-packages/webcolors.py /opt/zato/2.0.7/zato_extra_paths"
su - zato -c "ln -s $BST_ROOT/src/zato/bst/__init__.py /opt/zato/2.0.7/zato_extra_paths/zato_bst.py"

# Generate a random password
su - zato -c "uuidgen > /opt/zato/random_password.txt"
# ...and replace a variable with the password.
su - zato -c "sed -i 's/\$BST_PASSWORD/\"$(cat /opt/zato/random_password.txt)\"/g' $BST_ROOT/bst-enmasse.json"

SERVER1_ROOT=/opt/zato/env/qs-1/server1
SERVER2_ROOT=/opt/zato/env/qs-1/server2

# Prepare a directory to store BST definitions
su - zato -c "mkdir -p $SERVER1_ROOT/config/repo/proc/bst"
su - zato -c "mkdir -p $SERVER2_ROOT/config/repo/proc/bst"

# Copy sample BST definitions
su - zato -c "cp $BST_ROOT/sample.txt $SERVER1_ROOT/config/repo/proc/bst"

# Start Zato servers
su - zato -c "/opt/zato/current/bin/zato start $SERVER1_ROOT"
su - zato -c "/opt/zato/current/bin/zato start $SERVER2_ROOT"
sleep 60

# Hot-deploy BST services
su - zato -c "cp $BST_ROOT/src/zato/bst/services.py $SERVER1_ROOT/pickup-dir"
su - zato -c "cp $BST_ROOT/src/zato/bst/services.py $SERVER2_ROOT/pickup-dir"
sleep 60

# Reconfigure Zato servers
su - zato -c "sed -i '/startup_services_first_worker/a labs.proc.bst.definition.startup-setup=' $SERVER1_ROOT/config/repo/server.conf"
su - zato -c "sed -i '/startup_services_first_worker/a labs.proc.bst.definition.startup-setup=' $SERVER2_ROOT/config/repo/server.conf"

# Import REST channels and their credentials
su - zato -c "zato enmasse $SERVER1_ROOT/ --input $BST_ROOT/bst-enmasse.json --import --replace-odb-objects"

# Stop the servers
sleep 30
su - zato -c "/opt/zato/current/bin/zato stop $SERVER1_ROOT"
su - zato -c "/opt/zato/current/bin/zato stop $SERVER2_ROOT"
sleep 30
