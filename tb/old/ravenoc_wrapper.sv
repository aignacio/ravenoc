/**
 * File: verilator_wrapper.sv
 * Description: RaveNoC top module
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
module ravenoc_wrapper import ravenoc_pkg::*; (
  input                               clk /*verilator clocker*/,
  input                               arst,
  input   [$clog2(NOC_SIZE)-1:0]      axi_sel,
  //******************************************
  //  AXI MISO
  //******************************************
  // Write Addr channel
  output  logic                             awready,
  // Write Data channel
  output  logic                             wready,
  // Write Response channel
  output  logic                             bid,
  output  aerror_t                          bresp,
  output  logic [`AXI_USER_RESP_WIDTH-1:0]  buser,
  output  logic                             bvalid,
  // Read addr channel
  output  logic                             arready,
  // Read data channel
  output  logic                             rid,
  output  logic [`AXI_DATA_WIDTH-1:0]       rdata,
  output  aerror_t                          rresp,
  output  logic                             rlast,
  output  logic [`AXI_USER_REQ_WIDTH-1:0]   ruser,
  output  logic                             rvalid,

  //******************************************
  //  AXI MOSI
  //******************************************
  input                                     awid,
  input   axi_addr_t                        awaddr,
  input   [`AXI_ALEN_WIDTH-1:0]             awlen,
  input   asize_t                           awsize,
  input   aburst_t                          awburst,
  input   [1:0]                             awlock,
  input   [3:0]                             awcache,
  input   [2:0]                             awprot,
  input   [3:0]                             awqos,
  input   [3:0]                             awregion,
  input   [`AXI_USER_REQ_WIDTH-1:0]         awuser,
  input                                     awvalid,
  // Write Data channel
  input                                     wid,
  input   [`AXI_DATA_WIDTH-1:0]             wdata,
  input   [(`AXI_DATA_WIDTH/8)-1:0]         wstrb,
  input                                     wlast,
  input   [`AXI_USER_DATA_WIDTH-1:0]        wuser,
  input                                     wvalid,
  // Write Response channel
  input                                     bready,
  // Read Address channel
  input                                     arid,
  input   axi_addr_t                        araddr,
  input   [`AXI_ALEN_WIDTH-1:0]             arlen,
  input   asize_t                           arsize,
  input   aburst_t                          arburst,
  input   [1:0]                             arlock,
  input   [3:0]                             arcache,
  input   [2:0]                             arprot,
  input   [3:0]                             arqos,
  input   [3:0]                             arregion,
  input   [`AXI_USER_REQ_WIDTH-1:0]         aruser,
  input                                     arvalid,
  // Read Data channel
  input                                     rready,
  output  logic                             test_z
);
  s_axi_mosi_t [NOC_SIZE-1:0] axi_mosi_int;
  s_axi_miso_t [NOC_SIZE-1:0] axi_miso_int;

  always_comb begin
    awready = '0;
    wready  = '0;
    bid     = '0;
    bresp   = '0;
    buser   = '0;
    bvalid  = '0;
    arready = '0;
    rid     = '0;
    rdata   = '0;
    rresp   = '0;
    rlast   = '0;
    ruser   = '0;
    rvalid  = '0;

    for (int i=0;i<NOC_SIZE-1;i++) begin
      if (axi_sel == i[$clog2(NOC_SIZE)-1:0]) begin
        // Master => Slave
        axi_mosi_int[i].awid     = awid;
        axi_mosi_int[i].awaddr   = awaddr;
        axi_mosi_int[i].awlen    = awlen;
        axi_mosi_int[i].awsize   = awsize;
        axi_mosi_int[i].awburst  = awburst;
        axi_mosi_int[i].awlock   = awlock;
        axi_mosi_int[i].awcache  = awcache;
        axi_mosi_int[i].awprot   = awprot;
        axi_mosi_int[i].awqos    = awqos;
        axi_mosi_int[i].awregion = awregion;
        axi_mosi_int[i].awuser   = awuser;
        axi_mosi_int[i].awvalid  = awvalid;
        axi_mosi_int[i].wid      = wid;
        axi_mosi_int[i].wdata    = wdata;
        axi_mosi_int[i].wstrb    = wstrb;
        axi_mosi_int[i].wlast    = wlast;
        axi_mosi_int[i].wuser    = wuser;
        axi_mosi_int[i].wvalid   = wvalid;
        axi_mosi_int[i].bready   = bready;
        axi_mosi_int[i].arid     = arid;
        axi_mosi_int[i].araddr   = araddr;
        axi_mosi_int[i].arlen    = arlen;
        axi_mosi_int[i].arsize   = arsize;
        axi_mosi_int[i].arburst  = arburst;
        axi_mosi_int[i].arlock   = arlock;
        axi_mosi_int[i].arcache  = arcache;
        axi_mosi_int[i].arprot   = arprot;
        axi_mosi_int[i].arqos    = arqos;
        axi_mosi_int[i].arregion = arregion;
        axi_mosi_int[i].aruser   = aruser;
        axi_mosi_int[i].arvalid  = arvalid;
        axi_mosi_int[i].rready   = rready;
        // Master <= Slave
        awready = axi_miso_int[i].awready;
        wready  = axi_miso_int[i].wready;
        bid     = axi_miso_int[i].bid;
        bresp   = axi_miso_int[i].bresp;
        buser   = axi_miso_int[i].buser;
        bvalid  = axi_miso_int[i].bvalid;
        arready = axi_miso_int[i].arready;
        rid     = axi_miso_int[i].rid;
        rdata   = axi_miso_int[i].rdata;
        rresp   = axi_miso_int[i].rresp;
        rlast   = axi_miso_int[i].rlast;
        ruser   = axi_miso_int[i].ruser;
        rvalid  = axi_miso_int[i].rvalid;
        break;
      end
      else begin
        axi_mosi_int[i] = s_axi_mosi_t'(0);
      end
    end
  end

  ravenoc u_ravenoc (
    .clk(clk),
    .arst(arst),
    .axi_mosi_if(axi_mosi_int),
    .axi_miso_if(axi_miso_int)
  );
endmodule
