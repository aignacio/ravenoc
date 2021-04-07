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
  input   s_pkt_out_req_t   pkt_out_req_i,
  output  s_pkt_out_resp_t  pkt_out_resp_o,

  // AXI Salve <- Pkt Gen
  output  s_pkt_in_req_t    pkt_in_req_o,
  input   s_pkt_in_resp_t   pkt_in_resp_i
);
  // **************************
  //
  // Send flits from AXI Wr data channel -> NoC (local input buffer)
  //
  // **************************
  always_comb begin : to_noc
    pkt_out_resp_o.ready = local_send.resp.ready;
    local_send.req = '0;

    if (pkt_out_req_i.valid) begin
      priority if (pkt_out_req_i.req_new) begin
        local_send.req.fdata[FlitWidth-1:FlitWidth-2] = HEAD_FLIT;
        local_send.req.fdata[FlitDataWidth-1:0] = pkt_out_req_i.flit_data_width;
        if (`AUTO_ADD_PKT_SZ == 1) begin
          local_send.req.fdata[(MinDataWidth-1):(MinDataWidth-PktWidth)] = pkt_out_req_i.pkt_sz;
        end
      end
      else if (pkt_out_req_i.req_last) begin
        local_send.req.fdata[FlitWidth-1:FlitWidth-2] = TAIL_FLIT;
        local_send.req.fdata[FlitDataWidth-1:0] = pkt_out_req_i.flit_data_width;
      end
      else begin
        local_send.req.fdata[FlitWidth-1:FlitWidth-2] = BODY_FLIT;
        local_send.req.fdata[FlitDataWidth-1:0] = pkt_out_req_i.flit_data_width;
      end

      local_send.req.vc_id = pkt_out_req_i.vc_id;
      local_send.req.valid = '1;
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
