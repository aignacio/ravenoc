`ifndef _ravenoc_structs_
  `define _ravenoc_structs_

  //typedef struct packed {L
    //shortint flit_width;    // flit width in bits
    //shortint flit_buff;     // Number of flits buffer in the vc fifo, must be power of 2 - 0..2..4
    //shortint flit_tp_width[MaL; // flit width type
    //shortint n_virt_chn;    // number of virtual channels
    //shortint h_priority;    // priority descending on virtual channel - low priority vc_id (0)
    //shortint cfg_sz_x;      //[MaL NoC size X
    //shortint cfg_sz_y;      // NoC size Y
    //shortint routing_alg;   // Routing Algorithm
    //shortint max_sz_pkt;    // max[MaL number of flits per packet
    //shortint min_size_flit; // the smallest flit size
  //} s_noc_config_t;

  //localparam s_noc_config_t default_noc_cfg = '{
    //flit_width   : `FLIT_WIDTH,
    //flit_buff    : `FLIT_BUFF,
    //flit_tp_width: `FLIT_TP_WIDTH,
    //n_virt_chn   : `N_VIRT_CHN,
    //h_priority   : `H_PRIORITY,
    //cfg_sz_x     : `NOC_CFG_SZ_ROWS,
    //cfg_sz_y     : `NOC_CFG_SZ_COLS,
    //routing_alg  : `ROUTING_ALG,
    //max_sz_pkt   : `MAX_SZ_PKT,
    //min_size_flit: `MIN_SIZE_FLIT
  //};

  function automatic integer MinBitWidth(int val);
      int bit_width;
      for (bit_width = 0; val > 0; bit_width = bit_width + 1) begin
            val = val >> 1;
      end
      return bit_width;
	endfunction

  localparam  X_Y_ALG         = 0;
  localparam  Y_X_ALG         = 1;
  localparam  FLIT_WIDTH      = `FLIT_DATA_WIDTH+`FLIT_TP_WIDTH;
  localparam  FLIT_DATA_WIDTH = `FLIT_DATA_WIDTH;
  localparam  FLIT_BUFF       = `FLIT_BUFF;
  localparam  FLIT_TP_WIDTH   = `FLIT_TP_WIDTH;
  localparam  N_VIRT_CHN      = `N_VIRT_CHN;
  localparam  H_PRIORITY      = `H_PRIORITY;
  localparam  NOC_CFG_SZ_ROWS = `NOC_CFG_SZ_ROWS;
  localparam  NOC_CFG_SZ_COLS = `NOC_CFG_SZ_COLS;
  localparam  NOC_SIZE        = `NOC_CFG_SZ_ROWS*`NOC_CFG_SZ_COLS;
  localparam  ROUTING_ALG     = `ROUTING_ALG;
  localparam  MAX_SZ_PKT      = `MAX_SZ_PKT;
  localparam  MIN_SIZE_FLIT   = `MIN_SIZE_FLIT;
  localparam  RAVENOC_LABEL   = "v1.0";

  localparam  VC_WIDTH        = MinBitWidth(`MIN_CLOG(N_VIRT_CHN)-1);
  localparam  X_WIDTH         = MinBitWidth(`MIN_CLOG(NOC_CFG_SZ_ROWS)-1);
  localparam  Y_WIDTH         = MinBitWidth(`MIN_CLOG(NOC_CFG_SZ_COLS)-1);
  localparam  PKT_WIDTH       = MinBitWidth(`MIN_CLOG(MAX_SZ_PKT)-1);
  localparam  MIN_DATA_WIDTH  = FLIT_WIDTH-FLIT_TP_WIDTH-X_WIDTH-Y_WIDTH-PKT_WIDTH;
  localparam  PKT_POS_WIDTH   = FLIT_WIDTH-FLIT_TP_WIDTH-X_WIDTH-Y_WIDTH;
  localparam  COORD_POS_WIDTH = FLIT_WIDTH-FLIT_TP_WIDTH;
  localparam  CSR_REGS_WIDTH  = MinBitWidth((`N_CSR_REGS-1)*'h4);

  // Usage of s_ = struct / _t = typedefl
  typedef enum logic [FLIT_TP_WIDTH-1:0] {
    HEAD_FLIT,
    BODY_FLIT,
    TAIL_FLIT
  } flit_type_t;

  typedef enum logic [2:0] {
    NORTH_PORT,
    SOUTH_PORT,
    WEST_PORT,
    EAST_PORT,
    LOCAL_PORT
  } routes_t;

  typedef struct packed {
    logic north_req;
    logic south_req;
    logic west_req;
    logic east_req;
    logic local_req;
  } s_router_ports_t;

  typedef logic [X_WIDTH-1:0] x_width_t;
  typedef logic [Y_WIDTH-1:0] y_width_t;

  typedef struct packed {
    flit_type_t                type_f;
    x_width_t                  x_dest;
    y_width_t                  y_dest;
    logic [PKT_WIDTH-1:0]      pkt_size;
    logic [MIN_DATA_WIDTH-1:0] data;
  } s_flit_head_data_t;

  // Flit handshake interface
  typedef struct packed {
    logic [FLIT_WIDTH-1:0]  fdata;
    logic [VC_WIDTH-1:0]    vc_id;
    logic                   valid;
  } s_flit_req_t;

  typedef struct packed {
    logic                   ready;
  } s_flit_resp_t;

  typedef struct packed {
    s_flit_req_t  req;
    s_flit_resp_t resp;
  } s_local_mosi_t;

  typedef struct packed {
    s_flit_req_t  req;
    s_flit_resp_t resp;
  } s_local_miso_t;

  typedef struct packed {
    logic [N_VIRT_CHN-1:0] irq_vcs;
    logic                  irq_trig;
  } s_irq_ni_t;

  typedef struct packed {
    logic         valid;
    logic         rd_or_wr;
    logic [15:0]  addr;
    logic [31:0]  data_in;
  } s_csr_req_t;

  typedef struct packed {
    logic [31:0]  data_out;
    logic         error;
    logic         ready;
  } s_csr_resp_t;

  typedef enum logic [CSR_REGS_WIDTH-1:0] {
    RAVENOC_VERSION = 'd0,
    ROUTER_ROW_X_ID = 'd4,
    ROUTER_COL_Y_ID = 'd8,
    IRQ_RD_STATUS   = 'd12,
    IRQ_RD_MUX      = 'd16,
    IRQ_RD_MASK     = 'd20
  } ravenoc_csrs_t;

  typedef enum logic [3:0] {
    DEFAULT,
    MUX_EMPTY_FLAGS,
    MUX_FULL_FLAGS,
    MUX_COMP_FLAGS
  } s_irq_ni_mux_t;
`endif
