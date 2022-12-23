`ifndef _RAVENOC_STRUCTS_
  `define _RAVENOC_STRUCTS_
  import amba_axi_pkg::*;

  function automatic integer MinBitWidth(int val);
      int bit_width;
      for (bit_width = 0; val > 0; bit_width = bit_width + 1) begin
            val = val >> 1;
      end
      return bit_width;
  endfunction

  localparam int XYAlg         = 0;
  localparam int YXAlg         = 1;
  localparam int ZeroLowPrior  = 0;
  localparam int ZeroHighPrior = 1;
  localparam int FlitWidth     = `FLIT_DATA_WIDTH+`FLIT_TP_WIDTH;
  localparam int FlitDataWidth = `FLIT_DATA_WIDTH;
  localparam int FlitBuff      = `FLIT_BUFF;
  localparam int FlitTpWidth   = `FLIT_TP_WIDTH;
  localparam int NumVirtChn    = `N_VIRT_CHN;
  localparam int HighPriority  = `H_PRIORITY;
  localparam int NoCCfgSzRows  = `NOC_CFG_SZ_ROWS;
  localparam int NoCCfgSzCols  = `NOC_CFG_SZ_COLS;
  localparam int NoCSize       = `NOC_CFG_SZ_ROWS*`NOC_CFG_SZ_COLS;
  localparam int RoutingAlg    = `ROUTING_ALG;
  localparam int MaxSzPkt      = `MAX_SZ_PKT;
  localparam int RavenocLabel  = "v1.0";

  localparam int VcWidth       = MinBitWidth(`MIN_CLOG(NumVirtChn)-1);
  localparam int XWidth        = MinBitWidth(`MIN_CLOG(NoCCfgSzRows)-1);
  localparam int YWidth        = MinBitWidth(`MIN_CLOG(NoCCfgSzCols)-1);
  localparam int PktWidth      = MinBitWidth(`MIN_CLOG(MaxSzPkt)-1);
  localparam int MinDataWidth  = FlitWidth-FlitTpWidth-XWidth-YWidth-PktWidth;
  localparam int PktPosWidth   = FlitWidth-FlitTpWidth-XWidth-YWidth;
  localparam int CoordPosWidth = FlitWidth-FlitTpWidth;
  localparam int CsrRegsWidth  = MinBitWidth((`N_CSR_REGS-1)*'h4);

  // Usage of s_ = struct / _t = typedefl

  typedef enum logic [1:0] {
    NONE,
    NOC_CSR,
    NOC_RD_FIFOS,
    NOC_WR_FIFOS
  } axi_mm_reg_t;

  typedef enum logic [FlitTpWidth-1:0] {
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

  typedef enum logic [CsrRegsWidth-1:0] {
    RAVENOC_VERSION = 'd0,
    ROUTER_ROW_X_ID = 'd4,
    ROUTER_COL_Y_ID = 'd8,
    IRQ_RD_STATUS   = 'd12,
    IRQ_RD_MUX      = 'd16,
    IRQ_RD_MASK     = 'd20,
    BUFFER_FULL     = 'd24
  } ravenoc_csrs_t;

  typedef enum logic [2:0] {
    DEFAULT,
    MUX_EMPTY_FLAGS,
    MUX_FULL_FLAGS,
    MUX_COMP_FLAGS,
    PULSE_HEAD_FLIT
  } s_irq_ni_mux_t;

  typedef struct packed {
    logic north_req;
    logic south_req;
    logic west_req;
    logic east_req;
    logic local_req;
  } s_router_ports_t;

  typedef logic [XWidth-1:0]    x_width_t;
  typedef logic [YWidth-1:0]    y_width_t;

  typedef struct packed {
    flit_type_t                 type_f;
    x_width_t                   x_dest;
    y_width_t                   y_dest;
    logic [PktWidth-1:0]        pkt_size;
    logic [MinDataWidth-1:0]    data;
  } s_flit_head_data_t;

  // Flit handshake interface
  typedef struct packed {
    logic [FlitWidth-1:0]       fdata;
    logic [VcWidth-1:0]         vc_id;
    logic                       valid;
  } s_flit_req_t;

  typedef struct packed {
    logic                       ready;
  } s_flit_resp_t;

  typedef struct packed {
    s_flit_req_t                req;
    s_flit_resp_t               resp;
  } s_local_mosi_t;

  typedef struct packed {
    s_flit_req_t                req;
    s_flit_resp_t               resp;
  } s_local_miso_t;

  typedef struct packed {
    logic [NumVirtChn-1:0]      irq_vcs;
    logic                       irq_trig;
  } s_irq_ni_t;

  typedef struct packed {
    logic                       valid;
    logic                       rd_or_wr;
    logic [15:0]                addr;
    logic [31:0]                data_in;
  } s_csr_req_t;

  typedef struct packed {
    logic [31:0]                data_out;
    logic                       error;
    logic                       ready;
  } s_csr_resp_t;

  typedef struct packed {
    axi_mm_reg_t                region;
    logic [VcWidth-1:0]         virt_chn_id;
  } s_axi_mm_dec_t;

  typedef struct packed {
    logic                       valid;
    logic [VcWidth-1:0]         vc_id;
    // Packet size in beats
    logic [PktWidth-1:0]        pkt_sz;
    logic [`AXI_DATA_WIDTH-1:0] flit_data_width;
  } s_pkt_out_req_t;

  typedef struct packed {
    logic                       ready;
  } s_pkt_out_resp_t;

  typedef struct packed {
    logic                       valid;
    logic [`AXI_DATA_WIDTH-1:0] flit_data_width;
    flit_type_t                 f_type;
    logic [VcWidth-1:0]         rq_vc;
    logic [FlitWidth-1:0]       flit_raw;
  } s_pkt_in_req_t;

  typedef struct packed {
    logic                       ready;
  } s_pkt_in_resp_t;

  // We don't use parameter on this function because
  // we're slicing some fields that'll not change.
  // The total width should match with AxiOtFifoWidth
  typedef struct packed {
    logic                       error;
    axi_tid_t                   id;
    logic [15:0]                addr;
    logic [7:0]                 alen;
    logic [1:0]                 asize;
  } s_ot_fifo_t;

  localparam int AxiOtFifoWidth = $bits(s_ot_fifo_t);
  localparam int AxiOtRespFifoWidth = $bits(axi_tid_t)+'d1;
`endif
