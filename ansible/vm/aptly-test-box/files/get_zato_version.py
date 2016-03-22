#!/usr/bin/python
# -*- coding: utf-8 -*-

import re

f = open('zato_package_list.txt', 'r')
contents = f.read()
f.close()

p = re.compile('\d+\.\d+\.\d+-\w+-\w+')
all_versions = p.findall(contents)
versions = list(set(all_versions))
versions.sort()

print(versions)
