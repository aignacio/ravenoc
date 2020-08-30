`ifndef _ravenoc_defines_
  `define _ravenoc_defines_
  localparam  FLIT_WIDTH    = 34;   // Flit width in bits
  localparam  FLIT_BUFF     = 4;    // Number of flits buffered in the virtual channel fifo, MUST BE POWER OF 2 0..2..4..8
  localparam  N_VIRT_CHN    = 4;    // Number of virtual channels
  localparam  PRIORITY_DESC = 1;    // Priority descending on Virtual channel - low priority (0)
`endif
