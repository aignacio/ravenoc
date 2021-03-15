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
from random import randint, randrange, getrandbits

class NoC_pkt:
    def __init__(self, cfg, message="test",
                 length_bytes=1, x_dest=0, y_dest=0,
                 op="write", virt_chn_id=0):
        # Max width in bits of head flit msg
        self.max_hflit_w = cfg['flit_data']-cfg['x_w']-cfg['y_w']-cfg['sz_pkt_w']
        # Max width in bytes of head flit msg
        self.max_bytes_hflit = math.floor(self.max_hflit_w/8)
        self.axi_address = cfg['vc_w_id'][virt_chn_id] if op == "write" else cfg['vc_r_id'][virt_chn_id]
        num_bytes_per_flit = int(cfg['flit_data']/8)
        # Head Flit:
        # -> Considering coffee/vanilla flavors, the head flit can be written as:
        # 1) Coffee:
        # 65---------------63-----------------------------------------------------------0
        # | FLIT_TYPE (2b) | X_DEST (2b) | Y_DEST (2b) | PKT_WIDTH (8b) | MESSAGE (52b) |
        # +-----------------------------------------------------------------------------+
        # FLIT_TYPE is prepended by the NoC
        # 2) Vanilla:
        # 33---------------31-----------------------------------------------------------0
        # | FLIT_TYPE (2b) | X_DEST (1b) | Y_DEST (1b) | PKT_WIDTH (8b) | MESSAGE (20b) |
        # +-----------------------------------------------------------------------------+
        # FLIT_TYPE is prepended by the NoC
        # It's required to apply a mask on top of the initial flit head msg
        head_overhead_delta = (cfg['flit_data']/8)-self.max_bytes_hflit # Number of bytes just for head flit
        # To make things simpler, if message size is smaller or equal to the size
        # of min num bytes into a single flit, we concatenate in the head flit
        # otherwise we add some random data on head flit and send the message in
        # the following flits (body+tail)
        if (length_bytes <= self.max_bytes_hflit):
            self.message = bytearray(message,'utf-8')
            self.length = 1
            msg_hflit = 0
            for byte_idx in range(self.max_bytes_hflit):
                msg_hflit = msg_hflit | (int(self.message[byte_idx]) << (byte_idx*8))
            self.hflit = msg_hflit
            self.hflit = self.hflit | (self.length << (self.max_hflit_w))
            self.hflit = self.hflit | (y_dest << (cfg['sz_pkt_w']+self.max_hflit_w))
            self.hflit = self.hflit | (x_dest << (cfg['y_w']+cfg['sz_pkt_w']+self.max_hflit_w))
            self.message = int(self.hflit)
        else:
            self.length = 1+math.ceil(length_bytes/num_bytes_per_flit)
            # We need to pad with zero char to match bus data width once
            if length_bytes%num_bytes_per_flit != 0:
                while len(message)%num_bytes_per_flit != 0:
                    message += '\0'
            msg_hflit = randrange(0, (self.max_bytes_hflit*(256))-1)
            self.hflit = msg_hflit
            self.hflit = self.hflit | (self.length << (self.max_hflit_w))
            self.hflit = self.hflit | (y_dest << (cfg['sz_pkt_w']+self.max_hflit_w))
            self.hflit = self.hflit | (x_dest << (cfg['y_w']+cfg['sz_pkt_w']+self.max_hflit_w))
            message = bytearray(message,'utf-8')
            data_in_beats = [int.from_bytes(message[i:i+num_bytes_per_flit],byteorder="big") for i in range(0,len(message),num_bytes_per_flit)]
            self.message = []
            self.message.append(self.hflit)
            self.message.extend(data_in_beats)
            # print(self.message)
            # for i in range(self.max_bytes_hflit):
                # self.message[:0] = self.hflit[i]
            # self.message[:0] = bytearray(str(self.hflit),'utf-8')
            # tmp = []
            # tmp.append(self.hflit)
            # for i in self.message[1::num_bytes_per_flit]:
                # acc = 0
                # for j in num_bytes_per_flit:
                    # acc = acc + int(self.message[i+j])<<(num_bytes_per_flit*8)
                # tmp.append(acc)
            # self.message = tmp
            # self.messageF = [int(self.message[i]+) for i in self.message[1::num_bytes_per_flit]]
            #self.message = str(self.hflit)+message:w

        # self.message = [int(self.hflit),45,23]#[int(i) for i in self.message]
        # self.message = int.from_bytes(self.message, byteorder='big', signed=False)

