#!/bin/py
# check_vms.py - Lists all VirtualBox's Virtual Machines and checks their status
#
# TODO: add help comments to argparse arguments
# TODO: add argument validation
# TODO: separate vms listing and vms stats

import argparse
import re
import subprocess
import sys

parser = argparse.ArgumentParser()
parser.add_argument("list")
parser.add_argument("state", nargs="?", default="all")
args = parser.parse_args()

try:
    vm_list = subprocess.check_output(["vboxmanage", "list", "vms"]).split("\n")
    # Remove exit code from vm_list
    del vm_list[-1]
except OSError:
    print("ERROR!")
    print("There is no VBoxManage CLI available on this machine.")
    print("There is nothing for this program to do.")
    print("Exiting.")
    sys.exit(0)

def check_vm_info(box):
    vm_info = subprocess.check_output(["vboxmanage", "showvminfo", box,])
    return vm_info

def get_vm_state(vm_info):
    for item in vm_info:
        m = re.match("State:\s+", item)
        if m:
            m = m.group(0)
            vm_state = item.replace(m, '')
    return vm_state

def get_info(*args):
    vms = args[0]
    running_vms = args[1]
    aborted_vms = args[2]
    state = args[3]

    vms_qty = len(vms)
    running_qty = len(running_vms)
    aborted_qty = len(aborted_vms)

    header = (70 * "=") + "\n\n" + (4 * " ") + \
        ("List of %s VirtualBox VMs:\n" % (state))
    delimiter = 70 * "-"
    footer = (70 * "=")

    if state == "all":
        current_vms = vms
    elif state == "running":
        current_vms = running_vms
    elif state == "aborted":
        current_vms = aborted_vms
    else:
        print("Invalid [state] argument.")
        print("Pass 'all', 'running' or 'aborted' as argument.")
        sys.exit(0)

    print(header)

    if len(current_vms) == 0:
        print("    There are no %s VMs on this machine.\n" % (state))
    elif len(current_vms) == 0 and state == "all":
        print("    There are no VMs created on this machine.\n")

    for vm in current_vms:
        name = current_vms[vm]['name']
        id = current_vms[vm]['id']
        state = current_vms[vm]['state']
        info = """%s\n
    box name: %s\n
    box id: %s\n
    box state: %s\n""" % (delimiter, name, id, state)
        print(info)

    print(70 * "-" + "\n")
    print(4 * " " + "Total number of VMs: %s" % (vms_qty))
    print(4 * " " + "Number of running VMs: %s" % running_qty)
    print(4 * " " + "Number of aborted VMs: %s" % aborted_qty)
    print("")
    print(footer)

def main():
    vms = {}
    running_vms = {}
    aborted_vms = {}
    idx = 1

    for vm in vm_list:
        vm = vm.split()
        vm_name = vm[0].strip('"')
        vm_id = vm[-1].strip("{}")
        vm_info = check_vm_info(vm_id).split('\n')
        vm_state = get_vm_state(vm_info)

        if len(vm) > 2:
            vm_name = " ".join(vm[0:-1])

        if "running" in vm_state:
            running_vms[idx] = {'name': vm_name, 'id': vm_id, 'state': vm_state}
        elif "aborted" in vm_state:
            aborted_vms[idx] = {'name': vm_name, 'id': vm_id, 'state': vm_state}

        vms[idx] = {'name': vm_name, 'id': vm_id, 'state': vm_state}
        idx += 1

    get_info(vms, running_vms, aborted_vms, args.state)

main()
