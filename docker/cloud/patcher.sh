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

if [ $EXTRA_REQ_VERSION == 27 ]
then
    patch -p0 -d eggs < patches/jsonpointer/jsonpointer.py.diff
    patch -p0 -d eggs < patches/anyjson/__init__.py.diff
    patch -p0 -d eggs < patches/oauth/oauth.py.diff
fi

sed -i -e 's|numpy==.*|numpy|' \
    -e 's|toolz==.*|https://github.com/pytoolz/toolz/archive/main.zip#egg=toolz|' \
    requirements.txt

patch -p1 <<-EOF
diff --git a/zato-cli/src/zato/cli/create_scheduler.py b/code/zato-cli/src/zato/cli/create_scheduler.py
index 892cb5f04..4287fcbb3 100644
--- a/zato-cli/src/zato/cli/create_scheduler.py
+++ b/zato-cli/src/zato/cli/create_scheduler.py
@@ -227,7 +227,8 @@ class Create(ZatoCommand):
         zato_well_known_data = cm.encrypt(zato_well_known_data)
         zato_well_known_data = zato_well_known_data.decode('utf8')

-        secret_key = secret_key.decode('utf8')
+        if isinstance(secret_key, (bytes, bytearray)):
+            secret_key = secret_key.decode('utf8')

         # We will use TLS only if we were given crypto material on input
         use_tls = is_arg_given(args, 'priv_key_path')
diff --git a/zato-cli/src/zato/cli/create_server.py b/code/zato-cli/src/zato/cli/create_server.py
index f39c12fc4..7ce9f591e 100644
--- a/zato-cli/src/zato/cli/create_server.py
+++ b/zato-cli/src/zato/cli/create_server.py
@@ -625,7 +625,10 @@ class Create(ZatoCommand):

         server = Server(cluster=cluster)
         server.name = args.server_name
-        server.token = self.token.decode('utf8')
+        if isinstance(self.token, (bytes, bytearray)):
+            server.token = self.token.decode('utf8')
+        else:
+            server.token = self.token
         server.last_join_status = SERVER_JOIN_STATUS.ACCEPTED
         server.last_join_mod_by = self._get_user_host()
         server.last_join_mod_date = datetime.utcnow()
@@ -720,12 +723,13 @@ class Create(ZatoCommand):
             zato_well_known_data = fernet1.encrypt(well_known_data.encode('utf8'))
             zato_well_known_data = zato_well_known_data.decode('utf8')

-            key1 = key1.decode('utf8')
+            if isinstance(key1, (bytes, bytearray)):
+                key1 = key1.decode('utf8')

             zato_main_token = fernet1.encrypt(self.token)
             zato_main_token = zato_main_token.decode('utf8')

-            zato_misc_jwt_secret = fernet1.encrypt(getattr(args, 'jwt_secret', Fernet.generate_key()))
+            zato_misc_jwt_secret = fernet1.encrypt(getattr(args, 'jwt_secret', Fernet.generate_key()).encode('utf-8'))
             zato_misc_jwt_secret = zato_misc_jwt_secret.decode('utf8')

             secrets_conf.write(secrets_conf_template.format(
diff --git a/zato-client/src/zato/client/__init__.py b/code/zato-client/src/zato/client/__init__.py
index c31679fb6..28c42b2ed 100644
--- a/zato-client/src/zato/client/__init__.py
+++ b/zato-client/src/zato/client/__init__.py
@@ -397,9 +397,12 @@ class _Client(object):
             raw_response, self.to_bunch, self.max_response_repr,
             self.max_cid_repr, self.logger, output_repeated)

+        if isinstance(request, (bytes, bytearray)):
+            request = request.decode('utf-8')
+
         if self.logger.isEnabledFor(logging.DEBUG):
             msg = 'request:[%s]\nresponse_class:[%s]\nasync:[%s]\nheaders:[%s]\n text:[%s]\ndata:[%s]'
-            self.logger.debug(msg, request.decode('utf-8'), response_class, async, headers, raw_response.text, response.data)
+            self.logger.debug(msg, request, response_class, async, headers, raw_response.text, response.data)

         return response

EOF
