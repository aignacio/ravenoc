#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# tb/test_ravenoc_basic.py
# Copyright (c) 2021 Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# -*- coding: utf-8 -*-
# File              : test_ravenoc_basic.py
# License           : MIT license <Check LICENSE>
# Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
# Date              : 17.02.2021
# Last Modified Date: 17.02.2021
# Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
import random
import cocotb
import os
import logging
import pytest
import cocotb_test.simulator
import glob

from logging.handlers import RotatingFileHandler
from cocotb.log import SimColourLogFormatter, SimLog, SimTimeContextFilter
from cocotb.regression import TestFactory
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge, Timer

CLK_100MHz  = (10, "ns")
CLK_200MHz  = (5, "ns")
RST_CYCLES  = 2
WAIT_CYCLES = 2

async def setup_clks(dut, clk_mode):
    dut._log.info("Configuring clocks...")
    if clk_mode == "AXI_>_NoC":
        dut._log.info("%s",clk_mode)
        cocotb.fork(Clock(dut.clk_noc, *CLK_100MHz).start())
        cocotb.fork(Clock(dut.clk_axi, *CLK_200MHz).start())
    elif clk_mode == "NoC_>_AXI":
        dut._log.info("%s",clk_mode)
        cocotb.fork(Clock(dut.clk_axi, *CLK_100MHz).start())
        cocotb.fork(Clock(dut.clk_noc, *CLK_200MHz).start())

async def arst(dut, clk_mode):
    dut.arst_axi.setimmediatevalue(0)
    dut.arst_noc.setimmediatevalue(0)
    dut._log.info("Reset DUT...")
    dut.arst_axi <= 1
    dut.arst_noc <= 1
    if clk_mode == "AXI_>_NoC":
        await ClockCycles(dut.clk_axi, RST_CYCLES)
    else:
        await ClockCycles(dut.clk_noc, RST_CYCLES)
    dut.arst_axi <= 0
    dut.arst_noc <= 0

async def run_test(dut, config_clk=None):
    logging.basicConfig(filename='sim_log', encoding='utf-8', level=logging.DEBUG)
    await setup_clks(dut, config_clk)
    await arst(dut, config_clk)
    for i in range(20):
        await RisingEdge(dut.clk_noc)


if cocotb.SIM_NAME:
    factory = TestFactory(run_test)
    factory.add_option("config_clk", ["AXI_>_NoC", "NoC_>_AXI"])
    factory.generate_tests()

@pytest.mark.skipif((os.getenv("SIM") != "verilator") and (os.getenv("SIM") != "xcelium") and (os.getenv("SIM") != "ius"), reason="Verilator/Xcelium are the only supported to simulate...")
@pytest.mark.parametrize("flavor",["vanilla","coffee"])
def test_ravenoc_basic(flavor):
    tests_dir = os.path.dirname(os.path.abspath(__file__))
    rtl_dir   = os.path.join(tests_dir,"../src/")
    inc_dir   = [f'{rtl_dir}include']
    module    = os.path.splitext(os.path.basename(__file__))[0]
    toplevel  = str(os.getenv("DUT"))
    simulator = str(os.getenv("SIM"))
    verilog_sources = [] # The sequence below is important...
    verilog_sources = verilog_sources + glob.glob(f'{rtl_dir}include/*.sv',recursive=True)
    verilog_sources = verilog_sources + glob.glob(f'{rtl_dir}include/*.svh',recursive=True)
    verilog_sources = verilog_sources + glob.glob(f'{rtl_dir}**/*.sv',recursive=True)
    extra_env = {}
    extra_env['COCOTB_HDL_TIMEUNIT'] = os.getenv("TIMEUNIT")
    extra_env['COCOTB_HDL_TIMEPRECISION'] = os.getenv("TIMEPREC")
    sim_build = os.path.join(tests_dir, f"sim_build_{simulator}_{module}_{flavor}")

    print(sim_build)
    if simulator == "verilator":
        extra_args = ["--trace-fst","--trace-structs","--Wno-UNOPTFLAT"]
    elif simulator == "xcelium" or simulator == "ius":
        #verilog_sources = [" -sv "+i for i in verilog_sources]
        extra_args = ["-64bit                                           \
					   -smartlib				                        \
					   -smartorder			                            \
					   -access +rwc		                                \
					   -clean					                        \
					   -lineclean			                            \
                       -gui                                             \
                       -sv"    ]
    else:
        extra_args = []

    cocotb_test.simulator.run(
        python_search=[tests_dir],
        includes=inc_dir,
        verilog_sources=verilog_sources,
        toplevel=toplevel,
        module=module,
        sim_build=sim_build,
        extra_env=extra_env,
        extra_args=extra_args
    )
