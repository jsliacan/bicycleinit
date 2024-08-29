#!/bin/bash

echo "" >> bicycleinit.log
date >> bicycleinit.log
echo "${BASH_SOURCE[0]}" | tee -a bicycleinit.log

# TODO: launch all the sensors
