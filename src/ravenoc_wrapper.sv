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
  // AXI Interface - MOSI
  // Write Address channel
  input  logic                                   NOC_AWID      [NOC_SIZE-1:0],
  input  axi_addr_t                              NOC_AWADDR    [NOC_SIZE-1:0],
  input  logic        [`AXI_ALEN_WIDTH-1:0]      NOC_AWLEN     [NOC_SIZE-1:0],
  input  asize_t                                 NOC_AWSIZE    [NOC_SIZE-1:0],
  input  aburst_t                                NOC_AWBURST   [NOC_SIZE-1:0],
  input  logic        [1:0]                      NOC_AWLOCK    [NOC_SIZE-1:0],
  input  logic        [3:0]                      NOC_AWCACHE   [NOC_SIZE-1:0],
  input  logic        [2:0]                      NOC_AWPROT    [NOC_SIZE-1:0],
  input  logic        [3:0]                      NOC_AWQOS     [NOC_SIZE-1:0],
  input  logic        [3:0]                      NOC_AWREGION  [NOC_SIZE-1:0],
  input  logic        [`AXI_USER_REQ_WIDTH-1:0]  NOC_AWUSER    [NOC_SIZE-1:0],
  input  logic                                   NOC_AWVALID   [NOC_SIZE-1:0],
  // Write Data channel
  input  logic                                   NOC_WID       [NOC_SIZE-1:0],
  input  logic        [`AXI_DATA_WIDTH-1:0]      NOC_WDATA     [NOC_SIZE-1:0],
  input  logic        [(`AXI_DATA_WIDTH/8)-1:0]  NOC_WSTRB     [NOC_SIZE-1:0],
  input  logic                                   NOC_WLAST     [NOC_SIZE-1:0],
  input  logic        [`AXI_USER_DATA_WIDTH-1:0] NOC_WUSER     [NOC_SIZE-1:0],
  input  logic                                   NOC_WVALID    [NOC_SIZE-1:0],
  // Write Response channel
  input  logic                                   NOC_BREADY    [NOC_SIZE-1:0],
  // Read Address channel
  input  logic                                   NOC_ARID      [NOC_SIZE-1:0],
  input  axi_addr_t                              NOC_ARADDR    [NOC_SIZE-1:0],
  input  logic        [`AXI_ALEN_WIDTH-1:0]      NOC_ARLEN     [NOC_SIZE-1:0],
  input  asize_t                                 NOC_ARSIZE    [NOC_SIZE-1:0],
  input  aburst_t                                NOC_ARBURST   [NOC_SIZE-1:0],
  input  logic        [1:0]                      NOC_ARLOCK    [NOC_SIZE-1:0],
  input  logic        [3:0]                      NOC_ARCACHE   [NOC_SIZE-1:0],
  input  logic        [2:0]                      NOC_ARPROT    [NOC_SIZE-1:0],
  input  logic        [3:0]                      NOC_ARQOS     [NOC_SIZE-1:0],
  input  logic        [3:0]                      NOC_ARREGION  [NOC_SIZE-1:0],
  input  logic        [`AXI_USER_REQ_WIDTH-1:0]  NOC_ARUSER    [NOC_SIZE-1:0],
  input  logic                                   NOC_ARVALID   [NOC_SIZE-1:0],
  // Read Data channel
  input  logic                                   NOC_RREADY    [NOC_SIZE-1:0],

  // AXI Interface - MISO
  // Write Addr channel
  output logic                                   NOC_AWREADY   [NOC_SIZE-1:0],
  // Write Data channel
  output logic                                   NOC_WREADY    [NOC_SIZE-1:0],
  // Write Response channel
  output logic                                   NOC_BID       [NOC_SIZE-1:0],
  output aerror_t                                NOC_BRESP     [NOC_SIZE-1:0],
  output logic        [`AXI_USER_RESP_WIDTH-1:0] NOC_BUSER     [NOC_SIZE-1:0],
  output logic                                   NOC_BVALID    [NOC_SIZE-1:0],
  // Read addr channel
  output logic                                   NOC_ARREADY   [NOC_SIZE-1:0],
  // Read data channel
  output logic                                   NOC_RID       [NOC_SIZE-1:0],
  output logic        [`AXI_DATA_WIDTH-1:0]      NOC_RDATA     [NOC_SIZE-1:0],
  output aerror_t                                NOC_RRESP     [NOC_SIZE-1:0],
  output logic                                   NOC_RLAST     [NOC_SIZE-1:0],
  output logic         [`AXI_USER_REQ_WIDTH-1:0] NOC_RUSER     [NOC_SIZE-1:0],
  output logic                                   NOC_RVALID    [NOC_SIZE-1:0]
);
  s_axi_mosi_t [NOC_SIZE-1:0] axi_mosi;
  s_axi_miso_t [NOC_SIZE-1:0] axi_miso;

  always begin
    for (int i=0;i<NOC_SIZE;i++) begin
      axi_mosi[i].awid     = NOC_AWID[i];
      axi_mosi[i].awaddr   = NOC_AWADDR[i];
      axi_mosi[i].awlen    = NOC_AWLEN[i];
      axi_mosi[i].awsize   = NOC_AWSIZE[i];
      axi_mosi[i].awburst  = NOC_AWBURST[i];
      axi_mosi[i].awlock   = NOC_AWLOCK[i];
      axi_mosi[i].awcache  = NOC_AWCACHE[i];
      axi_mosi[i].awprot   = NOC_AWPROT[i];
      axi_mosi[i].awqos    = NOC_AWQOS[i];
      axi_mosi[i].awregion = NOC_AWREGION[i];
      axi_mosi[i].awuser   = NOC_AWUSER[i];
      axi_mosi[i].awvalid  = NOC_AWVALID[i];
      axi_mosi[i].wid      = NOC_WID[i];
      axi_mosi[i].wdata    = NOC_WDATA[i];
      axi_mosi[i].wstrb    = NOC_WSTRB[i];
      axi_mosi[i].wlast    = NOC_WLAST[i];
      axi_mosi[i].wuser    = NOC_WUSER[i];
      axi_mosi[i].wvalid   = NOC_WVALID[i];
      axi_mosi[i].bready   = NOC_BREADY[i];
      axi_mosi[i].arid     = NOC_ARID[i];
      axi_mosi[i].araddr   = NOC_ARADDR[i];
      axi_mosi[i].arlen    = NOC_ARLEN[i];
      axi_mosi[i].arsize   = NOC_ARSIZE[i];
      axi_mosi[i].arburst  = NOC_ARBURST[i];
      axi_mosi[i].arlock   = NOC_ARLOCK[i];
      axi_mosi[i].arcache  = NOC_ARCACHE[i];
      axi_mosi[i].arprot   = NOC_ARPROT[i];
      axi_mosi[i].arqos    = NOC_ARQOS[i];
      axi_mosi[i].arregion = NOC_ARREGION[i];
      axi_mosi[i].aruser   = NOC_ARUSER[i];
      axi_mosi[i].arvalid  = NOC_ARVALID[i];
      axi_mosi[i].rready   = NOC_RREADY[i];

      NOC_AWREADY[i]  = axi_miso[i].awready;
      NOC_WREADY[i]   = axi_miso[i].wready;
      NOC_BID[i]      = axi_miso[i].bid;
      NOC_BRESP[i]    = axi_miso[i].bresp;
      NOC_BUSER[i]    = axi_miso[i].buser;
      NOC_BVALID[i]   = axi_miso[i].bvalid;
      NOC_ARREADY[i]  = axi_miso[i].arready;
      NOC_RID[i]      = axi_miso[i].rid;
      NOC_RDATA[i]    = axi_miso[i].rdata;
      NOC_RRESP[i]    = axi_miso[i].rresp;
      NOC_RLAST[i]    = axi_miso[i].rlast;
      NOC_RUSER[i]    = axi_miso[i].ruser;
      NOC_RVALID[i]   = axi_miso[i].rvalid;
    end
  end

  ravenoc u_ravenoc (
    .clk_axi        (clk_axi),
    .clk_noc        (clk_noc),
    .arst_axi       (arst_axi),
    .arst_noc       (arst_noc),
    .axi_mosi_if    (axi_mosi),
    .axi_miso_if    (axi_miso)
  );
endmodule
