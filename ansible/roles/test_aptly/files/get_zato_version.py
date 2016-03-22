#!/usr/bin/python
# -*- coding: utf-8 -*-

import re
import os
import sys

os.system("apt-cache showpkg zato >> 'showpkg.txt'")

f = open('showpkg.txt', 'r')
contents = f.read()
f.close()

# The following code will find all strings matching the pattern,
# e.g. '2.0.5-stable-trusty', and put the into tuple of lists:
# [('2.0.4', 'stable', 'trusty'), ('2.0.5', 'stable', 'trusty')].
# All elements are then accessed by their offsets passed
# via command line to 'set_variables' function.
p = re.compile('(\d+\.\d+\.\d+)-(\w+)-(\w+)')
versions = p.findall(contents)
versions = list(set(versions))
versions.sort()

def set_variables(file, offset):

    # 'file' is a path to an output file
    # where variables are be saved
    # 'offset' is a position of each parameter
    # in 'versions' tuple of lists

    release_version = versions[offset][0]
    package_version = versions[offset][1]
    codename = versions[offset][2]

    f = open(file, 'w')
    f.write(
        '---\n\n'
        'release_version: ' + release_version + '\n'
        'package_version: ' + package_version + '\n'
        'codename: ' + codename
    )
    f.close()

if __name__ == "__main__":
    set_variables(sys.argv[1], int(sys.argv[2]))
