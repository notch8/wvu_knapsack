#!/bin/bash
# remove docker volumes
docker volume prune --all --force
# remove all docker images created from the current directory
docker images --filter=reference='*/*' --format '{{.ID}}' | xargs docker rmi --force 2>/dev/null
# remove all dangling images
docker images --filter "dangling=true" -q | xargs docker rmi --force 2>/dev/null
