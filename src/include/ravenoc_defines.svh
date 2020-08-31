`ifndef _ravenoc_defines_
  `define _ravenoc_defines_
  localparam  FLIT_WIDTH    = 34;                       // Flit width in bits
  localparam  FLIT_BUFF     = 4;                        // Number of flits buffered in the virtual channel fifo, MUST BE POWER OF 2 0..2..4..8
  localparam  N_VIRT_CHN    = 4;                        // Number of virtual channels
  localparam  H_PRIORITY    = 1;                        // Priority descending on Virtual channel - low priority VC_ID (0)
  localparam  ROUTING_ALG   = "X_Y_ALG";                // Routing algorithm
  localparam  X_WIDTH_FLIT  = 3;                        // Number of bits of the X dest index
  localparam  Y_WIDTH_FLIT  = 3;                        // Number of bits of the Y dest index
  localparam  PKT_SZ_WIDTH  = 8;                        // Number of bits of the packet size
  // Bit position inside flit
  //localparam  MSB_TYP_IF    = FLIT_WIDTH-1;             // MSB of flit type inside the flit, in this case MSB
  //localparam  MSB_X_IF      = MSB_TYP_IF-2;             // MSB of flit (X,Y) address inside the fliti
  //localparam  MSB_Y_IF      = MSB_X_IF-X_WIDTH_FLIT;    // MSB of flit (X,Y) address inside the flit
`endif
