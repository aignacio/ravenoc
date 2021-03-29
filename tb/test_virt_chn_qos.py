#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : test_virt_chn_qos.py
# License           : MIT license <Check LICENSE>
# Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
# Date              : 29.03.2021
# Last Modified Date: 29.03.2021
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
from cocotb.triggers import ClockCycles, RisingEdge, with_timeout, ReadOnly, Event
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

    if (noc_cfg['max_nodes'] >= 3) and (noc_cfg['n_virt_chn']>1):
        max_size = (noc_cfg['max_sz_pkt']-1)*(int(noc_cfg['flit_data_width']/8))

        high_prior_vc = (noc_cfg['n_virt_chn']-1) if noc_cfg['h_priority'] == 1 else 0
        low_prior_vc = 0 if noc_cfg['h_priority'] == 1 else (noc_cfg['n_virt_chn']-1)

        pkt_lp = RaveNoC_pkt(cfg=noc_cfg, msg=tb._get_random_string(max_size), src_dest=(1,noc_cfg['max_nodes']-1), virt_chn_id=low_prior_vc)
        pkt_hp = RaveNoC_pkt(cfg=noc_cfg, src_dest=(0,noc_cfg['max_nodes']-1), virt_chn_id=high_prior_vc)
        pkts = [pkt_hp,pkt_lp]

        wr_lp_pkt = cocotb.fork(tb.write_pkt(pkt=pkt_lp, timeout=noc_const.TIMEOUT_AXI_EXT)) #We need to extend the timeout once it's the max pkt sz
        wr_hp_pkt = cocotb.fork(tb.write_pkt(pkt=pkt_hp,use_side_if=1))

        await wr_hp_pkt

        # Just to ensure the HP pkt has been sent over the NoC
        # and the LP pkt is still being processed
        assert((wr_lp_pkt._finished == False) and (wr_hp_pkt._finished == True))
        lp_prior = 2**(noc_cfg['n_virt_chn']-1)
        hp_prior = 2**(0)
        irq_lp_hp = (lp_prior+hp_prior) << (noc_cfg['max_nodes']-1)*noc_cfg['n_virt_chn']
        tb.log.info("IRQs to wait: %d",irq_lp_hp)
        await tb.wait_irq_x(irq_lp_hp)

        for pkt in pkts:
            resp = await tb.read_pkt(pkt=pkt, timeout=noc_const.TIMEOUT_AXI_EXT)
            tb.check_pkt(resp.data,pkt.msg)
    else:
        tb.log.info("Test not executed due to the NoC Size, min >=3 routers && min > 1 VCs")

def cycle_pause():
    return itertools.cycle([1, 1, 1, 0])

if cocotb.SIM_NAME:
    factory = TestFactory(run_test)
    factory.add_option("config_clk", ["AXI_slwT_NoC", "NoC_slwT_AXI", "NoC_equal_AXI"])
    factory.generate_tests()

@pytest.mark.parametrize("flavor",noc_const.regression_setup)
def test_virt_chn_qos(flavor):
    """
    Test the QoS of VCs in the NoC

    Test ID: 6

    Description:
    In this test, we send a LOW priority (can be vc_id=0 or vc_id=Max, depending upon cfg) pkt with the maximum size of
    payload and a HIGH priority pkt with a single flit size through the NoC. The src routers which it'll be send will be
    router 0 for the HP pkt and router 1 for the LP one, because it'll be executed at the same time with fork(). Both pkts
    will have as destiny the last Router in NoC thus sharing the same datapath. The expectation is that the HP pkt will
    finish earlier than the LP (assert wr_....) using the same datapath, then we read both and check if the respective
    contents are matching.
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
