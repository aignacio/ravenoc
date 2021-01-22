#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : test_ravenoc.py
# Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
# Date              : 20.01.2021
# Last Modified Date: 20.01.2021
# Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
import cocotb
from cocotb.triggers import Timer

@cocotb.test()
async def my_first_test(dut):
    """Try accessing the design."""

    dut._log.info("Running test!")
    for cycle in range(10):
        dut.clk = 0
        await Timer(1, units='ns')
        dut.clk = 1
        await Timer(1, units='ns')
    dut._log.info("Running test!")
