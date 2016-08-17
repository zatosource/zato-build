#!/bin/bash

ZATO_VERSION=2.0.7
ZATO_ROOT_DIR=$HOME/opt/zato
ZATO_TARGET_DIR=$ZATO_ROOT_DIR/$ZATO_VERSION/code
waiting_time=10

function check_exit_code
{
    if [ $? -eq 0 ]
    then
        echo "Done."
    else
        exit 1
    fi
}

# Install Zato locally
echo "Unpacking Zato..."
tar -xzf zato-2.0.7.tar.gz
check_exit_code

# Add local libs to PATH
$ZATO_TARGET_DIR/set-env-variables.sh
check_exit_code
source $HOME/.bashrc
source $HOME/.bash_profile

echo "Starting redis-server..."
redis-server --daemonize yes
check_exit_code

echo "Creating Zato quickstart environment..."
mkdir -p $HOME/env/qs-1
zato quickstart create $HOME/env/qs-1 sqlite localhost 6379 \
    --kvdb_password '' \
    --verbose
check_exit_code
echo "Wait $waiting_time seconds before proceeding..."
sleep $waiting_time

echo "Enable extra libraries..."
mkdir $ZATO_TARGET_DIR/zato_extra_paths
cp $HOME/extra-libs/config_db.py $ZATO_TARGET_DIR/zato_extra_paths
check_exit_code

echo "Start Zato components."
cd $HOME/env/qs-1
declare -a components=( server1 server2 web-admin )

# First, start haproxy with Zato LB's configuration
echo "Starting haproxy..."
haproxy -D -f $ZATO_TARGET_DIR/zato.config
check_exit_code
echo "Wait $waiting_time seconds..."
sleep $waiting_time

# Next, start the other components
for component in ${components[@]}
do
    echo "Starting $component"
    zato start $component
    if [ ! $component = "web-admin" ]
    then
        waiting_time=20
    fi
    echo "Wait $waiting_time seconds for $component to start..."
    sleep $waiting_time
done

echo "Hot-deploying services."
echo "Copying..."
cp $HOME/services/*.py $HOME/env/qs-1/server1/pickup-dir/
if [ $? -eq 0 ]
then
    echo "The services have been copied over."
    echo "Wait $waiting_time seconds..."
    sleep $waiting_time
    echo "Done."
    echo "Check the server logs for potential errors."
else
    exit 1
fi

echo "Exporting server objects..."
cd $HOME/server-objects
zato enmasse $HOME/env/qs-1/server1 --input ./odb_config.json --export-local
zato enmasse $HOME/env/qs-1/server1 --input ./zato-export-*.json \
    --import --replace-odb-objects
check_exit_code

echo "Starting gunicorn..."
cd $HOME/foxway.foxwayops
gunicorn foxwayid:app --daemon --log-file=portal.log --log-level DEBUG
check_exit_code
