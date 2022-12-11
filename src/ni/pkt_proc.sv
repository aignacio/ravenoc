/**
 * File: pkt_proc.sv
 * Description: Implements packet processor combo logic to
 *              to AXI slave and to the NoC
 * Author: Anderson Ignacio da Silva <anderson@aignacio.com>
 *
 * MIT License
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
module pkt_proc
  import amba_axi_pkg::*;
  import ravenoc_pkg::*;
(
  input                     clk_axi,
  input                     arst_axi,

  // Interface with NoC
  router_if.send_flit       local_send,
  router_if.recv_flit       local_recv,

  // Interface with AXI Slave
  // AXI Slave -> Pkt Gen
  input   s_pkt_out_req_t   pkt_out_req_i,
  output  s_pkt_out_resp_t  pkt_out_resp_o,

  // AXI Salve <- Pkt Gen
  output  s_pkt_in_req_t    pkt_in_req_o,
  input   s_pkt_in_resp_t   pkt_in_resp_i
);
  logic [PktWidth-1:0]      pkt_cnt_ff, next_pkt_cnt;
  logic                     wr_txn_ff, next_wr_txn;

  // **************************
  //
  // Send flits from AXI Wr data channel -> NoC (local input buffer)
  //
  // **************************
  always_comb begin : to_noc
    local_send.req = '0;
    pkt_out_resp_o.ready = local_send.resp.ready;
    next_wr_txn  = wr_txn_ff;
    next_pkt_cnt = pkt_cnt_ff;

    if (pkt_out_req_i.valid) begin
      local_send.req.fdata[FlitDataWidth-1:0]       = pkt_out_req_i.flit_data_width;
      local_send.req.vc_id                          = pkt_out_req_i.vc_id;
      local_send.req.valid                          = 1'b1;

      if (~wr_txn_ff && (pkt_out_req_i.pkt_sz > 0)) begin
        next_wr_txn = 1'b1;
        next_pkt_cnt = pkt_out_resp_o.ready ? (pkt_out_req_i.pkt_sz-'d1) : pkt_out_req_i.pkt_sz;
      end

      if (wr_txn_ff && (pkt_cnt_ff > 0) && pkt_out_resp_o.ready) begin
        next_pkt_cnt = pkt_cnt_ff - 'd1;
      end

      if (wr_txn_ff && (pkt_cnt_ff == 0) && pkt_out_resp_o.ready) begin
        next_wr_txn = 1'b0;
      end

      if (~wr_txn_ff) begin
        local_send.req.fdata[FlitWidth-1:FlitWidth-2] = HEAD_FLIT;
      end
      else if (wr_txn_ff && (pkt_cnt_ff > 0)) begin
        local_send.req.fdata[FlitWidth-1:FlitWidth-2] = BODY_FLIT;
      end
      else begin
        local_send.req.fdata[FlitWidth-1:FlitWidth-2] = TAIL_FLIT;
      end
    end
  end

  always_ff @ (posedge clk_axi or posedge arst_axi) begin
    if (arst_axi) begin
      pkt_cnt_ff <= 'd0;
      wr_txn_ff  <= 1'b0;
    end
    else begin
      pkt_cnt_ff <= next_pkt_cnt;
      wr_txn_ff  <= next_wr_txn;
    end
  end

  // **************************
  //
  // Receive flits from NoC -> Send to AXI RX buffer
  //
  // **************************
  always_comb begin : from_noc
    pkt_in_req_o.valid = local_recv.req.valid;
    // We remove the flit type to send to the buffer
    pkt_in_req_o.flit_data_width = local_recv.req.fdata[FlitDataWidth-1:0];
    pkt_in_req_o.rq_vc = local_recv.req.vc_id;
    local_recv.resp.ready = pkt_in_resp_i.ready;
  end
endmodule
