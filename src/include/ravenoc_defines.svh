`ifndef _ravenoc_defines_
  `define _ravenoc_defines_
  localparam  FLIT_WIDTH    = 34;                       // Flit width in bits
  localparam  FLIT_BUFF     = 4;                        // Number of flits buffered in the virtual channel fifo, MUST BE POWER OF 2 0..2..4..8
  localparam  FLIT_TP_WIDTH = 2;                        // Flit Width type
  localparam  N_VIRT_CHN    = 1;                        // Number of virtual channels
  localparam  H_PRIORITY    = 1;                        // Priority descending on Virtual channel - low priority VC_ID (0)
  localparam  NOC_CFG_SZ_X  = 2;                        // NoC size X
  localparam  NOC_CFG_SZ_Y  = 2;                        // NoC size Y
  localparam  ROUTING_ALG   = "X_Y_ALG";                // Routing algorithm
  localparam  X_WIDTH_FLIT  = $clog2(NOC_CFG_SZ_X>1?
                                     NOC_CFG_SZ_X:2);   // Number of bits of the X dest index
  localparam  Y_WIDTH_FLIT  = $clog2(NOC_CFG_SZ_Y>1?
                                     NOC_CFG_SZ_Y:2);   // Number of bits of the Y dest index
  localparam  MAX_SZ_PKT    = 256;                      // Max number of flits per packet
  localparam  PKT_SZ_WIDTH  = $clog2(MAX_SZ_PKT);       // Number of bits of the packet size
  localparam  MIN_SIZE_FLIT = 1;                        // The smallest flit size
  localparam  HEAD_F_DATA_W = FLIT_WIDTH-
                              FLIT_TP_WIDTH-
                              X_WIDTH_FLIT-
                              Y_WIDTH_FLIT-
                              PKT_SZ_WIDTH;             // Head flit data width
`endif
