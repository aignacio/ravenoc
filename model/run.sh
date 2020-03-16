#!/bin/bash
# File              : run.sh
# Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
# Date              : 16.03.2020
# Last Modified Date: 16.03.2020
# Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
mkdir -p build
cd build
cmake -GNinja ..
cmake --build .
chmod +x raveNoC
./raveNoC
