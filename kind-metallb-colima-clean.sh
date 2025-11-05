#!/opt/homebrew/bin/bash

#Prerequisite bash4+

set +e
set -x

colima stop; colima delete; rm -rf ~/.colima

