#!/bin/py
# check_vms.py - Lists all VirtualBox's Virtual Machines and checks their status

import argparse
import re
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument("list")
parser.add_argument("state", nargs="?", default="all")
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

def get_info(vms, state):
    header = (70 * "=") + "\n\n" + (4 * " ") + \
        ("List of %s VirtualBox VMs:\n" % (state))
    print(header)
    delimiter = 70 * "-"
    for i in vms:
        name = vms[i]['name']
        id = vms[i]['id']
        state = vms[i]['state']
        info = """%s\n
    box name: %s\n
    box id: %s\n
    box state: %s\n""" % (delimiter, name, id, state)
        print(info)


def main():
    vms = {}
    running_vms = {}
    aborted_vms = {}
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
            running_vms[idx] = {'name': box_name, 'id': box_id, 'state': box_state}
        elif "aborted" in box_state:
            aborted_vms[idx] = {'name': box_name, 'id': box_id, 'state': box_state}

        vms[idx] = {'name': box_name, 'id': box_id, 'state': box_state}
        idx += 1

    if args.state == "all":
        get_info(vms, args.state)

    elif args.state == "running":
        get_info(running_vms, args.state)

    elif args.state == "aborted":
        get_info(aborted_vms, args.state)

    vms_qty = len(vms)
    running_qty = len(running_vms)
    aborted_qty = len(aborted_vms)

    footer = (70 * "=") + '\n'

    print(70 * "-" + "\n")
    print(4 * " " + "Total number of VMs: %s" % (vms_qty))
    print(4 * " " + "Number of running VMs: %s" % running_qty)
    print(4 * " " + "Number of aborted VMs: %s" % aborted_qty)
    print("")
    print(footer)

main()
