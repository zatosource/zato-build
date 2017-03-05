#!/bin/py
# check_vms.py - Lists all VirtualBox's Virtual Machines and checks their status

import re
import subprocess

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

header = (70 * "=") + "\n\n" + (4 * " ") + "List of VirtualBox VMs:\n"

print(header)
vms = {}
running_vms = []
aborted_vms = []
idx = 1
for box in box_list:
    box = box.split()
    box_name = box[0][1:-1]
    if len(box) > 2:
        box_name = " ".join(box[0:-1])
    box_id = box[-1].strip("{}")
    box_info = check_box_info(box_id).split('\n')
    box_state = get_box_state(box_info)
    if box_state == "running":
        running_vms.append([box_name, box_id])
    elif box_state == "aborted":
        aborted_vms.append([box_name, box_id])
    info = format_info(box_name, box_id, box_state)
    print(info)

    vms[idx] = {'name': box_name, 'id': box_id, 'state': box_state}
    idx += 1

footer = (70 * "=") + '\n'
print(footer)
print("Total number of VMs: %s" % (idx))
print("Number of running VMs: %s" % len(running_vms))
print("Number of aborted VMs: %s" % len(aborted_vms))
print("")
