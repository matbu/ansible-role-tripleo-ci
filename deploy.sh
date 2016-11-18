#!/bin/bash
: ${OPT_WORKDIR:=$PWD/.ci}
: ${OPT_CLEANUP:=0}
: ${REQUIREMENTS:=requirements.txt}
: ${OPT_SYSTEM_PACKAGES:=0}
: ${RELEASE:=mitaka}

VIRTHOST=$1
# gate-tripleo-ci-centos-7-ovb-nonha-upgrades-nv
JOB_NAME=$2
export NODECOUNT=2
for JOB_TYPE_PART in $(sed 's/-/ /g' <<< "${JOB_NAME:-}") ; do
    case $JOB_TYPE_PART in
        updates)
            if [ $JOB_NAME == 'ovb-updates' ] ; then
                NODECOUNT=3
            fi
            ;;
        ha)
            NODECOUNT=4
            ;;
        nonha)
            if [[ ! "$JOB_NAME" =~ "upgrades" ]] ; then
                NODECOUNT=3
            fi
            ;;
        multinode)
            NODECOUNT=1
            ;;
        undercloud)
            NODECOUNT=0
            ;;
    esac
done

# echo overcloud nodes for oooq
cat <<EOF >> tripleo_config.yaml
overcloud_nodes:
  - name: control_0
    flavor: control
  - name: control_1
    flavor: control
  - name: control_2
    flavor: control
  - name: compute_3
    flavor: compute
EOF

clean_virtualenv() {
    if [ -d $OPT_WORKDIR ]; then
        rm -rf $OPT_WORKDIR
    fi
}

# Setup virtualenv for ansible and install tripleo-quickstart
setup() {

    if [ "$OPT_CLEANUP" = 1 ]; then
        clean_virtualenv
    fi
    virtualenv $( [ "$OPT_SYSTEM_PACKAGES" = 1 ] && printf -- "--system-site-packages\n" ) $OPT_WORKDIR
    . $OPT_WORKDIR/bin/activate

    python setup.py install
    pip install --no-cache-dir -r $REQUIREMENTS
}

echo "setup virtualenv and install deps"
setup

echo "Executing Ansible..."

# Ansible variables:
export ANSIBLE_GATHERING=smart
export ANSIBLE_COMMAND_WARNINGS=False
export ANSIBLE_HOST_KEY_CHECKING=False
export ANSIBLE_FORCE_COLOR=1
export ANSIBLE_INVENTORY=$OPT_WORKDIR/hosts
export SSH_CONFIG=$OPT_WORKDIR/ssh.config.ansible
export ANSIBLE_SSH_ARGS="-F ${SSH_CONFIG}"
export ANSIBLE_TEST_PLUGINS=/usr/lib/python2.7/site-packages/tripleo-quickstart/playbooks/test_plugins:$VIRTUAL_ENV/usr/local/share/tripleo-quickstart/test_plugins
export ANSIBLE_LIBRARY=/usr/lib/python2.7/site-packages/tripleo-quickstart/playbooks/library:$VIRTUAL_ENV/usr/local/share/tripleo-quickstart/library:playbooks/library
export ANSIBLE_ROLES_PATH=/usr/lib/python2.7/site-packages/tripleo-quickstart/playbooks/roles:$VIRTUAL_ENV/usr/local/share/tripleo-quickstart/roles:$VIRTUAL_ENV/usr/local/share/ansible/roles/
export ANSIBLE_CALLBACK_PLUGINS=plugins/callback
export ANSIBLE_CALLBACK_WHITELIST=profile_timeline

if [ ! -f "$OPT_WORKDIR/ssh.config.ansible" ]; then
    cat <<EOF >> $OPT_WORKDIR/ssh.config.ansible
Host $VIRTHOST
    User root
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
EOF
fi

ansible-playbook -vvvv $OPT_WORKDIR/playbooks/deploy.yml \
    -e @$OPT_WORKDIR/config/release/$RELEASE.yml \
    -e @tripleo_config.yaml \
    -e upgrade_review=true \
    --tags "teardown-all,untagged,provision,environment,undercloud-scripts" \
    -e ansible_python_interpreter=/usr/bin/python \
    -e local_working_dir=$OPT_WORKDIR \
    -e virthost=$VIRTHOST \
    -e job_name=$JOB_NAME


#    --tags "provision,environment,undercloud-scripts" \
# \
#    ${EXTRA_VARS[@]}

#    --tags "teardown-all,untagged,provision,environment,undercloud-scripts" \
#    --skip-tags "undercloud-scripts,undercloud-install,undercloud-post-install" \

