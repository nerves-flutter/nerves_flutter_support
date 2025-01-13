#!/bin/bash

#
# Print information about the state of the Buildroot tree.
#
# Inputs:
#   $1   The Buildroot version
#   $2   The directory containing patches for Buildroot
#
# Outputs:
#   Text describing the Buildroot tree
#

set -e
export LC_ALL=C

BR_VERSION=$1

usage() {
    echo "buildroot-state.sh <BR version>"
}

# Trust the passed in version
echo "Buildroot: $BR_VERSION"
