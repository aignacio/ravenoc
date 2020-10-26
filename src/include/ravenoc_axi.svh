`ifndef _ravenoc_axi_
  `define _ravenoc_axi_


  typedef enum logic [2:0] {
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
    WRAP
    RESERVED
  } aburst_t;

  typedef enum logic [1:0] {
    OKAY,
    EXOKAY,
    SLVERR,
    DECERR
  } aerror_t;

  typedef struct packed {
    // Write Addr channel
    logic                               awready;
    // Write Data channel
    logic                               wready;
    // Write Response channel
    logic                               bid;
    aerror_t                            bresp;
    logic [AXI_USER_RESP_WIDTH-1:0]     buser;
    logic                               bvalid;
    // Read addr channel
    logic                               arready;
    // Read data channel
    logic                               rid;
    logic [AXI_DATA_WIDTH-1:0]          rdata;
    aerror_t                            rresp;
    logic                               rlast;
    logic [AXI_USER_REQ_WIDTH-1:0]      ruser;
    logic                               rvalid;
  } s_axi_miso_t;

  typedef struct packed {
    // Globas
    logic                               aclk;
    logic                               aresetn;
    // Write Address channel
    logic                               awid;
    logic [AXI_ADDR_WIDTH-1:0]          awaddr;
    logic [7:0]                         awlen;
    asize_t                             awsize;
    aburst_t                            awburst;
    logic [1:0]                         awlock;
    logic [3:0]                         awcache;
    logic [2:0]                         awprot;
    logic [3:0]                         awqos;
    logic [3:0]                         awregion;
    logic [AXI_USER_REQ_WIDTH-1:0]      awuser;
    logic                               awvalid;
    // Write Data channel
    logic                               wid;
    logic [AXI_DATA_WIDTH]              wdata;
    logic [(AXI_DATA_WIDTH/8)-1:0]      wstrb;
    logic                               wlast;
    logic [AXI_USER_DATA_WIDTH-1:0]     wuser;
    logic                               wvalid;
    // Write Response channel
    logic                               bready;
    // Read Address channel
    logic                               arid;
    logic [AXI_ADDR_WIDTH-1:0]          araddr;
    logic [7:0]                         arlen;
    asize_t                             arsize;
    aburst_t                            arburst;
    logic [1:0]                         arlock;
    logic [3:0]                         arcache;
    logic [2:0]                         arprot;
    logic [3:0]                         arqos;
    logic [3:0]                         arregion;
    logic [AXI_USER_REQ_WIDTH-1:0]      aruser;
    logic                               arvalid;
    // Read Data channel
    logic                               rready;
  } s_axi_mosi_t;

`endif
