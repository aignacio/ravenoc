#!/bin/bash
# File              : run.sh
# Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
# Date              : 16.03.2020
# Last Modified Date: 23.04.2020
# Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
mkdir -p model/build
cd model/build
cmake -GNinja ..
cmake --build .
chmod +x raveNoC
#./raveNoC
#/home/aignacio/projects/gdb_systemc_trace/gdb_systemc_trace.py raveNoC
