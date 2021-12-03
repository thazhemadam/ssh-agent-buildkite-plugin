#!/bin/bash

set -eou pipefail

# Start up ssh-agent if we don't already have a valid SSH_AUTH_SOCK
if [ ! -S "${SSH_AUTH_SOCK:-}" ]; then
    echo "No pre-existing ssh-agent found, starting one up..."
    eval "$(ssh-agent -s 2>/dev/null)"
fi

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
    
    # Then we dereference _again_ to get the actual keyfile contents.
    # We first try feeding it directly into `ssh-add`, and if that doesn't
    # work, we base64-decode it, as that's a common encoding we use.
    if ! ssh-add <<< "${!VARNAME}"; then
        if ! base64 -d <<< "${!VARNAME}" | ssh-add; then
            echo "Unable to add SSH key stored in ${VARNAME}!" >&2
            
            if [[ "${BUILDKITE_PLUGIN_SSH_AGENT_DEBUG:-false}" == "true" ]]; then
                echo "--- ${VARNAME} key dump"
                cat <<< "${!VARNAME}"
            fi
        fi
    fi

    IDX=$((${IDX} + 1))
done

# List all loaded SSH keys
ssh-add -l || true
