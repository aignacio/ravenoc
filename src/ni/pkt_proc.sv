/**
 * File: pkt_proc.sv
 * Description: Implements packet processor combo logic to
 *              to AXI slave and to the NoC
 * Author: Anderson Ignacio da Silva <aignacio@aignacio.com>
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
module pkt_proc import ravenoc_pkg::*; (
  // Interface with NoC
  router_if.send_flit       local_send,
  router_if.recv_flit       local_recv,

  // Interface with AXI Slave
  // AXI Slave -> Pkt Gen
  input   s_pkt_out_req_t   pkt_out_req,
  output  s_pkt_out_resp_t  pkt_out_resp,

  // AXI Salve <- Pkt Gen
  output  s_pkt_in_req_t    pkt_in_req,
  input   s_pkt_in_resp_t   pkt_in_resp
);
  // **************************
  //
  // Send flits from AXI Wr data channel -> NoC (local input buffer)
  //
  // **************************
  always_comb begin : to_noc
    pkt_out_resp.ready = local_send.resp.ready;
    local_send.req = '0;

    if (pkt_out_req.valid) begin
      priority if (pkt_out_req.req_new) begin
        local_send.req.fdata[FLIT_WIDTH-1:FLIT_WIDTH-2] = HEAD_FLIT;
        local_send.req.fdata[FLIT_DATA-1:0] = pkt_out_req.flit_data[FLIT_DATA-1:0];
        local_send.req.fdata[(PKT_POS_WIDTH-1):(PKT_POS_WIDTH-PKT_WIDTH)] = pkt_out_req.pkt_sz;
      end
      else if (pkt_out_req.req_last) begin
        local_send.req.fdata[FLIT_WIDTH-1:FLIT_WIDTH-2] = TAIL_FLIT;
        local_send.req.fdata[FLIT_DATA-1:0] = pkt_out_req.flit_data;
      end
      else begin
        local_send.req.fdata[FLIT_WIDTH-1:FLIT_WIDTH-2] = BODY_FLIT;
        local_send.req.fdata[FLIT_DATA-1:0] = pkt_out_req.flit_data;
      end

      local_send.req.vc_id = pkt_out_req.vc_id;
      local_send.req.valid = '1;
    end
  end

  // **************************
  //
  // Receive flits from NoC -> Send to AXI RX buffer
  //
  // **************************
  always_comb begin : from_noc
    pkt_in_req.valid = local_recv.req.valid;
    // We remove the flit type to send to the buffer
    pkt_in_req.flit_data = local_recv.req.fdata[FLIT_DATA-1:0];
    pkt_in_req.rq_vc = local_recv.req.vc_id;
    local_recv.resp.ready = pkt_in_resp.ready;
  end
endmodule
