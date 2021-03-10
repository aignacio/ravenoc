#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : test_ravenoc_basic.py
# License           : MIT license <Check LICENSE>
# Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
# Date              : 09.03.2021
# Last Modified Date: 09.03.2021
# Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
import random
import cocotb
import os
import logging
import pytest

from common_noc.testbench import Tb
from common_noc.constants import noc_const
from cocotb_test.simulator import run
from cocotb.regression import TestFactory
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge, Timer
from random import randint, randrange, getrandbits

async def run_test(dut, config_clk=None):
    noc_flavor = os.getenv("FLAVOR")
    tb = Tb(dut,f"sim_{config_clk}")
    await tb.setup_clks(config_clk)
    await tb.arst(config_clk)

    source_node = randrange(0, noc_const.MAX_NODES[str(os.getenv("FLAVOR"))]-1)
    dest_node = randrange(0, noc_const.MAX_NODES[str(os.getenv("FLAVOR"))]-1)
    tb.dut.axi_sel = source_node


if cocotb.SIM_NAME:
    factory = TestFactory(run_test)
    factory.add_option("config_clk", ["AXI_gt_NoC", "NoC_gt_AXI"])
    factory.generate_tests()

@pytest.mark.parametrize("flavor",["vanilla","coffee"])
def test_ravenoc_basic(flavor):
    """
    Basic test that sends a packet over the NoC and checks it

    Test ID: 2
    Expected Results: Received packet should match with the sent one
    """
    module = os.path.splitext(os.path.basename(__file__))[0]
    SIM_BUILD = os.path.join(noc_const.TESTS_DIR, f"../../run_dir/sim_build_{noc_const.SIMULATOR}_{module}_{flavor}")
    noc_const.EXTRA_ENV['SIM_BUILD'] = SIM_BUILD
    noc_const.EXTRA_ENV['FLAVOR'] = flavor
    EXTRA_ARGS = noc_const.EXTRA_ARGS_VANILLA if flavor == "vanilla" else noc_const.EXTRA_ARGS_COFFEE
    run(
        python_search=[noc_const.TESTS_DIR],
        includes=noc_const.INC_DIR,
        verilog_sources=noc_const.VERILOG_SOURCES,
        toplevel=noc_const.TOPLEVEL,
        module=module,
        sim_build=SIM_BUILD,
        extra_env=noc_const.EXTRA_ENV,
        extra_args=EXTRA_ARGS
    )
