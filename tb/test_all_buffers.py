# -*- coding: utf-8 -*-
# File              : test_all_buffers.py
# License           : MIT license <Check LICENSE>
# Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
# Date              : 09.03.2021
# Last Modified Date: 29.03.2021
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
            for flit_buff in range(0,buff_rd_vc(vc)): # We follow this Equation to discover how many buffs exists in each router / (RD_AXI_BFF(x) x<=2?(1<<x):4)
                print("Generating pkt - Router dest=%d Vc=%d flit_buff=%d",router,vc,flit_buff)
                pkts.append(RaveNoC_pkt(cfg=noc_cfg, src_dest=(0,router), virt_chn_id=vc))

    for pkt in pkts:
        await tb.write_pkt(pkt)

    val = 0
    for router in range(1,noc_cfg['max_nodes']):
        val += ((2**noc_cfg['n_virt_chn'])-1) << (router*noc_cfg['n_virt_chn'])

    # Wait for every pkts to be delivered
    tb.log.info("IRQs to wait:%d",val)
    await tb.wait_irq_x(val)

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

def buff_rd_vc(x):
    return (1<<x) if x<=2 else 4

if cocotb.SIM_NAME:
    factory = TestFactory(run_test)
    factory.add_option("config_clk", ["AXI_slwT_NoC", "NoC_slwT_AXI", "NoC_equal_AXI"])
    factory.generate_tests()

@pytest.mark.parametrize("flavor",noc_const.regression_setup)
def test_all_buffers(flavor):
    """
    Test if all buffers of all routers are able to transfer flits

    Test ID: 5

    Description:
    In this test, it'll be dispatched single random flits to all the routers (also all VCs) up to the maximum
    to fill all the buffers inside the NoC. Then we read back all the random pkts to see if they're matching
    and were transferred correctly. It's important to highlight that the number of buffers per VC is calculated
    using the default parameter in the ravenoc_define.svh (RD_AXI_BFF(x) x<=2?(1<<x):4) if the user change this macro,
    it should change the line 34 to represent the correct function that calculates the buffers.
    """
    module = os.path.splitext(os.path.basename(__file__))[0]
    SIM_BUILD = os.path.join(noc_const.TESTS_DIR,
            f"../../run_dir/sim_build_{noc_const.SIMULATOR}_{module}_{flavor}")
    noc_const.EXTRA_ENV['SIM_BUILD'] = SIM_BUILD
    noc_const.EXTRA_ENV['FLAVOR'] = flavor

    extra_args_sim = noc_const._get_cfg_args(flavor)

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
