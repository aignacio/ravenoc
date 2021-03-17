/**
 * File: router_wrapper.sv
 * Description: RaveNoC router wrapper, encapsulates router+ni
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
module router_wrapper import ravenoc_pkg::*; # (
  parameter ROUTER_X_ID = 0,
  parameter ROUTER_Y_ID = 0,
  parameter CDC_REQUIRED = 1
) (
  input                 clk_axi,
  input                 clk_noc,
  input                 arst_axi,
  input                 arst_noc,
  router_if.send_flit   north_send,
  router_if.recv_flit   north_recv,
  router_if.send_flit   south_send,
  router_if.recv_flit   south_recv,
  router_if.send_flit   west_send,
  router_if.recv_flit   west_recv,
  router_if.send_flit   east_send,
  router_if.recv_flit   east_recv,
  // AXI I/F with PE
  input   s_axi_mosi_t  axi_mosi_if,
  output  s_axi_miso_t  axi_miso_if,
  // IRQs
  output  s_irq_ni_t    ni_irqs
);
  router_if local_port_send ();
  router_if local_port_send_tmp ();
  router_if local_port_recv ();
  router_if local_port_recv_tmp ();

  s_pkt_out_req_t   pkt_out_req;
  s_pkt_out_resp_t  pkt_out_resp;
  s_pkt_in_req_t    pkt_in_req;
  s_pkt_in_resp_t   pkt_in_resp;

  router_ravenoc#(
    .ROUTER_X_ID(ROUTER_X_ID),
    .ROUTER_Y_ID(ROUTER_Y_ID)
  ) u_router (
    .clk         (clk_noc),
    .arst        (arst_noc),
    .north_send  (north_send),
    .north_recv  (north_recv),
    .south_send  (south_send),
    .south_recv  (south_recv),
    .west_send   (west_send),
    .west_recv   (west_recv),
    .east_send   (east_send),
    .east_recv   (east_recv),
    .local_send  (local_port_send),
    .local_recv  (local_port_recv)
  );

  axi_slave_if u_axi_local (
    .clk_axi     (clk_axi),
    .clk_noc     (clk_noc),
    .arst_axi    (arst_axi),
    .arst_noc    (arst_noc),
    // AXI I/F
    .axi_mosi_if (axi_mosi_if),
    .axi_miso_if (axi_miso_if),
    // Interface with the Packet Generator
    // AXI Slave -> Pkt Gen
    .pkt_out_req (pkt_out_req),
    .pkt_out_resp(pkt_out_resp),
    // AXI Salve <- Pkt Gen
    .pkt_in_req  (pkt_in_req),
    .pkt_in_resp (pkt_in_resp),
    // IRQ signals
    .ni_irqs     (ni_irqs)
  );

  pkt_proc u_pkt_proc (
    // Interface with NoC
    .local_send  (local_port_recv_tmp),
    .local_recv  (local_port_send_tmp),
    // Interface with AXI Slave
    // AXI Slave -> Pkt Gen
    .pkt_out_req (pkt_out_req),
    .pkt_out_resp(pkt_out_resp),
    // AXI Salve <- Pkt Gen
    .pkt_in_req  (pkt_in_req),
    .pkt_in_resp (pkt_in_resp)
  );

  generate
    if (CDC_REQUIRED == 1) begin
      cdc_pkt #(
        .CDC_STEPS(2)
      ) u_cdc_pkt (
        .clk_axi          (clk_axi),
        .clk_noc          (clk_noc),
        .arst_axi         (arst_axi),
        .arst_noc         (arst_noc),
        //--------------------------------
        // AXI --> NoC I/F
        //--------------------------------
        // Send interface Input AXI clk domain
        .flit_req_axi_axi (local_port_recv_tmp),
        // Send interface output NoC clk domain
        .flit_req_axi_noc (local_port_recv),
        //--------------------------------
        // NoC --> AXI I/F
        //--------------------------------
        // Send interface Input NoC clk domain
        .flit_req_noc_noc (local_port_send),
        // Send interface output AXI clk domain
        .flit_req_noc_axi (local_port_send_tmp)
      );
    end
    else begin
      assign local_port_recv.req = local_port_recv_tmp.req;
      assign local_port_recv_tmp.resp = local_port_recv.resp;

      assign local_port_send_tmp.req = local_port_send.req;
      assign local_port_send.resp = local_port_send_tmp.resp;
    end
  endgenerate
endmodule
