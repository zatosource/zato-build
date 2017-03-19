#!/bin/py
# check_vms.py - Lists all VirtualBox's Virtual Machines and checks their status

import argparse
import re
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument("list")
parser.add_argument("state", default="all")
args = parser.parse_args()

box_list = subprocess.check_output(["vboxmanage", "list", "vms"]).split("\n")
# Remove exit code from box_list
del box_list[-1]

def check_box_info(box):
    box_info = subprocess.check_output(["vboxmanage", "showvminfo", box,])
    return box_info

def get_box_state(box_info):
    for item in box_info:
        m = re.match("State:\s+", item)
        if m:
            m = m.group(0)
            box_state = item.replace(m, '')
    return box_state

def format_info(box_name, box_id, box_state):
    delimiter = 70 * "-"
    info = """%s\n
    box name: %s\n
    box id: %s\n
    box state: %s\n""" % (delimiter, box_name, box_id, box_state)
    return info

def analyze_vms():
    vms = {}
    running_vms = []
    aborted_vms = []
    idx = 1

    for box in box_list:
        box = box.split()
        box_name = box[0].strip('"')
        box_id = box[-1].strip("{}")
        box_info = check_box_info(box_id).split('\n')
        box_state = get_box_state(box_info)

        if len(box) > 2:
            box_name = " ".join(box[0:-1])
        if "running" in box_state:
            running_vms.append([box_name, box_id])
        elif "aborted" in box_state:
            aborted_vms.append([box_name, box_id])

        info = format_info(box_name, box_id, box_state)
        print(info)

        vms[idx] = {'name': box_name, 'id': box_id, 'state': box_state}
        idx += 1

    return (vms, running_vms, aborted_vms)

def main():

    if args.state == "all":
        header = (70 * "=") + "\n\n" + (4 * " ") + "List of VirtualBox VMs:\n"
        print(header)

        analyzed = analyze_vms()
        all_vms = len(analyzed[0])
        running_vms = len(analyzed[1])
        aborted_vms = len(analyzed[2])

        footer = (70 * "=") + '\n'
        print(footer)

        print("Total number of VMs: %s" % (all_vms))
        print("Number of running VMs: %s" % running_vms)
        print("Number of aborted VMs: %s" % aborted_vms)
        print("")

    elif args.state == "running":
        header = (70 * "=") + "\n\n" + (4 * " ") + "List of running VirtualBox VMs:\n"
        print(header)

    elif args.state == "aborted":
        header = (70 * "=") + "\n\n" + (4 * " ") + "List of aborted VirtualBox VMs:\n"
        print(header)

def running():
    pass

main()
