#!/bin/bash

if [ -z "$1" ]; then
  echo Argument 1 must be Zato version
  exit 2
fi

ZATO_VERSION=$1
PY_BINARY=${2:-python}
# PACKAGE_VERSION=$3

cd /tmp/packages || exit 1

if [ "$(type -p apt-get)" ]; then
  apt-get update

  if ! [ -x "$(command -v lsb_release)" ]; then
    sudo apt-get install -y lsb-release
  fi

  if ! [ -e "/usr/share/zoneinfo/GMT" ]; then
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends tzdata
  fi

  if ! [ -e "/etc/localtime" ]; then
    ln -s /usr/share/zoneinfo/GMT /etc/localtime
  fi

  for i in $(find "/tmp/packages/" -type f -name \*.deb); do
    dpkg -i $i
  done
  apt-get install -f -y || exit 1
elif [ "$(type -p yum)" ]; then
  RHEL_VERSION=el7
  if [[ ${PY_BINARY} == "python3" ]]; then
    sudo yum install -y centos-release-scl-rh
    sudo yum-config-manager --enable centos-sclo-rh-testing

    # On RHEL, enable RHSCL and RHSCL-beta repositories for you system:
    sudo yum-config-manager --enable rhel-server-rhscl-7-rpms
    sudo yum-config-manager --enable rhel-server-rhscl-beta-7-rpms

    # 2. Install the collection:
    sudo yum install -y rh-python36

    # 3. Start using software collections:
    # scl enable rh-python36 bash
    source /opt/rh/rh-python36/enable
  fi

  for i in $(find /tmp/packages/ -type f -name \*.rpm); do
    yum install -y $i
  done
  # elif [ "$(type -p apk)" ]
  # then
else
  echo "install.sh: Unsupported OS: could not detect apt-get, yum, or apk." >&2
  exit 1
fi
if [[ ${PY_BINARY} == "python3" ]]; then
  PY_VERSION="py3."
else
  PY_VERSION="py2."
fi

head -n 1 /opt/zato/current/bin/zato

su - zato -c 'zato --version 1>/tmp/zato-version 2>&1'

cat /tmp/zato-version

if [[ -n "$(grep 'Zato ' /tmp/zato-version | grep $PY_VERSION)" ]]; then
  [[ -n "$(grep 'Zato ' /tmp/zato-version)" ]] && echo "Zato execution: ok"
  [[ -n "$(grep 'Zato ' /tmp/zato-version | grep $PY_VERSION)" ]] && echo "Python version: ok"
  echo "Zato command output:"
  cat /tmp/zato-version
  echo "Tests passed..Uploading packages"
  echo -e "" > /root/.s3cfg <<EOF
[default]
access_key = ${ZATO_S3_ACCESS_KEY}
access_token =
add_content_encoding = True
add_encoding_exts =
add_headers =
bucket_location = US
cache_file =
cloudfront_host = cloudfront.amazonaws.com
default_mime_type = binary/octet-stream
delay_updates = False
delete_after = False
delete_after_fetch = False
delete_removed = False
dry_run = False
enable_multipart = True
encoding = UTF-8
encrypt = False
follow_symlinks = False
force = False
get_continue = False
gpg_command = /usr/bin/gpg
gpg_decrypt = %(gpg_command)s -d --verbose --no-use-agent --batch --yes --passphrase-fd %(passphrase_fd)s -o %(output_file)s %(input_file)s
gpg_encrypt = %(gpg_command)s -c --verbose --no-use-agent --batch --yes --passphrase-fd %(passphrase_fd)s -o %(output_file)s %(input_file)s
gpg_passphrase =
guess_mime_type = True
host_base = s3.amazonaws.com
host_bucket = %(bucket)s.s3.amazonaws.com
human_readable_sizes = False
ignore_failed_copy = False
invalidate_default_index_on_cf = False
invalidate_default_index_root_on_cf = True
invalidate_on_cf = False
list_md5 = False
log_target_prefix =
max_delete = -1
mime_type =
multipart_chunk_size_mb = 15
preserve_attrs = True
progress_meter = True
proxy_host =
proxy_port = 0
put_continue = False
recursive = False
recv_chunk = 4096
reduced_redundancy = False
secret_key = ${ZATO_S3_SECRET_KEY}
send_chunk = 4096
server_side_encryption = False
simpledb_host = sdb.amazonaws.com
skip_existing = False
socket_timeout = 300
urlencoding_mode = normal
use_https = False
use_mime_magic = True
verbosity = WARNING
website_endpoint = http://%(bucket)s.s3-website-%(location)s.amazonaws.com/
website_error =
website_index = index.html
EOF
  cat /root/.s3cfg
  s3cmd sync \
    /tmp/packages/ \
    "$ZATO_S3_BUCKET_NAME/" && echo "Packages uploaded"
else
  echo "Zato failed to pass tests"
  echo -n "Zato execution:"
  if [[ -n "$(grep 'Zato ' /tmp/zato-version)" ]]; then
      echo "ok"
  else
      echo "error"
  fi
  echo -n "Python version ($PY_VERSION):"
  if [[ -n "$(grep 'Zato ' /tmp/zato-version | grep $PY_VERSION)" ]]; then
      echo "ok"
  else
      echo "error"
  fi
  echo "Zato command output:"
  cat /tmp/zato-version
  exit 1
fi
