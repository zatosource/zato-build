# -*- coding: utf-8 -*-

import os
import json
import logging
import re


logging.basicConfig(level=logging.INFO)

current_dir = os.getcwd()
main_vm_dir = os.path.join(current_dir, 'vm')
virtual_machines = sorted(os.listdir(main_vm_dir))
test_passed = []


def check_result(result):

    if result == 'ZATO_OK':
        test_passed.append(True)
    elif result is True:
        test_passed.append(True)
    else:
        test_passed.append(False)


def check_content(file):

    output_file = open(file)
    pattern_info = re.compile(r'info_*')
    pattern_ping = re.compile(r'ping_*')

    content = json.load(output_file)

    if re.search(pattern_info, file):
        details = {
            'name': content['component_details']['component'],
            'running': content['component_running'],
            'version': content['component_details']['version'],
        }
        logging.info(' Component:')

        for key, value in details.iteritems():
            logging.info(' - %s: %s' % (key, value))
            check_result(value)
        print '\n'

    elif re.search(pattern_ping, file):
        details = {
            'result': content['zato_env']['result']
        }
        result = details['result']
        logging.info(' %s: %s\n' % ('ping', result))
        check_result(result)


for directory in virtual_machines:
    logging.info(' ' + 45 * '=')
    logging.info(' Checking test results for %s', directory)
    test_directory = os.path.join(main_vm_dir, directory, 'tests')
    for root, dirs, files in os.walk(test_directory):
        for filename in files:
            logging.info(' Checking %s now', filename)
            filename = os.path.join(test_directory, filename)
            try:
                check_content(filename)
            except ValueError:
                logging.info(' Content of this file is not json. Skipping.\n')

if test_passed.count(False) == 0:
    logging.info('All tests passed')
else:
    logging.info('%s' %
        ' Some tests have failed. Refer to test output files to check what has gone wrong.')
