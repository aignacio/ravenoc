/**
 * File: cdc_pkt.sv
 * Description: It encapsulates a pkt into different clk domains
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
module cdc_pkt import ravenoc_pkg::*; #(
  parameter CDC_STEPS = 2
)(
  input                     clk_axi,
  input                     clk_noc,

  input                     arst_axi,
  input                     arst_noc,
  // AXI Slave (pkt gen) -> NoC
  router_if.recv_flit       flit_req_axi_axi,
  router_if.send_flit       flit_req_axi_noc,
  // AXI Slave (pkt_gen) <- NoC
  router_if.recv_flit       flit_req_noc_noc,
  router_if.send_flit       flit_req_noc_axi
);
  localparam WIDTH_AXI_TO_NOC = $bits(s_flit_req_t);

  logic [WIDTH_AXI_TO_NOC-1:0]  input_afifo_axi_noc;
  logic [WIDTH_AXI_TO_NOC-1:0]  output_afifo_axi_noc;
  logic                         wr_full_axi_noc;
  logic                         rd_empty_axi_noc;
  logic                         rd_enable_axi_noc;

  localparam WIDTH_NOC_TO_AXI = $bits(s_flit_req_t);

  logic [WIDTH_NOC_TO_AXI-1:0]  input_afifo_noc_axi;
  logic [WIDTH_NOC_TO_AXI-1:0]  output_afifo_noc_axi;
  logic                         wr_full_noc_axi;
  logic                         rd_empty_noc_axi;
  logic                         rd_enable_noc_axi;

  //------------------------------------
  //
  // AXI to NoC - CDC AFIFO Sync
  // Let's bring pkt requests to NoC domain,
  // Now it can go to the NoC bc it's coming
  // from the pkt generator combo logic
  //
  //------------------------------------
  always_comb begin : axi_to_noc_flow
    input_afifo_axi_noc = WIDTH_AXI_TO_NOC'(flit_req_axi_axi.req);
    flit_req_axi_axi.resp.ready = ~wr_full_axi_noc;
    flit_req_axi_noc.req = rd_empty_axi_noc ? s_flit_req_t'('0) : output_afifo_axi_noc;
    rd_enable_axi_noc = flit_req_axi_noc.resp.ready && flit_req_axi_noc.req.valid;
  end

  async_gp_fifo #(
    .SLOTS    (CDC_STEPS),
    .WIDTH    (WIDTH_AXI_TO_NOC)
  ) u_afifo_axi_to_noc (
    // AXI
    .wr_clk   (clk_axi),
    .wr_arst  (arst_axi),
    .wr_en    (flit_req_axi_axi.req.valid),
    .wr_data  (input_afifo_axi_noc),
    .wr_full  (wr_full_axi_noc),
    // NoC
    .rd_clk   (clk_noc),
    .rd_arst  (arst_noc),
    .rd_en    (rd_enable_axi_noc),
    .rd_data  (output_afifo_axi_noc),
    .rd_empty (rd_empty_axi_noc)
  );

  //------------------------------------
  //
  // NoC to AXI - CDC AFIFO Sync
  // Let's bring pkt requests to AXI domain,
  // Now it can go to the pkt gen bc it's coming
  // from the NoC output module
  //
  //------------------------------------
  always_comb begin : noc_to_noc_flow
    input_afifo_noc_axi = WIDTH_NOC_TO_AXI'(flit_req_noc_noc.req);
    flit_req_noc_noc.resp.ready = ~wr_full_noc_axi;
    flit_req_noc_axi.req = rd_empty_noc_axi ? s_flit_req_t'('0) : output_afifo_noc_axi;
    rd_enable_noc_axi = flit_req_noc_axi.resp.ready && flit_req_noc_axi.req.valid;
  end

  async_gp_fifo #(
    .SLOTS    (CDC_STEPS),
    .WIDTH    (WIDTH_NOC_TO_AXI)
  ) u_afifo_noc_to_axi (
    // NoC
    .wr_clk   (clk_noc),
    .wr_arst  (arst_noc),
    .wr_en    (flit_req_noc_noc.req.valid),
    .wr_data  (input_afifo_noc_axi),
    .wr_full  (wr_full_noc_axi),
    // AXI
    .rd_clk   (clk_axi),
    .rd_arst  (arst_axi),
    .rd_en    (rd_enable_noc_axi),
    .rd_data  (output_afifo_noc_axi),
    .rd_empty (rd_empty_noc_axi)
  );
endmodule
