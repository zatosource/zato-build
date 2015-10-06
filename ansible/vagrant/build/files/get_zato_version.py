#!/usr/bin/python
# -*- coding: utf-8 -*-

import re
import os

os.system("apt-cache showpkg zato >> 'showpkg.txt'")

f = open('showpkg.txt', 'r')
contents = f.read()
f.close()

#p = re.compile('\d+\.\d+\.\d+-\w+-\w+')
p = re.compile('(\d+\.\d+\.\d+)-(\w+)-(\w+)')
versions = p.findall(contents)
versions = list(set(versions))
versions.sort()

release_version_latest = versions[-1][0]
package_version_latest = versions[-1][1]
codename_latest = versions[-1][2]

release_version_previous = versions[-2][0]
package_version_previous = versions[-2][1]
codename_previous = versions[-2][2]

f = open('/vagrant/latest.yml', 'w')
#f.write(
#    '---\n\n'
#    'release_version: ' + release_version_latest + '\n'
#    'package_version: ' + package_version_latest + '\n'
#    'codename: ' + codename_latest
#)
f.close()

f = open('/vagrant/previous.yml', 'w')
#f.write(
#    '---\n\n'
#    'release_version: ' + release_version_previous + '\n'
#    'package_version: ' + package_version_previous + '\n'
#    'codename: ' + codename_previous
#)
f.close()
