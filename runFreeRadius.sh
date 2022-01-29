#!/bin/bash

podman run -it --rm --privileged --log-level=debug \
  --name freeradius1 \
  --hostname freeradius1.dk \
  -p 1812:1812/udp \
  -p 1813:1813/udp \
  -p 18120:18120/udp freeradius