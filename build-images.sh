#!/bin/bash

#
# Copyright (C) 2023 Nethesis S.r.l.
# SPDX-License-Identifier: GPL-3.0-or-later
#

# Terminate on error
set -e
# Prepare variables for later use
images=()
# The image will be pushed to GitHub container registry
repobase="${REPOBASE:-ghcr.io/mrmarkuz}"

#Create fetchmail-webapp container
reponame="fetchmail-binary"
container=$(buildah from docker.io/library/alpine:3.20.2)
buildah run "${container}" /bin/sh <<'EOF'
set -e
apk add --no-cache cronie fetchmail fetchmailconf fetchmail-openrc fetchmail-doc nano
EOF
# Exclude add directory to container to make it work - we may need the directory including a bash script later
#buildah add "${container}" fetchmail/ /
# Commit the image
buildah commit --rm "${container}" "${repobase}/${reponame}"

# Append the image URL to the images array
images+=("${repobase}/${reponame}")

# Configure the image name
reponame="fetchmail"

# Create a new empty container image
container=$(buildah from scratch)

# Reuse existing nodebuilder-fetchmail container, to speed up builds
if ! buildah containers --format "{{.ContainerName}}" | grep -q nodebuilder-fetchmail; then
    echo "Pulling NodeJS runtime..."
    buildah from --name nodebuilder-fetchmail -v "${PWD}:/usr/src:Z" docker.io/library/node:lts
fi

echo "Build static UI files with node..."
buildah run \
    --workingdir=/usr/src/ui \
    --env="NODE_OPTIONS=--openssl-legacy-provider" \
    nodebuilder-fetchmail \
    sh -c "yarn install && yarn build"

# Add imageroot directory to the container image
buildah add "${container}" imageroot /imageroot
buildah add "${container}" ui/dist /ui
# Setup the entrypoint, ask to reserve one TCP port with the label and set a rootless container
buildah config --entrypoint=/ \
    --label="org.nethserver.authorizations=mail@any:mailadm" \
    --label="org.nethserver.rootfull=0" \
    --label="org.nethserver.images=${repobase}/fetchmail-binary:${IMAGETAG:-latest}" \
    "${container}"
# Commit the image
buildah commit "${container}" "${repobase}/${reponame}"

# Append the image URL to the images array
images+=("${repobase}/${reponame}")

#
# NOTICE:
#
# It is possible to build and publish multiple images.
#
# 1. create another buildah container
# 2. add things to it and commit it
# 3. append the image url to the images array
#

#
# Setup CI when pushing to Github. 
# Warning! docker::// protocol expects lowercase letters (,,)
if [[ -n "${CI}" ]]; then
    # Set output value for Github Actions
    printf "images=%s\n" "${images[*],,}" >> "${GITHUB_OUTPUT}"
else
    # Just print info for manual push
    printf "Publish the images with:\n\n"
    for image in "${images[@],,}"; do printf "  buildah push %s docker://%s:%s\n" "${image}" "${image}" "${IMAGETAG:-latest}" ; done
    printf "\n"
fi