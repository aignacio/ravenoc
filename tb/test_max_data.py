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
from common_noc.ravenoc_pkt import RaveNoC_pkt
from cocotb_test.simulator import run
from cocotb.regression import TestFactory
from random import randrange
from cocotb.result import TestFailure
import itertools

async def run_test(dut, config_clk="NoC_slwT_AXI", idle_inserter=None, backpressure_inserter=None):
    noc_flavor = os.getenv("FLAVOR")
    noc_cfg = noc_const.NOC_CFG[noc_flavor]

    # Setup testbench
    idle = "no_idle" if idle_inserter == None else "w_idle"
    backp = "no_backpressure" if backpressure_inserter == None else "w_backpressure"
    tb = Tb(dut,f"sim_{config_clk}_{idle}_{backp}")
    tb.set_idle_generator(idle_inserter)
    tb.set_backpressure_generator(backpressure_inserter)
    await tb.setup_clks(config_clk)
    await tb.arst(config_clk)

    msg = "ddddddddddddddkjndn3n4j3n3n24jn23j4nj23 23n4j2 n34j2n3 4j 2j34cn32j4n23j4nj234nk3nj4 kn4cknlqln cl3 qc4n34kl n4n 3qk4jnqj4 342j k4n2 k4n l234n 2l34n24ldddddddddddssssssss"
    pkt = RaveNoC_pkt(cfg=noc_cfg, message=msg)
    write = cocotb.fork(tb.write_pkt(pkt))
    await tb.wait_irq()
    resp = await tb.read_pkt(pkt)
    tb.check_pkt(resp.data,pkt.message)

def cycle_pause():
    return itertools.cycle([1, 1, 1, 0])

if cocotb.SIM_NAME:
    factory = TestFactory(run_test)
    factory.add_option("config_clk", ["AXI_slwT_NoC", "NoC_slwT_AXI", "NoC_equal_AXI"])
    factory.add_option("idle_inserter", [None, cycle_pause])
    factory.add_option("backpressure_inserter", [None, cycle_pause])
    factory.generate_tests()

@pytest.mark.parametrize("flavor",["vanilla","coffee"])
def test_max_data(flavor):
    """
    Basic test that sends a packet over the NoC and checks it

    Test ID: 1
    Expected Results: Received packet should match with the sent one
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
