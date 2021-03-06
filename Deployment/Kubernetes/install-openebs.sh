# ITNOA

#!/bin/bash

# Installing OpenEBS as a storage infrastructure on K8s from https://openebs.io/docs/user-guides/installation#installation-through-helm
#
# Installing prerequisites from https://docs.openebs.io/v280/docs/next/ugmayastor.html
# please see configure-hugepages.sh

is_internet_exist=0
# Check internet connection exist or not?
if ping 4.2.2.4 -c 2 -W 2 &> /dev/null ; then
    is_internet_exist=1
    echo "Internet is connected :)"
fi

readonly total_memory=$(free -m | awk '/^Mem:/{print $2}')

if [[ total_memory -lt 3900 ]] ; then
    echo "Insufficient memory for installing openebs mayastor engine, you have to provide 4GB memory at least"
    exit 1
fi

# Check kubectl cli exist or not?
# https://stackoverflow.com/a/677212/1539100
if ! command -v kubectl &> /dev/null ; then
    echo "kubectl does not found, please install kubectl, and ensure K8s running on this node"
    exit 1
fi

# Check helm cli exist or not?
# https://stackoverflow.com/a/677212/1539100
if command -v helm &> /dev/null && [[ is_internet_exist ]] ; then
    echo "Helm found, so we using helm..."

    if [[ $(helm ls -n openebs | wc -l) -gt 1 ]] ; then
        echo "OpenEBS is installed, so we do not need reinstall"
        exit 0
    fi

    # Check helm needed repo exist or not?
    if ! helm repo list | grep openebs &> /dev/null ; then
        # Before I can install the chart I will need to add the harbor repo to Helm
        helm repo add openebs http://openebs.github.io/charts
    fi

    # Follow https://medium.com/volterra-io/kubernetes-storage-performance-comparison-v2-2020-updated-1c0b69f0dcf4 instructions
    #‌ to prepare environment for installing OpenEBS run configure-hugepages.sh in each node

    # TODO: Optional for installing mayastor as OpenEBS engine
    for node_name in $(kubectl get nodes --no-headers | tr -s ' ' | grep none | cut -d ' ' -f 1) ; do
        kubectl label node $node_name openebs.io/engine=mayastor
    done

    # For checking that node has correct label or not? you can use kubectl label --list nodes node_name

    # For checking helm chart documentation please see https://github.com/openebs/charts/tree/master/charts/openebs
    # default installation of openebs, install LocalPV
    helm install openebs --namespace openebs openebs/openebs --create-namespace
else
    echo "Helm must be install from 'install-helm.sh'"
fi