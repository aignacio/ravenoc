#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : noc_pkt.py
# License           : MIT license <Check LICENSE>
# Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
# Date              : 09.03.2021
# Last Modified Date: 09.03.2021
# Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
import cocotb
import logging
import math
from common_noc.constants import noc_const
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge, Timer
from cocotb.log import SimColourLogFormatter, SimLog, SimTimeContextFilter
from datetime import datetime

class NoC_pkt:
    def __init__(self, cfg, message="A",
                 length=1, x_dest=0, y_dest=0,
                 op="write", virt_chn_id=0):
        # Max width in bits of head flit msg
        self.max_hflit_w = cfg['flit_data']-cfg['x_w']-cfg['y_w']-cfg['pkt_w']
        # Max width in bytes of head flit msg
        self.max_bytes_hflit = math.floor(self.max_hflit_w/8)
        self.axi_address = cfg['vc_w_id'][virt_chn_id] if op == "write" else cfg['vc_r_id'][virt_chn_id]
        # Head Flit:
        # -> Considering coffee/vanilla flavors, the head flit can be written as:
        # 1) Coffee:
        # 65---------------63-----------------------------------------------------------0
        # | FLIT_TYPE (2b) | X_DEST (3b) | Y_DEST (2b) | PKT_WIDTH (8b) | MESSAGE (51b) |
        # +-----------------------------------------------------------------------------+
        # FLIT_TYPE is prepended by the NoC
        # 2) Vanilla:
        # 33---------------31-----------------------------------------------------------0
        # | FLIT_TYPE (2b) | X_DEST (2b) | Y_DEST (2b) | PKT_WIDTH (8b) | MESSAGE (20b) |
        # +-----------------------------------------------------------------------------+
        # FLIT_TYPE is prepended by the NoC
        # It's required to apply a mask on top of the initial flit head msg
        mask_msg_hflit = (((2**8)*self.max_bytes_hflit)-1)
        message = bytearray(message,'utf-8')
        msg_hflit = 0
        for byte_idx in range(self.max_bytes_hflit):
            msg_hflit = msg_hflit | (int(message[byte_idx]) << (byte_idx*8))
        self.hflit = msg_hflit
        self.hflit = self.hflit | (y_dest << (cfg['pkt_w']+self.max_hflit_w))
        self.hflit = self.hflit | (x_dest << (cfg['y_w']+cfg['pkt_w']+self.max_hflit_w))
