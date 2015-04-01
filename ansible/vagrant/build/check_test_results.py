# -*- coding: utf-8 -*-

import os
import json
import logging
import re


logging.basicConfig(level=logging.INFO)

current_dir = os.getcwd()
vm_dir = os.path.join(current_dir, 'vm')
virtual_machines = os.listdir(vm_dir)


def check_content(file):

    output_file = open(file)
    pattern_info = re.compile(r'info_*')
    pattern_ping = re.compile(r'ping_*')

    if re.search(pattern_info, file):
        try:
            content = json.load(output_file)
            details = {
                'name': content['component_details']['component'],
                'running': content['component_running'],
                'version': content['component_details']['version'],
            }

            logging.info("Component:")

            for key, value in details.iteritems():
                logging.info("%s%s: %s" % ('\t', key, value))

            logging.info("\n")

        except (ValueError, KeyError):
            logging.warning("Content of this file is not json.\n")

    elif re.search(pattern_ping, file):
        pass


for directory in virtual_machines:
    logging.info(40 * "=")
    logging.info("Checking test results for %s", directory)
    test_directory = os.path.join(vm_dir, directory, 'tests')
    for root, dirs, files in os.walk(test_directory):
        for item in files:
            logging.info("Checking %s now", item)
            item = os.path.join(test_directory, item)
            check_content(item)
