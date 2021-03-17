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
from common_noc.ravenoc_pkt import RaveNoC_pkt
from cocotb.regression import TestFactory
from cocotb.triggers import ClockCycles, Timer, with_timeout, Edge
from random import randint, randrange, getrandbits
from cocotb_bus.drivers.amba import AXIBurst

async def run_test(dut, config_clk=None):
    noc_flavor = os.getenv("FLAVOR")
    noc_cfg = noc_const.NOC_CFG[noc_flavor]

    tb = Tb(dut,f"sim_{config_clk}_{noc_flavor}")
    await tb.setup_clks(config_clk)
    await tb.arst(config_clk)

if cocotb.SIM_NAME:
    factory = TestFactory(run_test)
    factory.add_option("config_clk", ["AXI_slwT_NoC", "NoC_slwT_AXI"])
    factory.generate_tests()

@pytest.mark.parametrize("flavor",["vanilla","coffee"])
def test_all_nodes(flavor):
    """
    Elects a sender node and sends a single flit to all nodes in the NoC and
    then reads it back.

    Test ID: 3
    Expected Results: Received packet should match with the sent ones
    """
    module = os.path.splitext(os.path.basename(__file__))[0]
    SIM_BUILD = os.path.join(noc_const.TESTS_DIR,
            f"../../run_dir/sim_build_{noc_const.SIMULATOR}_{module}_{flavor}")
    noc_const.EXTRA_ENV['SIM_BUILD'] = SIM_BUILD
    noc_const.EXTRA_ENV['FLAVOR'] = flavor
    extra_args_sim = noc_const.EXTRA_ARGS_VANILLA if flavor == "vanilla" else noc_const.EXTRA_ARGS_COFFEE
    run(
        python_search=[noc_const.TESTS_DIR],
        includes=noc_const.INC_DIR,
        verilog_sources=noc_const.VERILOG_SOURCES,
        toplevel=noc_const.TOPLEVEL,
        module=module,
        sim_build=SIM_BUILD,
        extra_env=noc_const.EXTRA_ENV,
        extra_args=extra_args_sim
    )
