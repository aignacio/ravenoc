/**
 * File: RaveNoC wrapper module
 * Description: It only exists because it facilitates intg. with cocotb
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
module ravenoc_wrapper import ravenoc_pkg::*; #(
  parameter bit DEBUG = 0
)(
  input                                          clk_axi,
  input                                          clk_noc,
  input                                          arst_axi,
  input                                          arst_noc,
  // AXI mux I/F
  input                                          act_in,
  input               [$clog2(NoCSize)-1:0]     axi_sel_in,
  input                                          act_out,
  input               [$clog2(NoCSize)-1:0]     axi_sel_out,
  // Used to test when clk_axi == clk_noc to bypass CDC
  input                                          bypass_cdc,
  // AXI in I/F
  // AXI Interface - MOSI
  // Write Address channel
  input  logic                                   noc_in_awid,
  input  axi_addr_t                              noc_in_awaddr,
  input  logic        [`AXI_ALEN_WIDTH-1:0]      noc_in_awlen,
  input  asize_t                                 noc_in_awsize,
  input  aburst_t                                noc_in_awburst,
  input  logic                                   noc_in_awlock,
  input  logic        [3:0]                      noc_in_awcache,
  input  logic        [2:0]                      noc_in_awprot,
  input  logic        [3:0]                      noc_in_awqos,
  input  logic        [3:0]                      noc_in_awregion,
  input  logic        [`AXI_USER_REQ_WIDTH-1:0]  noc_in_awuser,
  input  logic                                   noc_in_awvalid,
  // Write Data channel
  //input  logic                                   noc_in_wid,
  input  logic        [`AXI_DATA_WIDTH-1:0]      noc_in_wdata,
  input  logic        [(`AXI_DATA_WIDTH/8)-1:0]  noc_in_wstrb,
  input  logic                                   noc_in_wlast,
  input  logic        [`AXI_USER_DATA_WIDTH-1:0] noc_in_wuser,
  input  logic                                   noc_in_wvalid,
  // Write Response channel
  input  logic                                   noc_in_bready,
  // Read Address channel
  input  logic                                   noc_in_arid,
  input  axi_addr_t                              noc_in_araddr,
  input  logic        [`AXI_ALEN_WIDTH-1:0]      noc_in_arlen,
  input  asize_t                                 noc_in_arsize,
  input  aburst_t                                noc_in_arburst,
  input  logic                                   noc_in_arlock,
  input  logic        [3:0]                      noc_in_arcache,
  input  logic        [2:0]                      noc_in_arprot,
  input  logic        [3:0]                      noc_in_arqos,
  input  logic        [3:0]                      noc_in_arregion,
  input  logic        [`AXI_USER_REQ_WIDTH-1:0]  noc_in_aruser,
  input  logic                                   noc_in_arvalid,
  // Read Data channel
  input  logic                                   noc_in_rready,

  // AXI Interface - MISO
  // Write Addr channel
  output logic                                   noc_in_awready,
  // Write Data channel
  output logic                                   noc_in_wready,
  // Write Response channel
  output logic                                   noc_in_bid,
  output aerror_t                                noc_in_bresp,
  output logic        [`AXI_USER_RESP_WIDTH-1:0] noc_in_buser,
  output logic                                   noc_in_bvalid,
  // Read addr channel
  output logic                                   noc_in_arready,
  // Read data channel
  output logic                                   noc_in_rid,
  output logic        [`AXI_DATA_WIDTH-1:0]      noc_in_rdata,
  output aerror_t                                noc_in_rresp,
  output logic                                   noc_in_rlast,
  output logic        [`AXI_USER_REQ_WIDTH-1:0]  noc_in_ruser,
  output logic                                   noc_in_rvalid,

  // AXI out I/F
  // AXI Interface - MOSI
  // Write Address channel
  input  logic                                   noc_out_awid,
  input  axi_addr_t                              noc_out_awaddr,
  input  logic        [`AXI_ALEN_WIDTH-1:0]      noc_out_awlen,
  input  asize_t                                 noc_out_awsize,
  input  aburst_t                                noc_out_awburst,
  input  logic                                   noc_out_awlock,
  input  logic        [3:0]                      noc_out_awcache,
  input  logic        [2:0]                      noc_out_awprot,
  input  logic        [3:0]                      noc_out_awqos,
  input  logic        [3:0]                      noc_out_awregion,
  input  logic        [`AXI_USER_REQ_WIDTH-1:0]  noc_out_awuser,
  input  logic                                   noc_out_awvalid,
  // Write Data channel
  //input  logic                                   noc_out_wid,
  input  logic        [`AXI_DATA_WIDTH-1:0]      noc_out_wdata,
  input  logic        [(`AXI_DATA_WIDTH/8)-1:0]  noc_out_wstrb,
  input  logic                                   noc_out_wlast,
  input  logic        [`AXI_USER_DATA_WIDTH-1:0] noc_out_wuser,
  input  logic                                   noc_out_wvalid,
  // Write Response channel
  input  logic                                   noc_out_bready,
  // Read Address channel
  input  logic                                   noc_out_arid,
  input  axi_addr_t                              noc_out_araddr,
  input  logic        [`AXI_ALEN_WIDTH-1:0]      noc_out_arlen,
  input  asize_t                                 noc_out_arsize,
  input  aburst_t                                noc_out_arburst,
  input  logic                                   noc_out_arlock,
  input  logic        [3:0]                      noc_out_arcache,
  input  logic        [2:0]                      noc_out_arprot,
  input  logic        [3:0]                      noc_out_arqos,
  input  logic        [3:0]                      noc_out_arregion,
  input  logic        [`AXI_USER_REQ_WIDTH-1:0]  noc_out_aruser,
  input  logic                                   noc_out_arvalid,
  // Read Data channel
  input  logic                                   noc_out_rready,
  // AXI Interface - MISO
  // Write Addr channel
  output logic                                   noc_out_awready,
  // Write Data channel
  output logic                                   noc_out_wready,
  // Write Response channel
  output logic                                   noc_out_bid,
  output aerror_t                                noc_out_bresp,
  output logic        [`AXI_USER_RESP_WIDTH-1:0] noc_out_buser,
  output logic                                   noc_out_bvalid,
  // Read addr channel
  output logic                                   noc_out_arready,
  // Read data channel
  output logic                                   noc_out_rid,
  output logic        [`AXI_DATA_WIDTH-1:0]      noc_out_rdata,
  output aerror_t                                noc_out_rresp,
  output logic                                   noc_out_rlast,
  output logic        [`AXI_USER_REQ_WIDTH-1:0]  noc_out_ruser,
  output logic                                   noc_out_rvalid,
  // IRQs
  output logic        [NumVirtChn*NoCSize-1:0]   irqs_out
);
  s_axi_mosi_t [NoCSize-1:0] axi_mosi;
  s_axi_miso_t [NoCSize-1:0] axi_miso;
  s_irq_ni_t   [NoCSize-1:0] irqs;
  logic        [NoCSize-1:0] bypass_cdc_vec;
  logic        [NoCSize-1:0] clk_axi_array;
  logic        [NoCSize-1:0] arst_axi_array;

  always begin
    for (int i=0;i<NoCSize;i++) begin
      bypass_cdc_vec[i] = bypass_cdc;
      clk_axi_array[i] = clk_axi;
      arst_axi_array[i] = arst_axi;
    end

    noc_in_awready  = '0;
    noc_in_wready   = '0;
    noc_in_bid      = '0;
    noc_in_bresp    = '0;
    noc_in_buser    = '0;
    noc_in_bvalid   = '0;
    noc_in_arready  = '0;
    noc_in_rid      = '0;
    noc_in_rdata    = '0;
    noc_in_rresp    = '0;
    noc_in_rlast    = '0;
    noc_in_ruser    = '0;
    noc_in_rvalid   = '0;

    noc_out_awready  = '0;
    noc_out_wready   = '0;
    noc_out_bid      = '0;
    noc_out_bresp    = '0;
    noc_out_buser    = '0;
    noc_out_bvalid   = '0;
    noc_out_arready  = '0;
    noc_out_rid      = '0;
    noc_out_rdata    = '0;
    noc_out_rresp    = '0;
    noc_out_rlast    = '0;
    noc_out_ruser    = '0;
    noc_out_rvalid   = '0;

    axi_mosi = '0;
    // verilator lint_off WIDTH
    for (int i=0;i<NoCSize;i++) begin
      for (int vc=0;vc<NumVirtChn;vc++) begin
        irqs_out[i*NumVirtChn+vc] = irqs[i].irq_vcs[vc];
      end

      if (axi_sel_out == i && act_out)  begin
        axi_mosi[i].awid     = noc_out_awid;
        axi_mosi[i].awaddr   = noc_out_awaddr;
        axi_mosi[i].awlen    = noc_out_awlen;
        axi_mosi[i].awsize   = noc_out_awsize;
        axi_mosi[i].awburst  = noc_out_awburst;
        axi_mosi[i].awlock   = noc_out_awlock;
        axi_mosi[i].awcache  = noc_out_awcache;
        axi_mosi[i].awprot   = noc_out_awprot;
        axi_mosi[i].awqos    = noc_out_awqos;
        axi_mosi[i].awregion = noc_out_awregion;
        axi_mosi[i].awuser   = noc_out_awuser;
        axi_mosi[i].awvalid  = noc_out_awvalid;
        //axi_mosi[i].wid      = noc_out_wid;
        axi_mosi[i].wdata    = noc_out_wdata;
        axi_mosi[i].wstrb    = noc_out_wstrb;
        axi_mosi[i].wlast    = noc_out_wlast;
        axi_mosi[i].wuser    = noc_out_wuser;
        axi_mosi[i].wvalid   = noc_out_wvalid;
        axi_mosi[i].bready   = noc_out_bready;
        axi_mosi[i].arid     = noc_out_arid;
        axi_mosi[i].araddr   = noc_out_araddr;
        axi_mosi[i].arlen    = noc_out_arlen;
        axi_mosi[i].arsize   = noc_out_arsize;
        axi_mosi[i].arburst  = noc_out_arburst;
        axi_mosi[i].arlock   = noc_out_arlock;
        axi_mosi[i].arcache  = noc_out_arcache;
        axi_mosi[i].arprot   = noc_out_arprot;
        axi_mosi[i].arqos    = noc_out_arqos;
        axi_mosi[i].arregion = noc_out_arregion;
        axi_mosi[i].aruser   = noc_out_aruser;
        axi_mosi[i].arvalid  = noc_out_arvalid;
        axi_mosi[i].rready   = noc_out_rready;

        noc_out_awready  = axi_miso[i].awready;
        noc_out_wready   = axi_miso[i].wready;
        noc_out_bid      = axi_miso[i].bid;
        noc_out_bresp    = axi_miso[i].bresp;
        noc_out_buser    = axi_miso[i].buser;
        noc_out_bvalid   = axi_miso[i].bvalid;
        noc_out_arready  = axi_miso[i].arready;
        noc_out_rid      = axi_miso[i].rid;
        noc_out_rdata    = axi_miso[i].rdata;
        noc_out_rresp    = axi_miso[i].rresp;
        noc_out_rlast    = axi_miso[i].rlast;
        noc_out_ruser    = axi_miso[i].ruser;
        noc_out_rvalid   = axi_miso[i].rvalid;
      end
      if (axi_sel_in == i && act_in)  begin
        axi_mosi[i].awid     = noc_in_awid;
        axi_mosi[i].awaddr   = noc_in_awaddr;
        axi_mosi[i].awlen    = noc_in_awlen;
        axi_mosi[i].awsize   = noc_in_awsize;
        axi_mosi[i].awburst  = noc_in_awburst;
        axi_mosi[i].awlock   = noc_in_awlock;
        axi_mosi[i].awcache  = noc_in_awcache;
        axi_mosi[i].awprot   = noc_in_awprot;
        axi_mosi[i].awqos    = noc_in_awqos;
        axi_mosi[i].awregion = noc_in_awregion;
        axi_mosi[i].awuser   = noc_in_awuser;
        axi_mosi[i].awvalid  = noc_in_awvalid;
        //axi_mosi[i].wid      = noc_in_wid;
        axi_mosi[i].wdata    = noc_in_wdata;
        axi_mosi[i].wstrb    = noc_in_wstrb;
        axi_mosi[i].wlast    = noc_in_wlast;
        axi_mosi[i].wuser    = noc_in_wuser;
        axi_mosi[i].wvalid   = noc_in_wvalid;
        axi_mosi[i].bready   = noc_in_bready;
        axi_mosi[i].arid     = noc_in_arid;
        axi_mosi[i].araddr   = noc_in_araddr;
        axi_mosi[i].arlen    = noc_in_arlen;
        axi_mosi[i].arsize   = noc_in_arsize;
        axi_mosi[i].arburst  = noc_in_arburst;
        axi_mosi[i].arlock   = noc_in_arlock;
        axi_mosi[i].arcache  = noc_in_arcache;
        axi_mosi[i].arprot   = noc_in_arprot;
        axi_mosi[i].arqos    = noc_in_arqos;
        axi_mosi[i].arregion = noc_in_arregion;
        axi_mosi[i].aruser   = noc_in_aruser;
        axi_mosi[i].arvalid  = noc_in_arvalid;
        axi_mosi[i].rready   = noc_in_rready;

        noc_in_awready  = axi_miso[i].awready;
        noc_in_wready   = axi_miso[i].wready;
        noc_in_bid      = axi_miso[i].bid;
        noc_in_bresp    = axi_miso[i].bresp;
        noc_in_buser    = axi_miso[i].buser;
        noc_in_bvalid   = axi_miso[i].bvalid;
        noc_in_arready  = axi_miso[i].arready;
        noc_in_rid      = axi_miso[i].rid;
        noc_in_rdata    = axi_miso[i].rdata;
        noc_in_rresp    = axi_miso[i].rresp;
        noc_in_rlast    = axi_miso[i].rlast;
        noc_in_ruser    = axi_miso[i].ruser;
        noc_in_rvalid   = axi_miso[i].rvalid;
      end


    end
  end
  // verilator lint_on WIDTH

  ravenoc #(
    .AXI_CDC_REQ('1)
  ) u_ravenoc (
    .clk_axi        (clk_axi_array),
    .clk_noc        (clk_noc),
    .arst_axi       (arst_axi_array),
    .arst_noc       (arst_noc),
    .axi_mosi_if    (axi_mosi),
    .axi_miso_if    (axi_miso),
    .irqs           (irqs),
    .bypass_cdc     (bypass_cdc_vec)
  );

  illegal_input_axi_muxes : assert property (
    @(posedge clk_axi) disable iff (arst_axi)
    (act_in && act_out) |-> (axi_sel_in != axi_sel_out)
  ) else $error("Illegal mux on the AXI!");

endmodule
