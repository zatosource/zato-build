#!/bin/bash

ZATO_ROOT=/opt/zato
BST_ROOT=$ZATO_ROOT/zato-labs/bst

ZATO_SERVERS=( "$@" )
ZATO_SERVER=${ZATO_SERVERS[0]}

if [[ -z "${ZATO_SERVERS[@]}" ]]
then
    echo "You have to pass at least one path to a Zato server to this script."
    exit 0
fi

if [ ! -d $ZATO_ROOT/zato-labs ]
then
    git clone https://github.com/zatosource/zato-labs.git
else
    echo "Aborting: zato-labs directory already exists."
    exit 0
fi

echo "Compiling BST..."
cd $BST_ROOT
make

echo "Symlinking Python dependencies..."
ln -s $BST_ROOT/bst-env/lib/python2.7/site-packages/blockdiag \
      $ZATO_ROOT/current/zato_extra_paths
ln -s $BST_ROOT/bst-env/lib/python2.7/site-packages/funcparserlib \
      $ZATO_ROOT/current/zato_extra_paths
ln -s $BST_ROOT/bst-env/lib/python2.7/site-packages/PIL \
      $ZATO_ROOT/current/zato_extra_paths
ln -s $BST_ROOT/bst-env/lib/python2.7/site-packages/webcolors.py \
      $ZATO_ROOT/current/zato_extra_paths
ln -s $BST_ROOT/src/zato/bst/__init__.py \
      $ZATO_ROOT/current/zato_extra_paths/zato_bst.py
ln -s $BST_ROOT/src/zato/bst/__init__.py \
      $ZATO_ROOT/current/zato_extra_paths/zato_transitions.py

# Generate a random password...
echo "Generating a random password and saving it to a file..."
uuidgen > $ZATO_ROOT/random_password.txt
# ...and replace a variable with the password.
sed -i 's/$BST_PASSWORD/'\"$(cat $ZATO_ROOT/random_password.txt)\"'/g' \
       $BST_ROOT/bst-enmasse.json

# Servers have to be stopped before proceeding
#for SERVER in ${ZATO_SERVERS[@]}
#do
#    echo "Stopping Zato server: "$SERVER
#    /opt/zato/current/bin/zato stop $SERVER
#done

echo "Stopping all Zato components..."
declare -A COMPONENTS
for COMPONENT in "${ZATO_COMPONENTS[@]}"
do
    echo "Stopping ""$COMPONENT"
    /opt/zato/current/bin/zato stop "$COMPONENT"
done
sleep 30

for SERVER in ${ZATO_SERVERS[@]}
do
    echo "Working with Zato server: "$SERVER

    echo "Preparing a directory to store BST definitions..."
    mkdir -p $SERVER/config/repo/proc/bst

    echo "Copying sample BST definitions..."
    cp $BST_ROOT/sample.txt $SERVER/config/repo/proc/bst
done

for COMPONENT in ${ZATO_COMPONENTS[@]}
do
    echo "Starting Zato components..."
    /opt/zato/current/bin/zato start $COMPONENT
done
sleep 60

for SERVER in ${ZATO_SERVERS[@]}
do
    echo "Hot-deploying BST services..."
    cp $BST_ROOT/src/zato/bst/services.py $SERVER/pickup-dir
    sleep 20

    echo "Reconfiguring Zato server..."
    sed -i 's/zato.kvdb.log-connection-info=/zato.kvdb.log-connection-info=\nlabs.proc.bst.definition.startup-setup=/' \
        $SERVER/config/repo/server.conf
done

echo "Importing REST channels and their credentials..."
/opt/zato/current/bin/zato enmasse $ZATO_SERVER/ \
     --input $BST_ROOT/bst-enmasse.json \
     --import --replace-odb-objects

echo "Getting a list of BST deifnitions installed in a cluster..."
curl http://bst:`cat $ZATO_ROOT/random_password.txt`@localhost:11223/bst/get-definition-list
