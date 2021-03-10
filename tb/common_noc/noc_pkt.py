#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : noc_pkt.py
# License           : MIT license <Check LICENSE>
# Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
# Date              : 09.03.2021
# Last Modified Date: 09.03.2021
# Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
import cocotb
import logging
from common_noc.constants import noc_const
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge, Timer
from cocotb.log import SimColourLogFormatter, SimLog, SimTimeContextFilter
from datetime import datetime

class NoC_pkt:
    def __init__(self, flavor="vanilla", message="A"):
        # m_array = bytearray(message,'utf-8')
        # size_bits = len(bin(m_array[0]))-1
        # Compute max size of single flit message
        # size-noc_const.
        # if message > size
