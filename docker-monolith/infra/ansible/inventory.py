#!/usr/bin/python

import json
import subprocess
import os


class InventoryGenerator:

    terraform_output_map = {
        'app_external_ip': 'app',
    }

    terraform_dir_path = '/../terraform/'

    def __init__(self):
        self._hosts = {}
        current_path = os.path.dirname(os.path.realpath(__file__))
        os.chdir(current_path + self.terraform_dir_path)
        terraform_result = subprocess.check_output(['terraform', 'output', '-json'])
        for key, item in json.loads(terraform_result).iteritems():
            for value_key, value in enumerate(item['value']):
                self._hosts[str(value_key)] = value

    def get_host_name(self, terraform_name):
        if not terraform_name in self.terraform_output_map:
            return terraform_name + '_host'
        return self.terraform_output_map[terraform_name]

    def print_json(self):
        hostvars = {}
        all = []
        inventory = {
            '_meta': {
                'hostvars': hostvars
            },
            'all': {
                'children': all
            }
        }

        for name, ip_address in self._hosts.iteritems():
            hostvars[name] = {'ansible_host': ip_address}
            host_name = self.get_host_name(name)
            all.append(host_name)
            inventory[host_name] = {'hosts': [name]}

        print(json.dumps(inventory))


generator = InventoryGenerator()
generator.print_json()
