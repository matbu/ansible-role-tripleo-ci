Ansible Tripleo-CI
==================

This role give you the opportunity to run the tripleo-ci script as close as
possible to the CI run.
It's allow you to reproduce CI failures and being able to debug the CI

Requirements
------------

One boxe with ssh access as root throught ssh-keys.
32gb / 8 cpu

Role Variables
--------------

the main variable is: job_name, which correspond to the name of the tripleo-ci
that aim to run.

Dependencies
------------

It use tripleo-quickstart for setting up your server then it just clone
tripleo-ci repo and call scripts

Example Playbook
----------------

- include: quickstart.yml

- name:  Deploy Tripleo
  hosts: undercloud
  gather_facts: no
  roles:
    - { role: tripleo-ci }

How to execute
--------------

After making sure that you can ssh to your server, run just a:
./deploy.sh <server_ip_or_name> <job_name>

example, for the experimental job: gate-tripleo-ci-centos-7-ovb-nonha-upgrades-nv:
./deploy.sh mbubox ovb-nonha-upgrades

Todo
----

Handle the zuul variable for gate jobs

License
-------

BSD

Author Information
------------------

mat.bultel@gmail.com
