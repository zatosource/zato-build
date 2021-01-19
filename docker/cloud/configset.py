#!/opt/zato/current/bin/python
# -*- coding: utf-8 -*-

"""
Copyright (C) 2019, Zato Source s.r.o. https://zato.io
Licensed under LGPLv3, see LICENSE.txt for terms and conditions.

configset.py is used to dockerize Zato components. This script allows you to configure Zato's server.conf and sso.conf by environment variables.

Examples:
server__component_enabled__sso=True configures server.conf [component_enabled] sso with value 'True'
sso__signup__is_approval_needed=False configures sso.conf [signup] is_approval_needed with value 'False'

"""

import os
import configobj

server_config_changed = False
server_config_path = '/opt/zato/env/qs-1/config/repo/server.conf'
server_config = configobj.ConfigObj(server_config_path, use_zato=False)

sso_config_changed = False
sso_config_path = '/opt/zato/env/qs-1/config/repo/sso.conf'
sso_config = configobj.ConfigObj(sso_config_path, use_zato=False)

def patch(key, value):
    parts = key.split('__')
    filename = parts.pop(0) + '.conf'
    key = parts.pop(-1)
    nestedSections = parts
    print(filename, nestedSections, key, value)
    _patch(filename, nestedSections, key, value)

def _patch(filename, nestedSections, key, value):
    global server_config_changed
    global sso_config_changed
    if filename == 'server.conf':
        config = None
        for n in nestedSections:
            if config:
                config = config.get(n, {})
            else:
                config = server_config.get(n, {})
        config[key] = value
        server_config_changed = True
    if filename == 'sso.conf':
        config = None
        for n in nestedSections:
            if config:
                config = config[n]
            else:
                config = sso_config.get(n, {})
        config[key] = value
        sso_config_changed = True

# Patch config file based on environment format:
# server__section_key=value -> server.conf [section] key = value
# sso__section_key=value -> sso.conf [section] key = value
for i in os.environ:
    if 'server__' in str(i):
        patch(i, os.environ.get(i) )
    if 'sso__' in str(i):
        patch(i, os.environ.get(i) )

# Patch lagacy environment variables
ZATO_SSO = os.environ.get('ZATO_SSO')
if ZATO_SSO == 'y':
    patch('server__component_enabled__sso', 'True')
ZATO_SSO_IS_APPROVAL_NEEDED = os.environ.get('ZATO_SSO_IS_APPROVAL_NEEDED')
if ZATO_SSO_IS_APPROVAL_NEEDED == 'n':
    patch('sso__signup__is_approval_needed', 'False')

# Overwrite configuration files
if server_config_changed:
    server_config.write()

if sso_config_changed:
    sso_config.write()

