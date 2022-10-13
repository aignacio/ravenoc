`ifndef _RAVENOC_AXI_
  `define _RAVENOC_AXI_

  typedef logic [`AXI_ADDR_WIDTH-1:0]   axi_addr_t;
  typedef logic [`AXI_TXN_ID_WIDTH-1:0] axi_tid_t;

  typedef enum logic [`AXI_ASIZE_WIDTH-1:0] {
    BYTE,
    HALF_WORD,
    WORD,
    DWORD,
    BYTES_16,
    BYTES_32,
    BYTES_64,
    BYTES_128
  } asize_t;

  typedef enum logic [1:0] {
    FIXED,
    INCR,
    WRAP,
    RESERVED
  } aburst_t;

  typedef enum logic [1:0] {
    OKAY,
    EXOKAY,
    SLVERR,
    DECERR
  } aerror_t;

  typedef struct packed {
    // Globals
    logic                               aclk;
    logic                               arst;
  } s_axi_glb_t;

  typedef struct packed {
    // Write Addr channel
    logic                               awready;
    // Write Data channel
    logic                               wready;
    // Write Response channel
    axi_tid_t                           bid;
    aerror_t                            bresp;
    logic [`AXI_USER_RESP_WIDTH-1:0]    buser;
    logic                               bvalid;
    // Read addr channel
    logic                               arready;
    // Read data channel
    axi_tid_t                           rid;
    logic [`AXI_DATA_WIDTH-1:0]         rdata;
    aerror_t                            rresp;
    logic                               rlast;
    logic [`AXI_USER_REQ_WIDTH-1:0]     ruser;
    logic                               rvalid;
  } s_axi_miso_t;

  typedef struct packed {
    // Write Address channel
    axi_tid_t                           awid;
    axi_addr_t                          awaddr;
    logic [`AXI_ALEN_WIDTH-1:0]         awlen;
    asize_t                             awsize;
    aburst_t                            awburst;
    logic                               awlock;
    logic [3:0]                         awcache;
    logic [2:0]                         awprot;
    logic [3:0]                         awqos;
    logic [3:0]                         awregion;
    logic [`AXI_USER_REQ_WIDTH-1:0]     awuser;
    logic                               awvalid;
    // Write Data channel
    //logic                               wid; //Only on AXI3
    logic [`AXI_DATA_WIDTH-1:0]         wdata;
    logic [(`AXI_DATA_WIDTH/8)-1:0]     wstrb;
    logic                               wlast;
    logic [`AXI_USER_DATA_WIDTH-1:0]    wuser;
    logic                               wvalid;
    // Write Response channel
    logic                               bready;
    // Read Address channel
    axi_tid_t                           arid;
    axi_addr_t                          araddr;
    logic [`AXI_ALEN_WIDTH-1:0]         arlen;
    asize_t                             arsize;
    aburst_t                            arburst;
    logic                               arlock;
    logic [3:0]                         arcache;
    logic [2:0]                         arprot;
    logic [3:0]                         arqos;
    logic [3:0]                         arregion;
    logic [`AXI_USER_REQ_WIDTH-1:0]     aruser;
    logic                               arvalid;
    // Read Data channel
    logic                               rready;
  } s_axi_mosi_t;

`endif
