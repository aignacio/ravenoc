#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : test_noc_csr.py
# License           : MIT license <Check LICENSE>
# Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
# Date              : 09.03.2021
# Last Modified Date: 25.06.2023
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
from cocotbext.axi import AxiResp,AxiBurstType
import itertools

async def run_test(dut, config_clk="NoC_slwT_AXI", idle_inserter=None, backpressure_inserter=None):
    noc_flavor = os.getenv("FLAVOR")
    noc_cfg = noc_const.NOC_CFG[noc_flavor]

    # Setup testbench
    idle = "no_idle" if idle_inserter == None else "w_idle"
    backp = "no_backpressure" if backpressure_inserter == None else "w_backpressure"
    tb = Tb(dut, f"sim_{config_clk}_{idle}_{backp}", noc_cfg)
    tb.set_idle_generator(idle_inserter)
    tb.set_backpressure_generator(backpressure_inserter)
    await tb.setup_clks(config_clk)
    await tb.arst(config_clk)
    csr = noc_const.NOC_CSRs

    # RaveNoC Version
    router = randrange(0,noc_cfg['max_nodes'])
    resp = await tb.read(sel=router, address=csr['RAVENOC_VERSION'], length=4, size=0x2)
    assert resp.resp == AxiResp.OKAY, "AXI bus should not have raised an error here!"
    version = resp.data.decode()[::-1] # get object data, convert from bytearray to string with decode method and invert it
    assert version == noc_const.NOC_VERSION, "NoC version not matching with expected!"
    tb.log.info("NoC Version = %s",version)

    # Router X,Y coordinates check
    router = randrange(0,noc_cfg['max_nodes'])
    ref_pkt = RaveNoC_pkt(cfg=noc_cfg, src_dest=(router,0 if router !=0 else 1)) # pkt not used, only to compare in the assertion
    resp_row = await tb.read(sel=router, address=csr['ROUTER_ROW_X_ID'], length=4, size=0x2)
    resp_col = await tb.read(sel=router, address=csr['ROUTER_COL_Y_ID'], length=4, size=0x2)
    assert resp_row.resp == AxiResp.OKAY, "AXI bus should not have raised an error here!"
    assert resp_col.resp == AxiResp.OKAY, "AXI bus should not have raised an error here!"
    resp_row = int.from_bytes(resp_row.data, byteorder='little', signed=False)
    resp_col = int.from_bytes(resp_col.data, byteorder='little', signed=False)
    assert resp_row == ref_pkt.src[1], "NoC CSR - Coordinate ROW not matching"
    assert resp_col == ref_pkt.src[2], "NoC CSR - Coordinate COL not matching"

    # IRQ registers
    router = randrange(0,noc_cfg['max_nodes'])
    resp = await tb.read(sel=router, address=csr['IRQ_RD_STATUS'], length=4, size=0x2)
    assert resp.resp == AxiResp.OKAY, "AXI bus should have raised an error here!"
    irq = resp.data.decode()[::-1]

    router = randrange(0,noc_cfg['max_nodes'])
    rand_data = bytearray(tb._get_random_string(length=4),'utf-8')
    req = await tb.write(sel=router, address=csr['IRQ_RD_MUX'], data=rand_data, size=0x2)
    assert req.resp == AxiResp.OKAY, "AXI bus should have not raised an error here!"
    resp = await tb.read(sel=router, address=csr['IRQ_RD_MUX'], length=4, size=0x2)
    assert resp.resp == AxiResp.OKAY, "AXI bus should have raised an error here!"
    # We need to do the & 7 masking because this CSR has only 3-bits
    data_in = int.from_bytes(rand_data, byteorder='little', signed=False) & 7
    data_out = int.from_bytes(resp.data, byteorder='little', signed=False)
    assert data_in == data_out, "NoC CSR, mismatch on IRQ_RD_MUX - Write/Read back"

    router = randrange(0,noc_cfg['max_nodes'])
    rand_data = bytearray(tb._get_random_string(length=4),'utf-8')
    req = await tb.write(sel=router, address=csr['IRQ_RD_MASK'], data=rand_data, size=0x2)
    assert req.resp == AxiResp.OKAY, "AXI bus should not have raised an error here!"
    resp = await tb.read(sel=router, address=csr['IRQ_RD_MASK'], length=4, size=0x2)
    assert resp.resp == AxiResp.OKAY, "AXI bus should have raised an error here!"
    data_in = int.from_bytes(rand_data, byteorder='little', signed=False)
    data_out = int.from_bytes(resp.data, byteorder='little', signed=False)
    assert data_in == data_out, "NoC CSR, mismatch on IRQ_RD_MASK - Write/Read back"

    # Illegal operations
    not_writable = [csr['RAVENOC_VERSION'],
                    csr['ROUTER_ROW_X_ID'],
                    csr['ROUTER_COL_Y_ID'],
                    csr['IRQ_RD_STATUS'],
                    csr['RD_SIZE_VC_START'],
                    csr['WR_BUFFER_FULL']]
    not_writable.extend([(csr['RD_SIZE_VC_START']+4*x) for x in range(noc_cfg['n_virt_chn'])])
    router = randrange(0,noc_cfg['max_nodes'])
    rand_data = bytearray(tb._get_random_string(length=4),'utf-8')
    for not_wr in not_writable:
        req = await tb.write(sel=router, address=not_wr, data=rand_data, size=0x2)
        assert req.resp == AxiResp.SLVERR, "AXI bus should have raised an error here! ILLEGAL WR CSR:"+hex(not_wr)

    router = randrange(0,noc_cfg['max_nodes'])

    if noc_cfg['flit_data_width'] == 64:
        for i in csr:
            req = await tb.read(sel=router, address=csr[i], size=0x3)
            assert req.resp == AxiResp.SLVERR, "AXI bus should have raised an error here!"
            req = await tb.write(sel=router, address=csr[i], data=rand_data, size=0x3)
            assert req.resp == AxiResp.SLVERR, "AXI bus should have raised an error here!"

    # Testing RD_SIZE_VC[0,1,2...]_PKT
    for vc in range(noc_cfg['n_virt_chn']):
        await tb.arst(config_clk)
        msg_size = randrange(5,noc_cfg['max_sz_pkt'])
        msg = tb._get_random_string(length=msg_size)
        pkt = RaveNoC_pkt(cfg=noc_cfg, msg=msg, virt_chn_id=vc)
        write = cocotb.fork(tb.write_pkt(pkt, timeout=noc_const.TIMEOUT_AXI_EXT))
        await tb.wait_irq()
        resp_csr = await tb.read(sel=pkt.dest[0], address=(csr['RD_SIZE_VC_START']+4*vc), length=4, size=0x2)
        resp_pkt_size = int.from_bytes(resp_csr.data, byteorder='little', signed=False)
        assert resp_pkt_size == pkt.length_beats, "Mistmatch on CSR pkt size vs pkt sent!"
        resp = await tb.read_pkt(pkt, timeout=noc_const.TIMEOUT_AXI_EXT)
        tb.check_pkt(resp.data,pkt.msg)

def cycle_pause():
    return itertools.cycle([1, 1, 1, 0])

if cocotb.SIM_NAME:
    factory = TestFactory(run_test)
    factory.add_option("config_clk", ["AXI_slwT_NoC", "NoC_slwT_AXI", "NoC_equal_AXI"])
    factory.add_option("idle_inserter", [None, cycle_pause])
    factory.add_option("backpressure_inserter", [None, cycle_pause])
    factory.generate_tests()

@pytest.mark.parametrize("flavor",noc_const.regression_setup)
def test_noc_csr(flavor):
    """
    Check all WR/RD CSRs inside the NoC

    Test ID: 7

    Description:
    Write/Read to all CSRs of the NoC. It's also write in READ only registers and
    check if DWORD operations are answered with errors too.
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
