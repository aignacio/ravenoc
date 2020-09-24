`ifndef _ravenoc_defines_
  `define _ravenoc_defines_

  `ifndef FLIT_WIDTH
    `define  FLIT_WIDTH       34        // Flit width in bits
  `endif

  `ifndef FLIT_BUFF
    `define  FLIT_BUFF        4         // Number of flits buffered in the virtual channel fifo, MUST BE POWER OF 2 0..2..4..8
  `endif

  `ifndef FLIT_TP_WIDTH
    `define FLIT_TP_WIDTH     2         // Flit Width type
  `endif

  `ifndef N_VIRT_CHN
    `define N_VIRT_CHN        3         // Number of virtual channels
  `endif

  `ifndef H_PRIORITY
    `define H_PRIORITY        1         // Priority descending on Virtual channel - low priority VC_ID (0)
  `endif

  `ifndef NOC_CFG_SZ_X
    `define NOC_CFG_SZ_X      3         // NoC size X
  `endif

  `ifndef NOC_CFG_SZ_Y
    `define NOC_CFG_SZ_Y      4         // NoC size Y
  `endif

  `ifndef ROUTING_ALG
    `define ROUTING_ALG       "X_Y_ALG" // Routing algorithm
  `endif

  `ifndef MAX_SZ_PKT
    `define MAX_SZ_PKT        256       // Max number of flits per packet
  `endif

  `ifndef MIN_SIZE_FLIT
    `define MIN_SIZE_FLIT     1         // The smallest flit size
  `endif

  `define MIN_CLOG(X)         $clog2(X>1?X:2)
  `define VC_WIDTH            $clog2(`N_VIRT_CHN>1?`N_VIRT_CHN:2)
  `define X_WIDTH             $clog2(`NOC_CFG_SZ_X>1?`NOC_CFG_SZ_X:2)
  `define Y_WIDTH             $clog2(`NOC_CFG_SZ_Y>1?`NOC_CFG_SZ_Y:2)
  `define PKT_WIDTH           $clog2(`MAX_SZ_PKT>1?`MAX_SZ_PKT:2)
  `define MIN_DATA_WIDTH      `FLIT_WIDTH-`FLIT_TP_WIDTH-`X_WIDTH-`Y_WIDTH-`PKT_WIDTH
`endif
