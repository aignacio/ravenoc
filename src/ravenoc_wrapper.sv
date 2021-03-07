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
  // AXI Interface - MOSI
  // Write Address channel
  input  logic                                   NOC_AWID,
  input  axi_addr_t                              NOC_AWADDR,
  input  logic        [`AXI_ALEN_WIDTH-1:0]      NOC_AWLEN,
  input  asize_t                                 NOC_AWSIZE,
  input  aburst_t                                NOC_AWBURST,
  input  logic        [1:0]                      NOC_AWLOCK,
  input  logic        [3:0]                      NOC_AWCACHE,
  input  logic        [2:0]                      NOC_AWPROT,
  input  logic        [3:0]                      NOC_AWQOS,
  input  logic        [3:0]                      NOC_AWREGION,
  input  logic        [`AXI_USER_REQ_WIDTH-1:0]  NOC_AWUSER,
  input  logic                                   NOC_AWVALID,
  // Write Data channel
  input  logic                                   NOC_WID,
  input  logic        [`AXI_DATA_WIDTH-1:0]      NOC_WDATA,
  input  logic        [(`AXI_DATA_WIDTH/8)-1:0]  NOC_WSTRB,
  input  logic                                   NOC_WLAST,
  input  logic        [`AXI_USER_DATA_WIDTH-1:0] NOC_WUSER,
  input  logic                                   NOC_WVALID,
  // Write Response channel
  input  logic                                   NOC_BREADY,
  // Read Address channel
  input  logic                                   NOC_ARID,
  input  axi_addr_t                              NOC_ARADDR,
  input  logic        [`AXI_ALEN_WIDTH-1:0]      NOC_ARLEN,
  input  asize_t                                 NOC_ARSIZE,
  input  aburst_t                                NOC_ARBURST,
  input  logic        [1:0]                      NOC_ARLOCK,
  input  logic        [3:0]                      NOC_ARCACHE,
  input  logic        [2:0]                      NOC_ARPROT,
  input  logic        [3:0]                      NOC_ARQOS,
  input  logic        [3:0]                      NOC_ARREGION,
  input  logic        [`AXI_USER_REQ_WIDTH-1:0]  NOC_ARUSER,
  input  logic                                   NOC_ARVALID,
  // Read Data channel
  input  logic                                   NOC_RREADY,

  // AXI Interface - MISO
  // Write Addr channel
  output logic                                   NOC_AWREADY,
  // Write Data channel
  output logic                                   NOC_WREADY,
  // Write Response channel
  output logic                                   NOC_BID,
  output aerror_t                                NOC_BRESP,
  output logic        [`AXI_USER_RESP_WIDTH-1:0] NOC_BUSER,
  output logic                                   NOC_BVALID,
  // Read addr channel
  output logic                                   NOC_ARREADY,
  // Read data channel
  output logic                                   NOC_RID,
  output logic        [`AXI_DATA_WIDTH-1:0]      NOC_RDATA,
  output aerror_t                                NOC_RRESP,
  output logic                                   NOC_RLAST,
  output logic        [`AXI_USER_REQ_WIDTH-1:0]  NOC_RUSER,
  output logic                                   NOC_RVALID
);
  s_axi_mosi_t [NOC_SIZE-1:0] axi_mosi;
  s_axi_miso_t [NOC_SIZE-1:0] axi_miso;
  logic        [$clog2(NOC_SIZE)-1:0] test;

  always begin
    NOC_AWREADY  = '0;
    NOC_WREADY   = '0;
    NOC_BID      = '0;
    NOC_BRESP    = '0;
    NOC_BUSER    = '0;
    NOC_BVALID   = '0;
    NOC_ARREADY  = '0;
    NOC_RID      = '0;
    NOC_RDATA    = '0;
    NOC_RRESP    = '0;
    NOC_RLAST    = '0;
    NOC_RUSER    = '0;
    NOC_RVALID   = '0;

    test = '0;
    // verilator lint_off WIDTH
    for (int i=0;i<NOC_SIZE;i++) begin
      if (axi_sel == i)  begin
        test = i[$clog2(NOC_SIZE)-1:0];
        axi_mosi[i].awid     = NOC_AWID;
        axi_mosi[i].awaddr   = NOC_AWADDR;
        axi_mosi[i].awlen    = NOC_AWLEN;
        axi_mosi[i].awsize   = NOC_AWSIZE;
        axi_mosi[i].awburst  = NOC_AWBURST;
        axi_mosi[i].awlock   = NOC_AWLOCK;
        axi_mosi[i].awcache  = NOC_AWCACHE;
        axi_mosi[i].awprot   = NOC_AWPROT;
        axi_mosi[i].awqos    = NOC_AWQOS;
        axi_mosi[i].awregion = NOC_AWREGION;
        axi_mosi[i].awuser   = NOC_AWUSER;
        axi_mosi[i].awvalid  = NOC_AWVALID;
        axi_mosi[i].wid      = NOC_WID;
        axi_mosi[i].wdata    = NOC_WDATA;
        axi_mosi[i].wstrb    = NOC_WSTRB;
        axi_mosi[i].wlast    = NOC_WLAST;
        axi_mosi[i].wuser    = NOC_WUSER;
        axi_mosi[i].wvalid   = NOC_WVALID;
        axi_mosi[i].bready   = NOC_BREADY;
        axi_mosi[i].arid     = NOC_ARID;
        axi_mosi[i].araddr   = NOC_ARADDR;
        axi_mosi[i].arlen    = NOC_ARLEN;
        axi_mosi[i].arsize   = NOC_ARSIZE;
        axi_mosi[i].arburst  = NOC_ARBURST;
        axi_mosi[i].arlock   = NOC_ARLOCK;
        axi_mosi[i].arcache  = NOC_ARCACHE;
        axi_mosi[i].arprot   = NOC_ARPROT;
        axi_mosi[i].arqos    = NOC_ARQOS;
        axi_mosi[i].arregion = NOC_ARREGION;
        axi_mosi[i].aruser   = NOC_ARUSER;
        axi_mosi[i].arvalid  = NOC_ARVALID;
        axi_mosi[i].rready   = NOC_RREADY;

        NOC_AWREADY  = axi_miso[i].awready;
        NOC_WREADY   = axi_miso[i].wready;
        NOC_BID      = axi_miso[i].bid;
        NOC_BRESP    = axi_miso[i].bresp;
        NOC_BUSER    = axi_miso[i].buser;
        NOC_BVALID   = axi_miso[i].bvalid;
        NOC_ARREADY  = axi_miso[i].arready;
        NOC_RID      = axi_miso[i].rid;
        NOC_RDATA    = axi_miso[i].rdata;
        NOC_RRESP    = axi_miso[i].rresp;
        NOC_RLAST    = axi_miso[i].rlast;
        NOC_RUSER    = axi_miso[i].ruser;
        NOC_RVALID   = axi_miso[i].rvalid;
      end
    end
  end
  // verilator lint_on WIDTH

  ravenoc u_ravenoc (
    .clk_axi        (clk_axi),
    .clk_noc        (clk_noc),
    .arst_axi       (arst_axi),
    .arst_noc       (arst_noc),
    .axi_mosi_if    (axi_mosi),
    .axi_miso_if    (axi_miso)
  );
endmodule
