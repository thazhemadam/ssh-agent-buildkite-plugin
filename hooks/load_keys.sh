#!/bin/bash

set -eou pipefail

# Start up ssh-agent
eval "$(ssh-agent -s 2>/dev/null)"

# Load keyfiles off of disk
IDX=0
while [[ -v "BUILDKITE_PLUGIN_SSH_AGENT_KEYFILES_${IDX}" ]]; do
    VARNAME="BUILDKITE_PLUGIN_SSH_AGENT_KEYFILES_${IDX}"
    if [[ -f "${!VARNAME}" ]]; then
        cat "${!VARNAME}" | ssh-add -
    else
        echo "Skipping ${!VARNAME} as it doesn't exist (yet)"
    fi

    IDX=$((${IDX} + 1))
done

# Decode environment variables, and pipe them in through `stdin`
IDX=0
while [[ -v "BUILDKITE_PLUGIN_SSH_AGENT_KEYVARS_${IDX}" ]]; do
    # First, build buildkite plugin variable name
    VARNAME="BUILDKITE_PLUGIN_SSH_AGENT_KEYVARS_${IDX}"
    # Use that to get the actual keyfile variable name
    VARNAME="${!VARNAME}"
    # Then we dereference _again_ to get the actual keyfile contents
    base64 -d <<< "${!VARNAME}" | ssh-add -

    IDX=$((${IDX} + 1))
done

# List all loaded SSH keys
ssh-add -l
