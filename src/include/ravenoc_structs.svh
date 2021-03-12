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
    //cfg_sz_x     : `NOC_CFG_SZ_X,
    //cfg_sz_y     : `NOC_CFG_SZ_Y,
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

  localparam  X_Y_ALG        = 0;
  localparam  Y_X_ALG        = 1;
  localparam  FLIT_WIDTH     = `FLIT_DATA+`FLIT_TP_WIDTH;
  localparam  FLIT_DATA      = `FLIT_DATA;
  localparam  FLIT_BUFF      = `FLIT_BUFF;
  localparam  FLIT_TP_WIDTH  = `FLIT_TP_WIDTH;
  localparam  N_VIRT_CHN     = `N_VIRT_CHN;
  localparam  H_PRIORITY     = `H_PRIORITY;
  localparam  NOC_CFG_SZ_X   = `NOC_CFG_SZ_X;
  localparam  NOC_CFG_SZ_Y   = `NOC_CFG_SZ_Y;
  localparam  NOC_SIZE       = `NOC_CFG_SZ_X*`NOC_CFG_SZ_Y;
  localparam  ROUTING_ALG    = `ROUTING_ALG;
  localparam  MAX_SZ_PKT     = `MAX_SZ_PKT;
  localparam  MIN_SIZE_FLIT  = `MIN_SIZE_FLIT;

  localparam  VC_WIDTH        = MinBitWidth(N_VIRT_CHN);
  localparam  X_WIDTH         = MinBitWidth(NOC_CFG_SZ_X-1);
  localparam  Y_WIDTH         = MinBitWidth(NOC_CFG_SZ_Y-1);
  localparam  PKT_WIDTH       = MinBitWidth(MAX_SZ_PKT-1);
  localparam  MIN_DATA_WIDTH  = FLIT_WIDTH-FLIT_TP_WIDTH-X_WIDTH-Y_WIDTH-PKT_WIDTH;
  localparam  PKT_POS_WIDTH   = FLIT_WIDTH-FLIT_TP_WIDTH-X_WIDTH-Y_WIDTH;
  localparam  COORD_POS_WIDTH = FLIT_WIDTH-FLIT_TP_WIDTH;

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
`endif
