#!/bin/sh

set -xe

ol-rl -r server.scm &

ol-rl -r client.scm 8 &
ol-rl -r client.scm 3 &
# ol-rl -r client.scm 13 &
# ol-rl -r client.scm 16 &
# ol-rl -r client.scm 20 &

wait
