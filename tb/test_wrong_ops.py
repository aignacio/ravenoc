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

from testbench import Tb
from default_values import *
from cocotb_test.simulator import run
from cocotb.regression import TestFactory
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge, Timer, with_timeout
from random import randint, randrange, getrandbits
from cocotb_bus.drivers.amba import (AXIBurst, AXI4LiteMaster, AXI4Master, AXIProtocolError, AXIReadBurstLengthMismatch,AXIxRESP)
#from cocotbext.axi import AxiMaster

async def run_test(dut, config_clk=None):
    tb = Tb(dut,f"sim_{config_clk}")
    await tb.setup_clks(config_clk)
    await tb.arst(config_clk)

    axi_master = AXI4Master(tb.dut, "NOC", tb.dut.clk_axi)
    tb.dut.axi_sel = 4;

    data_width = 32
    address = 0x100c
    write_value = randrange(0, 2**(data_width * 8))
    strobe = 0xf

    try:
        await with_timeout(axi_master.write(0x100c, write_value, byte_enable=strobe), *TIMEOUT_AXI)
    except AXIProtocolError as e:
        tb.log.info("Exception: %s" % str(e))
        tb.log.info("Bus successfully raised an error")
    else:
        assert False, "AXI bus should have raised an error when writing to an invalid burst type"

    try:
        data = await with_timeout(axi_master.read(address), *TIMEOUT_AXI)
    except AXIProtocolError as e:
        tb.log.info("Exception: %s" % str(e))
        tb.log.info("Bus successfully raised an error")
    else:
        assert False, "AXI bus should have raised an error when writing to an invalid burst type"

    await tb.arst(config_clk)

    try:
        data = await with_timeout(axi_master.read(address=0x200c, burst=AXIBurst(0)), *TIMEOUT_AXI)
    except AXIProtocolError as e:
        tb.log.info("Exception: %s" % str(e))
        tb.log.info("Bus successfully raised an error")
    else:
        assert False, "AXI bus should have raised an error when reading from an empty buffer"


if cocotb.SIM_NAME:
    factory = TestFactory(run_test)
    factory.add_option("config_clk", ["AXI_gt_NoC", "NoC_gt_AXI"])
    factory.generate_tests()

@pytest.mark.parametrize("flavor",["vanilla","coffee"])
def test_wrong_ops(flavor):
    """
    Checks if the AXI-S/NoC is capable of throwing an errors when illegal operations are done

    Test ID: 1
    Expected Results: It's expected the NoC/AXI slave interface to refuse the txn throwing
    an error on the slave interface due to not supported requests
    """
    module = os.path.splitext(os.path.basename(__file__))[0]
    sim_build = os.path.join(tests_dir, f"../run_dir/sim_build_{simulator}_{module}_{flavor}")
    extra_env['SIM_BUILD'] = sim_build
    extra_args = extra_args_vanilla if flavor == "vanilla" else extra_args_coffee
    run(
        python_search=[tests_dir],
        includes=inc_dir,
        verilog_sources=verilog_sources,
        toplevel=toplevel,
        module=module,
        sim_build=sim_build,
        extra_env=extra_env,
        extra_args=extra_args
    )
