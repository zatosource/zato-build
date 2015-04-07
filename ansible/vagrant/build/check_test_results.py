# -*- coding: utf-8 -*-

import os
import json
import logging
import re


logging.basicConfig(level=logging.INFO)

current_dir = os.getcwd()
main_vm_dir = os.path.join(current_dir, 'vm')
virtual_machines = sorted(os.listdir(main_vm_dir))
passed_tests = []
failed_tests = []


def check_result(result):

    positive_results = ['ZATO_OK', 'OK', True]
    if result in positive_results:
        passed_tests.append(True)


def check_content(file):

    output_file = open(file)
    pattern_tests = re.compile(r'run-tests.txt')
    pattern_alive = re.compile(r'check-lb-alive.html')
    pattern_info = re.compile(r'info-*')
    pattern_ping = re.compile(r'ping-*')

    if re.search(pattern_info, file):
        content = json.load(output_file)
        details = {
            'name': content['component_details']['component'],
            'running': content['component_running'],
            'version': content['component_details']['version'],
        }
        logging.info(' Component:')

        for key, value in sorted(details.iteritems()):
            logging.info(' - %s: %s' % (key, value))

        check_result(details['running'])

    elif re.search(pattern_ping, file):
        try:
            content = json.load(output_file)
            details = {
                'result': content['zato_env']['result']
            }
            result = details['result']
            logging.info(' %s: %s' % ('ping', result))
            check_result(result)
        except ValueError:
            f = open(file, 'r')
            content = f.readlines()
            for line in content:
                if '504' in line:
                    result = 'FAIL'
                    failed_tests.append(file)
                    logging.info(' %s: %s' % ('Result', result))
                    check_result(result)

    elif re.search(pattern_tests, file) or re.search(pattern_alive, file):
        f = open(file, 'r')
        content = f.readlines()
        for line in content:
            if 'OK' in line:
                result = 'OK'
                logging.info(' %s: %s' % ('Result', result))
                check_result(result)
            elif 'FAIL' in line:
                result = 'FAIL'
                failed_tests.append(file)
                logging.info(' %s: %s' % ('Result', result))
                check_result(result)


def final_result():

    count_passed_tests = len(passed_tests)
    if len(failed_tests) == 0:
        logging.info(' SUCCESS! All %d tests have passed' % count_passed_tests)
        return True
    else:
        failed_test_count = len(failed_tests)
        logging.info(' FAILURE! %d tests have failed. Check the test output files:' % failed_test_count)
        return False

for directory in virtual_machines:
    logging.info(' ' + 45 * '=')
    logging.info(' Checking test results for %s', directory)
    test_directory = os.path.join(main_vm_dir, directory, 'tests')
    for root, dirs, files in os.walk(test_directory):
        for file in sorted(files):
            logging.info(' Checking %s', file)
            file = os.path.join(test_directory, file)
            try:
                check_content(file)
                logging.info('')
            except ValueError:
                logging.info(' Content of this file is not json. Skipping.')

final_result()
print failed_tests
