#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : testbench.py
# License           : MIT license <Check LICENSE>
# Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
# Date              : 09.03.2021
# Last Modified Date: 09.03.2021
# Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
import cocotb
import logging
from logging.handlers import RotatingFileHandler
from cocotb.log import SimLogFormatter, SimColourLogFormatter, SimLog, SimTimeContextFilter
from common_noc.constants import noc_const
from cocotb.clock import Clock
from datetime import datetime
from cocotb_bus.drivers.amba import (AXIBurst, AXI4LiteMaster, AXI4Master, AXIProtocolError, AXIReadBurstLengthMismatch,AXIxRESP)
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge, Timer, with_timeout
from common_noc.noc_pkt import NoC_pkt

class Tb:
    def __init__(self, dut, log_name, size=32):
        self.dut = dut
        self.size = size
        self.log = SimLog(log_name)
        self.log.setLevel(logging.DEBUG)
        now = datetime.now()
        timestamp = datetime.timestamp(now)
        timenow = datetime.now().strftime("%d_%b_%Y_%Hh_%Mm_%Ss")
        timenow_wstamp = timenow + str("_") + str(timestamp)
        self.file_handler = RotatingFileHandler(f"{log_name}_{timenow}.log", maxBytes=(5 * 1024 * 1024), backupCount=2, mode='w')
        self.file_handler.setFormatter(SimLogFormatter())
        self.log.addHandler(self.file_handler)
        self.log.addFilter(SimTimeContextFilter())
        self.log.info("+++++++[LOG - %s]+++++++",timenow_wstamp)
        self.log.info("RANDOM_SEED => %s",str(cocotb.RANDOM_SEED))
        self.noc_axi = AXI4Master(self.dut, "NOC", self.dut.clk_axi)
        #file_handler.setFormatter(SimColourLogFormatter())

    def __del__(self):
        # Need to write the last strings in the buffer in the file
        self.log.info("EXITING LOG...")
        self.log.removeHandler(self.file_handler)

    async def write_pkt(self, sel=0, pkt=NoC_pkt, strobe=0xff, **kwargs):
        self.dut.axi_sel.setimmediatevalue(sel)
        # for i in range(pkt.length)
        self.log.info(f"[AXI Master - Write NoC Packet] Slave = ["+str(sel)+"] / "
                        "Address = ["+str(hex(pkt.axi_address))+"] / "
                        "Byte strobe = ["+str(hex(strobe))+"] "
                        "Length = ["+str(pkt.length)+"]")
        self.log.info("[AXI Master - Write NoC Packet] Data:")
        for i in pkt.message:
            self.log.info("----------> [%s]"%hex(i))
        await with_timeout(self.noc_axi.write(address=pkt.axi_address, value=pkt.message,
                            byte_enable=strobe, burst=AXIBurst(0), **kwargs), *noc_const.TIMEOUT_AXI)

    async def write(self, sel=0, address=0x0, data=0x0, strobe=0xff, **kwargs):
        self.log.info(f"[AXI Master - Write] Slave = ["+str(sel)+"] / "
                        "Address = ["+str(hex(address))+"] / "
                        "Data = ["+str(hex(data))+"] / "
                        "Byte strobe = ["+str(hex(strobe))+"]")
        self.dut.axi_sel.setimmediatevalue(sel)
        await with_timeout(self.noc_axi.write(address, data, byte_enable=strobe, **kwargs), *noc_const.TIMEOUT_AXI)

    async def read(self, sel=0, address=0x0, **kwargs):
        self.log.info("[AXI Master - Read] Slave = ["+str(sel)+"] / Address = ["+str(hex(address))+"]")
        self.dut.axi_sel.setimmediatevalue(sel)
        result = await with_timeout(self.noc_axi.read(address, **kwargs), *noc_const.TIMEOUT_AXI)
        return result

    async def setup_clks(self, clk_mode="AXI_gt_NoC"):
        self.log.info(f"[Setup] Configuring the clocks: {clk_mode}")
        if clk_mode == "AXI_gt_NoC":
            cocotb.fork(Clock(self.dut.clk_noc, *noc_const.CLK_100MHz).start())
            cocotb.fork(Clock(self.dut.clk_axi, *noc_const.CLK_200MHz).start())
        else:
            cocotb.fork(Clock(self.dut.clk_axi, *noc_const.CLK_100MHz).start())
            cocotb.fork(Clock(self.dut.clk_noc, *noc_const.CLK_200MHz).start())

    async def arst(self, clk_mode="AXI_gt_NoC"):
        self.log.info("[Setup] Reset DUT")
        self.dut.arst_axi.setimmediatevalue(0)
        self.dut.arst_noc.setimmediatevalue(0)
        self.dut.axi_sel.setimmediatevalue(0)
        self.dut.arst_axi <= 1
        self.dut.arst_noc <= 1
        if clk_mode == "AXI_gt_NoC":
            await ClockCycles(self.dut.clk_axi, noc_const.RST_CYCLES)
        else:
            await ClockCycles(self.dut.clk_noc, noc_const.RST_CYCLES)
        self.dut.arst_axi <= 0
        self.dut.arst_noc <= 0


