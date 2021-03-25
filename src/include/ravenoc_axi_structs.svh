`ifndef _ravenoc_axi_
  `define _ravenoc_axi_

  typedef logic [`AXI_ADDR_WIDTH-1:0] axi_addr_t;

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

  typedef enum logic [1:0] {
    NONE,
    NOC_CSR,
    NOC_RD_FIFOS,
    NOC_WR_FIFOS
  } axi_mm_reg_t;

  typedef struct packed {
    axi_mm_reg_t                        region;
    logic [VC_WIDTH-1:0]                virt_chn_id;
  } s_axi_mm_dec_t;

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
    logic                               bid;
    aerror_t                            bresp;
    logic [`AXI_USER_RESP_WIDTH-1:0]    buser;
    logic                               bvalid;
    // Read addr channel
    logic                               arready;
    // Read data channel
    logic                               rid;
    logic [`AXI_DATA_WIDTH-1:0]         rdata;
    aerror_t                            rresp;
    logic                               rlast;
    logic [`AXI_USER_REQ_WIDTH-1:0]     ruser;
    logic                               rvalid;
  } s_axi_miso_t;

  typedef struct packed {
    // Write Address channel
    logic                               awid;
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
    logic                               arid;
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

  typedef struct packed {
    logic                       valid;
    logic                       req_new;
    logic                       req_last;
    logic [VC_WIDTH-1:0]        vc_id;
    // Packet size in bytes
    logic [PKT_WIDTH-1:0]       pkt_sz;
    logic [`AXI_DATA_WIDTH-1:0] flit_data_width;
  } s_pkt_out_req_t;

  typedef struct packed {
    logic                       ready;
  } s_pkt_out_resp_t;

  typedef struct packed {
    logic                       valid;
    logic [`AXI_DATA_WIDTH-1:0] flit_data_width;
    logic [VC_WIDTH-1:0]        rq_vc;
  } s_pkt_in_req_t;

  typedef struct packed {
    logic                       ready;
  } s_pkt_in_resp_t;

  typedef struct packed {
    //logic [`AXI_ADDR_WIDTH-1:0]   addr;
    //logic [`AXI_ALEN_WIDTH-1:0]   alen;
    //logic [`AXI_ASIZE_WIDTH-1:0]  asize
    logic                       error;
    logic [15:0]                addr;
    logic [7:0]                 alen;
    logic [1:0]                 asize;
  } s_ot_fifo_t;

  //typedef struct packed {
    //x_width_t                   x_dest;
    //y_width_t                   y_dest;
    //logic                       invalid;
  //} s_noc_addr_t;
  //

  typedef struct packed {
    logic [N_VIRT_CHN-1:0]      irq_vcs;
  } s_irq_ni_t;
`endif
