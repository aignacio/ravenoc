/**
 * File: RaveNoC wrapper module
 * Description: It only exists because it facilitates intg. with cocotb
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
module ravenoc_wrapper import ravenoc_pkg::*; #(
  parameter DEBUG = 0
)(
  input                                          clk_axi,
  input                                          clk_noc,
  input                                          arst_axi,
  input                                          arst_noc,
  // AXI mux I/F
  input               [$clog2(NOC_SIZE)-1:0]     axi_sel,
  // Used to test when clk_axi == clk_noc to bypass CDC
  input                                          bypass_cdc,
  // AXI Interface - MOSI
  // Write Address channel
  input  logic                                   noc_awid,
  input  axi_addr_t                              noc_awaddr,
  input  logic        [`AXI_ALEN_WIDTH-1:0]      noc_awlen,
  input  asize_t                                 noc_awsize,
  input  aburst_t                                noc_awburst,
  input  logic                                   noc_awlock,
  input  logic        [3:0]                      noc_awcache,
  input  logic        [2:0]                      noc_awprot,
  input  logic        [3:0]                      noc_awqos,
  input  logic        [3:0]                      noc_awregion,
  input  logic        [`AXI_USER_REQ_WIDTH-1:0]  noc_awuser,
  input  logic                                   noc_awvalid,
  // Write Data channel
  input  logic                                   noc_wid,
  input  logic        [`AXI_DATA_WIDTH-1:0]      noc_wdata,
  input  logic        [(`AXI_DATA_WIDTH/8)-1:0]  noc_wstrb,
  input  logic                                   noc_wlast,
  input  logic        [`AXI_USER_DATA_WIDTH-1:0] noc_wuser,
  input  logic                                   noc_wvalid,
  // Write Response channel
  input  logic                                   noc_bready,
  // Read Address channel
  input  logic                                   noc_arid,
  input  axi_addr_t                              noc_araddr,
  input  logic        [`AXI_ALEN_WIDTH-1:0]      noc_arlen,
  input  asize_t                                 noc_arsize,
  input  aburst_t                                noc_arburst,
  input  logic                                   noc_arlock,
  input  logic        [3:0]                      noc_arcache,
  input  logic        [2:0]                      noc_arprot,
  input  logic        [3:0]                      noc_arqos,
  input  logic        [3:0]                      noc_arregion,
  input  logic        [`AXI_USER_REQ_WIDTH-1:0]  noc_aruser,
  input  logic                                   noc_arvalid,
  // Read Data channel
  input  logic                                   noc_rready,

  // AXI Interface - MISO
  // Write Addr channel
  output logic                                   noc_awready,
  // Write Data channel
  output logic                                   noc_wready,
  // Write Response channel
  output logic                                   noc_bid,
  output aerror_t                                noc_bresp,
  output logic        [`AXI_USER_RESP_WIDTH-1:0] noc_buser,
  output logic                                   noc_bvalid,
  // Read addr channel
  output logic                                   noc_arready,
  // Read data channel
  output logic                                   noc_rid,
  output logic        [`AXI_DATA_WIDTH-1:0]      noc_rdata,
  output aerror_t                                noc_rresp,
  output logic                                   noc_rlast,
  output logic        [`AXI_USER_REQ_WIDTH-1:0]  noc_ruser,
  output logic                                   noc_rvalid,
  // IRQs
  output logic        [NOC_SIZE-1:0]             irqs_out
);
  s_axi_mosi_t [NOC_SIZE-1:0] axi_mosi;
  s_axi_miso_t [NOC_SIZE-1:0] axi_miso;
  s_irq_ni_t   [NOC_SIZE-1:0] irqs;

  always begin
    noc_awready  = '0;
    noc_wready   = '0;
    noc_bid      = '0;
    noc_bresp    = '0;
    noc_buser    = '0;
    noc_bvalid   = '0;
    noc_arready  = '0;
    noc_rid      = '0;
    noc_rdata    = '0;
    noc_rresp    = '0;
    noc_rlast    = '0;
    noc_ruser    = '0;
    noc_rvalid   = '0;

    // verilator lint_off WIDTH
    for (int i=0;i<NOC_SIZE;i++) begin
      irqs_out[i] = (irqs[i].irq_vcs != 'h0);
      if (axi_sel == i)  begin
        axi_mosi[i].awid     = noc_awid;
        axi_mosi[i].awaddr   = noc_awaddr;
        axi_mosi[i].awlen    = noc_awlen;
        axi_mosi[i].awsize   = noc_awsize;
        axi_mosi[i].awburst  = noc_awburst;
        axi_mosi[i].awlock   = noc_awlock;
        axi_mosi[i].awcache  = noc_awcache;
        axi_mosi[i].awprot   = noc_awprot;
        axi_mosi[i].awqos    = noc_awqos;
        axi_mosi[i].awregion = noc_awregion;
        axi_mosi[i].awuser   = noc_awuser;
        axi_mosi[i].awvalid  = noc_awvalid;
        axi_mosi[i].wid      = noc_wid;
        axi_mosi[i].wdata    = noc_wdata;
        axi_mosi[i].wstrb    = noc_wstrb;
        axi_mosi[i].wlast    = noc_wlast;
        axi_mosi[i].wuser    = noc_wuser;
        axi_mosi[i].wvalid   = noc_wvalid;
        axi_mosi[i].bready   = noc_bready;
        axi_mosi[i].arid     = noc_arid;
        axi_mosi[i].araddr   = noc_araddr;
        axi_mosi[i].arlen    = noc_arlen;
        axi_mosi[i].arsize   = noc_arsize;
        axi_mosi[i].arburst  = noc_arburst;
        axi_mosi[i].arlock   = noc_arlock;
        axi_mosi[i].arcache  = noc_arcache;
        axi_mosi[i].arprot   = noc_arprot;
        axi_mosi[i].arqos    = noc_arqos;
        axi_mosi[i].arregion = noc_arregion;
        axi_mosi[i].aruser   = noc_aruser;
        axi_mosi[i].arvalid  = noc_arvalid;
        axi_mosi[i].rready   = noc_rready;

        noc_awready  = axi_miso[i].awready;
        noc_wready   = axi_miso[i].wready;
        noc_bid      = axi_miso[i].bid;
        noc_bresp    = axi_miso[i].bresp;
        noc_buser    = axi_miso[i].buser;
        noc_bvalid   = axi_miso[i].bvalid;
        noc_arready  = axi_miso[i].arready;
        noc_rid      = axi_miso[i].rid;
        noc_rdata    = axi_miso[i].rdata;
        noc_rresp    = axi_miso[i].rresp;
        noc_rlast    = axi_miso[i].rlast;
        noc_ruser    = axi_miso[i].ruser;
        noc_rvalid   = axi_miso[i].rvalid;
      end
    end
  end
  // verilator lint_on WIDTH

  ravenoc #(
    .AXI_CDC_REQ('1)
  ) u_ravenoc (
    .clk_axi        (clk_axi),
    .clk_noc        (clk_noc),
    .arst_axi       (arst_axi),
    .arst_noc       (arst_noc),
    .axi_mosi_if    (axi_mosi),
    .axi_miso_if    (axi_miso),
    .irqs           (irqs),
    .bypass_cdc     (bypass_cdc)
  );
endmodule
