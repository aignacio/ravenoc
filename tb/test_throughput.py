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
import random
import string

from common_noc.testbench import Tb
from common_noc.constants import noc_const
from common_noc.ravenoc_pkt import RaveNoC_pkt
from cocotb_test.simulator import run
from cocotb.regression import TestFactory
from cocotb.utils import get_sim_time
from random import randrange
from cocotb.result import TestFailure
import itertools

async def run_test(dut, config_clk="NoC_slwT_AXI", idle_inserter=None, backpressure_inserter=None):
    noc_flavor = os.getenv("FLAVOR")
    noc_cfg = noc_const.NOC_CFG[noc_flavor]

    # Setup testbench
    tb = Tb(dut,f"sim_{config_clk}")
    await tb.setup_clks(config_clk)
    await tb.arst(config_clk)

    max_size = (noc_cfg['max_sz_pkt']-1)*(int(noc_cfg['flit_data_width']/8))
    msg = get_random_string(max_size)
    pkt = RaveNoC_pkt(cfg=noc_cfg, src_dest=(0,noc_cfg['max_nodes']-1), message=msg)
    start_time = get_sim_time(units='ns')
    write = cocotb.fork(tb.write_pkt(pkt, timeout=noc_const.TIMEOUT_AXI_EXT))
    await tb.wait_irq()
    resp = await tb.read_pkt(pkt, timeout=noc_const.TIMEOUT_AXI_EXT)
    end_time = get_sim_time(units='ns')
    delta_time_txn = end_time - start_time
    max_size += (int(noc_cfg['flit_data_width']/8)) # Adding header flit into account
    tb.log.info("Delta time = %d ns",delta_time_txn)
    tb.log.info("Bytes transferred = %d B",max_size)
    tb.log.info("BW = %f MB/s",float(max_size/(1024*1024))/float(delta_time_txn*10**-9))
    tb.check_pkt(resp.data,pkt.message)

def cycle_pause():
    return itertools.cycle([1, 1, 1, 0])

def get_random_string(length):
    # choose from all lowercase letter
    letters = string.ascii_lowercase
    result_str = ''.join(random.choice(letters) for i in range(length))
    return result_str
    print("Random string of length", length, "is:", result_str)

if cocotb.SIM_NAME:
    factory = TestFactory(run_test)
    factory.add_option("config_clk", ["AXI_slwT_NoC", "NoC_slwT_AXI", "NoC_equal_AXI"])
    factory.generate_tests()

@pytest.mark.parametrize("flavor",["vanilla","coffee"])
def test_throughput(flavor):
    """
    Test throughput of the NoC computing the total transfer time

    Test ID: 4
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
