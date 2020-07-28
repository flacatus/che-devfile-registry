#!/bin/bash
# Copyright (c) 2012-2020 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# Contributors:
#   Red Hat, Inc. - initial API and implementation

set -e

# PR_FILES_CHANGED store all Modified/Created files in Pull Request.
export PR_FILES_CHANGED="devfiles/nodejs-mongo/devfile.yaml devfiles/che4z/devfile.yaml pkg/che_types.go"

# filterDevFileYamls function transform PR_FILES_CHANGED into a new array => FILES_CHANGED_ARRAY.
function filterDevFileYamls() {
    export SCRIPT=$(readlink -f "$0")
    export ROOT_DIR=$(dirname $(dirname "$SCRIPT"));

    for files in ${PR_FILES_CHANGED}
    do
        if [[ $files =~ ^devfiles.*.yaml$ ]]; then
            echo "[INFO] Added/Changed new devfile in the current PR: ${files}"
            export FILES_CHANGED_ARRAY+=("${ROOT_DIR}/"$files)
        fi
    done 
}

function checkDevFileImages() {
    export IMAGES=$(yq -r '..|.image?' "${FILES_CHANGED_ARRAY[@]}" | grep -v "null" | uniq)

    for image in ${IMAGES}
    do
        local DIGEST="$(skopeo inspect --tls-verify=false docker://${image} 2>/dev/null | jq -r '.Digest')"
        pene_largo=yq -r '.components[] | .referenceContent?' "${devfile}" | yq -r '.items?|..|.image?' | grep -v "null" | sort | uniq
        echo ${pene_largo}
        if [ -z "${DIGEST}" ];
        then
            echo "[ERROR] Image ${image} don't contain an valid digest.Digest check script will fail."
            exit 1
        fi
        echo "[INFO] Successfully checked image digest: ${image}"
    done
}

filterDevFileYamls
checkDevFileImages
