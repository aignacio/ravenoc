#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : test_ravenoc.py
# Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
# Date              : 20.01.2021
# Last Modified Date: 30.01.2021
# Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
import cocotb
from cocotb.clock import Clock
from cocotbext.axi import AxiMaster
from cocotb.triggers import ClockCycles, Combine, Join, RisingEdge, Timer

CLK_NOC = (10, "ns")
CLK_AXI = (4, "ns")
RST_CYCLES = 2

async def setup_dut(dut):
    cocotb.fork(Clock(dut.clk, *CLK_NOC).start())
    dut.arst <= 1
    await ClockCycles(dut.clk, RST_CYCLES)
    dut.arst <= 0
    await ClockCycles(dut.clk, RST_CYCLES)


@cocotb.test()
async def basic_test(dut):
    """ Test message """
    await setup_dut(dut)

    for i in range(100):
        await RisingEdge(dut.clk)
