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
  parameter int CDC_TAPS = 2
)(
  input                     clk_axi,
  input                     clk_noc,

  input                     arst_axi,
  input                     arst_noc,
  input                     bypass_cdc_i,
  // AXI Slave (pkt gen) -> NoC
  router_if.recv_flit       flit_req_axi_axi,
  router_if.send_flit       flit_req_axi_noc,
  // AXI Slave (pkt_gen) <- NoC
  router_if.recv_flit       flit_req_noc_noc,
  router_if.send_flit       flit_req_noc_axi
);
  localparam int WidthAxiToNoC = $bits(s_flit_req_t);

  logic [WidthAxiToNoC-1:0]  input_afifo_axi_noc;
  logic [WidthAxiToNoC-1:0]  output_afifo_axi_noc;
  logic                      wr_full_axi_noc;
  logic                      rd_empty_axi_noc;
  logic                      rd_enable_axi_noc;

  localparam int WidthNoCToAxi = $bits(s_flit_req_t);

  logic [WidthNoCToAxi-1:0]  input_afifo_noc_axi;
  logic [WidthNoCToAxi-1:0]  output_afifo_noc_axi;
  logic                      wr_full_noc_axi;
  logic                      rd_empty_noc_axi;
  logic                      rd_enable_noc_axi;

  //------------------------------------
  //
  // AXI to NoC - CDC AFIFO Sync
  // Let's bring pkt requests to NoC domain,
  // Now it can go to the NoC bc it's coming
  // from the pkt generator combo logic
  //
  //------------------------------------
  always_comb begin : axi_to_noc_flow
    if (bypass_cdc_i == 0) begin
      input_afifo_axi_noc = WidthAxiToNoC'(flit_req_axi_axi.req);
      flit_req_axi_axi.resp.ready = ~wr_full_axi_noc;
      flit_req_axi_noc.req = rd_empty_axi_noc ? s_flit_req_t'('0) : output_afifo_axi_noc;
      rd_enable_axi_noc = flit_req_axi_noc.resp.ready && flit_req_axi_noc.req.valid;
    end
    else begin
      input_afifo_axi_noc = '0;
      rd_enable_axi_noc = '0;

      flit_req_axi_noc.req = flit_req_axi_axi.req;
      flit_req_axi_axi.resp = flit_req_axi_noc.resp;
    end
  end

  async_gp_fifo#(
    .SLOTS    (CDC_TAPS),
    .WIDTH    (WidthAxiToNoC)
  ) u_afifo_axi_to_noc (
    // AXI
    .clk_wr     (clk_axi),
    .arst_wr    (arst_axi),
    .wr_en_i    (flit_req_axi_axi.req.valid),
    .wr_data_i  (input_afifo_axi_noc),
    .wr_full_o  (wr_full_axi_noc),
    // NoC
    .clk_rd     (clk_noc),
    .arst_rd    (arst_noc),
    .rd_en_i    (rd_enable_axi_noc),
    .rd_data_o  (output_afifo_axi_noc),
    .rd_empty_o (rd_empty_axi_noc)
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
    if (bypass_cdc_i == 0) begin
      input_afifo_noc_axi = WidthNoCToAxi'(flit_req_noc_noc.req);
      flit_req_noc_noc.resp.ready = ~wr_full_noc_axi;
      flit_req_noc_axi.req = rd_empty_noc_axi ? s_flit_req_t'('0) : output_afifo_noc_axi;
      rd_enable_noc_axi = flit_req_noc_axi.resp.ready && flit_req_noc_axi.req.valid;
    end
    else begin
      input_afifo_noc_axi = '0;
      rd_enable_noc_axi = '0;

      flit_req_noc_axi.req = flit_req_noc_noc.req;
      flit_req_noc_noc.resp = flit_req_noc_axi.resp;
    end
  end

  async_gp_fifo#(
    .SLOTS    (CDC_TAPS),
    .WIDTH    (WidthNoCToAxi)
  ) u_afifo_noc_to_axi (
    // NoC
    .clk_wr     (clk_noc),
    .arst_wr    (arst_noc),
    .wr_en_i    (flit_req_noc_noc.req.valid),
    .wr_data_i  (input_afifo_noc_axi),
    .wr_full_o  (wr_full_noc_axi),
    // AXI
    .clk_rd     (clk_axi),
    .arst_rd    (arst_axi),
    .rd_en_i    (rd_enable_noc_axi),
    .rd_data_o  (output_afifo_noc_axi),
    .rd_empty_o (rd_empty_noc_axi)
  );
endmodule
