#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import re

# First off, prepare a regex
p = re.compile('(\w+)\.(\w+)')

# Now, get all filenames in current directory,
# match them against our regex, convert them
# from markdown to rst and remove all markdown files
# in current directory, as they are no longer needed
for root, dirs, files in os.walk('./'):
    for name in files:
        match_name = p.match(name)
        if match_name.group(2) == "md":
            os.system("pandoc --from=markdown --to=rst --output="
                + match_name.group(1)
                + ".txt "
                + name)
            os.system("rm " + name)
