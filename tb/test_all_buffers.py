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
import itertools

async def run_test(dut, config_clk="NoC_slwT_AXI", idle_inserter=None, backpressure_inserter=None):
    noc_flavor = os.getenv("FLAVOR")
    noc_cfg = noc_const.NOC_CFG[noc_flavor]

    # Setup testbench
    tb = Tb(dut,f"sim_{config_clk}")
    await tb.setup_clks(config_clk)
    await tb.arst(config_clk)

    # Populate all buffers of all vcs of all routers from router 0
    pkts = []
    for router in range(1,noc_cfg['max_nodes']):
        for vc in range(0,noc_cfg['n_virt_chn']):
            for flit_buff in range(0,1<<vc):
                print("Generating pkt - Router dest=%d Vc=%d flit_buff=%d",router,vc,flit_buff)
                pkts.append(RaveNoC_pkt(cfg=noc_cfg, src_dest=(0,router), virt_chn_id=vc))

    for pkt in pkts:
        await tb.write_pkt(pkt)

    await tb.wait_irq()

    for pkt in pkts:
        resp = await tb.read_pkt(pkt)
        tb.check_pkt(resp.data,pkt.msg)

    # Populate all vcs of router 0 from router 1
    pkts = []
    for vc in range(0,noc_cfg['n_virt_chn']):
        for flit_buff in range(0,1<<vc):
            print("Generating pkt - Router dest=0 Vc=%d flit_buff=%d",vc,flit_buff)
            pkts.append(RaveNoC_pkt(cfg=noc_cfg, src_dest=(1,0), virt_chn_id=vc))

    for pkt in pkts:
        await tb.write_pkt(pkt)

    await tb.wait_irq()

    for pkt in pkts:
        resp = await tb.read_pkt(pkt)
        tb.check_pkt(resp.data,pkt.msg)


if cocotb.SIM_NAME:
    factory = TestFactory(run_test)
    factory.add_option("config_clk", ["AXI_slwT_NoC", "NoC_slwT_AXI", "NoC_equal_AXI"])
    factory.generate_tests()

@pytest.mark.parametrize("flavor",["vanilla","coffee"])
def test_all_buffers(flavor):
    """
    Populate all buffers of all routers and reads back

    Test ID: 5
    Expected Results: Received packets should match with the sent ones
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
