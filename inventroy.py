#!/usr/bin/env python3
import json
import subprocess
import re

PROJECT_ID = "fifth-medley-478216-a7"
SSH_KEY_PATH = "/var/lib/jenkins/workspace/test_dev2/Terraform/id_rsa"


def get_instances():
    cmd = [
        "gcloud", "compute", "instances", "list",
        "--format=json",
        f"--project={PROJECT_ID}"
    ]
    output = subprocess.check_output(cmd)
    return json.loads(output)


def main():
    # Initialize inventory structure
    inventory = {
        "manager": {"hosts": []},
        "workers": {"hosts": []},
        "all": {"children": ["manager", "workers"]},
        "_meta": {"hostvars": {}}
    }

    instances = get_instances()

    for vm in instances:
        vm_name = vm["name"]
        name = vm_name.lower()
        ip = vm["networkInterfaces"][0]["networkIP"]

        # Identify manager
        if name == "swarm-manager":
            group = "manager"

        # Identify workers
        elif name.startswith("swarm-worker"):
            group = "workers"

        else:
            continue  # ignore unrelated VMs

        # Assign host
        inventory[group]["hosts"].append(vm_name)

        # Host variables
        inventory["_meta"]["hostvars"][vm_name] = {
            "ansible_host": ip,
            "ansible_user": "venki",
            "ansible_ssh_private_key_file": SSH_KEY_PATH,
            "ansible_ssh_common_args": "-o StrictHostKeyChecking=no"
        }

    print(json.dumps(inventory, indent=2))


if __name__ == "__main__":
    main()
