# -*- coding: utf-8 -*-

import os
import logging


logging.basicConfig(level=logging.INFO)

current_dir = os.getcwd()
vm_dir = os.path.join(current_dir, 'vm')
virtual_machines = os.listdir(vm_dir)


def check_content(file):

    output_file = enumerate(open(file))
    zato_components = ['LOAD_BALANCER', 'SERVER', 'WEB_ADMIN']

    for key, value in output_file:
        value = value.split('|')
        new_value = []
        for item in value:
            item = item.strip()
            new_value.append(item)
        for item in new_value:
            if 'version' in item:
                version_start = item.find('Zato')
                zato_version = item[version_start:-2]
                logging.info("Component version is %s", (zato_version))
            elif 'component_running' in item:
                component_running = new_value[2]
                if component_running == 'False':
                    logging.info("Component is running")
                else:
                    logging.warning("Component is not running")

for directory in virtual_machines:
    logging.info(40 * "=")
    logging.info("Checking test results for %s", directory)
    test_directory = os.path.join(vm_dir, directory, 'tests')
    for root, dirs, files in os.walk(test_directory):
        for item in files:
            logging.info("Checking %s now", item)
            item = os.path.join(test_directory, item)
            check_content(item)
