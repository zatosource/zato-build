#!/bin/bash
PY_BINARY=$1

# If it starts with "python2" then we install extra pip dependencies for Python 2.7,
# otherwise, extra dependencies for Python 3.x will be installed.
if [[ $(${PY_BINARY} -c 'import sys; print(sys.version_info[:][0])') -eq 2 ]]
then
    HAS_PYTHON2=1
    HAS_PYTHON3=0
    EXTRA_REQ_VERSION=27
else
    HAS_PYTHON2=0
    HAS_PYTHON3=1
    EXTRA_REQ_VERSION=3
fi

# Apply patches.
patch -p0 -d eggs < patches/butler/__init__.py.diff
patch -p0 -d eggs < patches/configobj.py.diff
patch -p0 -d eggs < patches/gunicorn/arbiter.py.diff
patch -p0 -d eggs < patches/gunicorn/glogging.py.diff
patch -p0 -d eggs < patches/gunicorn/workers/base.py.diff
patch -p0 -d eggs < patches/outbox/outbox.py.diff
patch -p0 -d eggs < patches/outbox/outbox.py2.diff
patch -p0 -d eggs < patches/outbox/outbox.py3.diff
patch -p0 -d eggs < patches/outbox/outbox.py4.diff
patch -p0 -d eggs < patches/psycopg2/__init__.py.diff --forward || true
patch -p0 -d eggs < patches/redis/redis/connection.py.diff
patch -p0 -d eggs < patches/requests/models.py.diff
patch -p0 -d eggs < patches/requests/sessions.py.diff
patch -p0 -d eggs < patches/sqlalchemy/sql/crud.py.diff
patch -p0 -d eggs < patches/ws4py/server/geventserver.py.diff

if [ $HAS_PYTHON2 == 1 ]
then
    patch -p0 -d eggs < patches/jsonpointer/jsonpointer.py.diff
    patch -p0 -d eggs < patches/anyjson/__init__.py.diff
    patch -p0 -d eggs < patches/oauth/oauth.py.diff
fi
