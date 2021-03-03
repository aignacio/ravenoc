import cocotb
import logging
from logging.handlers import RotatingFileHandler
from cocotb.log import SimLogFormatter, SimColourLogFormatter, SimLog, SimTimeContextFilter
from default_values import *
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge, Timer
from cocotb.log import SimColourLogFormatter, SimLog, SimTimeContextFilter

class Tb:
    def __init__(self, dut, log_name):
        self.dut = dut
        self.log = SimLog(log_name)
        self.log.setLevel(logging.DEBUG)
        file_handler = RotatingFileHandler(f"{log_name}.log", maxBytes=(5 * 1024 * 1024), backupCount=2, mode='w')
        file_handler.setFormatter(SimLogFormatter())
        self.log.addHandler(file_handler)
        self.log.addFilter(SimTimeContextFilter())
        self.log.info("RANDOM_SEED => %s",str(cocotb.RANDOM_SEED))
        #file_handler.setFormatter(SimColourLogFormatter())

    async def setup_clks(self, clk_mode):
        self.log.info(f"[Setup] Configuring the clocks: {clk_mode}")
        if clk_mode == "AXI_>_NoC":
            cocotb.fork(Clock(self.dut.clk_noc, *CLK_100MHz).start())
            cocotb.fork(Clock(self.dut.clk_axi, *CLK_200MHz).start())
        else:
            cocotb.fork(Clock(self.dut.clk_axi, *CLK_100MHz).start())
            cocotb.fork(Clock(self.dut.clk_noc, *CLK_200MHz).start())

    async def arst(self, clk_mode="AXI_>_NoC"):
        self.log.info("[Setup] Reset DUT")
        self.dut.arst_axi.setimmediatevalue(0)
        self.dut.arst_noc.setimmediatevalue(0)
        self.dut.axi_sel.setimmediatevalue(0)
        self.dut.arst_axi <= 1
        self.dut.arst_noc <= 1
        if clk_mode == "AXI_>_NoC":
            await ClockCycles(self.dut.clk_axi, RST_CYCLES)
        else:
            await ClockCycles(self.dut.clk_noc, RST_CYCLES)
        self.dut.arst_axi <= 0
        self.dut.arst_noc <= 0


