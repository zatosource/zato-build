#!/bin/bash

rsync -az --delete -e ssh ../vm/${sign_host}/repo vagrant@192.168.103.103:/home/vagrant/${sign_host}
