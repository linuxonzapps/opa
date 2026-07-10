#!/bin/bash
set -e -o pipefail
read -ra arr <<< "$@"
version=${arr[1]}
trap 0 1 2 ERR
# Extract DISTRO details for tagging
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO="$ID-$VERSION_ID"
    if [ "$VERSION_CODENAME" != "" ]; then
        DISTRO="$ID-$VERSION_CODENAME"
    fi
fi
current_dir="$PWD"
echo $DISTRO > .distro_zab.txt
# Ensure sudo is installed
apt-get update && apt-get install sudo -y
bash /tmp/linux-on-ibm-z-scripts/OPA/${version}/build_opa.sh -y
tar cvfz opa-${version}-linux-s390x.tar.gz -C $PWD/opa opa_linux_s390x
# Create container image
export PATH=$PATH:/usr/local/go/bin
# Ensure custom Go path is accounted for
GO_VERSION=`awk -F'[=" ]+' '$1=="GO_VERSION"{print $2; exit}' /tmp/linux-on-ibm-z-scripts/OPA/${version}/build_opa.sh`
export PATH=$PATH:/usr/local/go-${GO_VERSION}/bin
cd opa/ && make image-s390x
docker save -o opa-${version}-linux-s390x.container.tar openpolicyagent/opa
mv opa-${version}-linux-s390x.container.tar ../ && cd ../
exit 0
