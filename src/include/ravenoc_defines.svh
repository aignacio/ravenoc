`ifndef _RAVENOC_DEFINES_
  `define _RAVENOC_DEFINES_

  `ifndef FLIT_DATA_WIDTH
    `define  FLIT_DATA_WIDTH      32        // Flit width data in bits
  `endif

  `ifndef FLIT_TP_WIDTH
    `define FLIT_TP_WIDTH         2         // Flit Width type
  `endif

  `ifndef FLIT_BUFF
    `define  FLIT_BUFF            2         // Number of flits buffered in the virtual
  `endif                                    //channel fifo, MUST BE POWER OF 2 1..2..4..8

  `ifndef N_VIRT_CHN
    `define N_VIRT_CHN            3         // Number of virtual channels
  `endif

  `ifndef H_PRIORITY
    `define H_PRIORITY            ZeroHighPrior  // Priority asc/descending on Virtual
  `endif                                         // channel

  `ifndef NOC_CFG_SZ_ROWS
    `define NOC_CFG_SZ_ROWS       2         // NoC size rows
  `endif

  `ifndef NOC_CFG_SZ_COLS
    `define NOC_CFG_SZ_COLS       2         // NoC size cols
  `endif

  `ifndef ROUTING_ALG
    `define ROUTING_ALG           XYAlg     // Routing algorithm
  `endif

  `ifndef MAX_SZ_PKT
    `define MAX_SZ_PKT            256       // Max number of flits per packet
  `endif

  `ifndef N_CSR_REGS
    `define N_CSR_REGS            8         // Total number of CSR regs
  `endif

  `ifndef AUTO_ADD_PKT_SZ
    `define AUTO_ADD_PKT_SZ       0         // If 1, it'll overwrite the pkt size on the flit gen
  `endif

  `define MIN_CLOG(X)             (X>1?X:2)

  //*********************
  //
  // AXI Definitions
  //
  // ********************
  `ifndef AXI_ADDR_WIDTH
    `define AXI_ADDR_WIDTH        32
  `endif

  `ifndef AXI_DATA_WIDTH
    `define AXI_DATA_WIDTH        `FLIT_DATA_WIDTH
  `endif

  `ifndef AXI_ALEN_WIDTH
    `define AXI_ALEN_WIDTH        8
  `endif

  `ifndef AXI_ASIZE_WIDTH
    `define AXI_ASIZE_WIDTH       3
  `endif

  `ifndef AXI_MAX_OUTSTD_RD
    `define AXI_MAX_OUTSTD_RD     2
  `endif

  `ifndef AXI_MAX_OUTSTD_WR
    `define AXI_MAX_OUTSTD_WR     2
  `endif

  `ifndef AXI_USER_RESP_WIDTH
      `define AXI_USER_RESP_WIDTH 2
  `endif
  // Not used these signals in the logic for now
  `ifndef AXI_USER_REQ_WIDTH
      `define AXI_USER_REQ_WIDTH  2
  `endif

  `ifndef AXI_USER_DATA_WIDTH
      `define AXI_USER_DATA_WIDTH 2
  `endif

  `ifndef AXI_TXN_ID_WIDTH
      `define AXI_TXN_ID_WIDTH    1
  `endif

  // Number of flits that each read buffer
  // in the AXI slave can hold it (per VC)
  `ifndef RD_AXI_BFF
    `define RD_AXI_BFF(x)         x<=2?(1<<x):4
  `endif

  // MM regions
  // Region 0 - Send flit buffers
  // Region 1 - Receive flit buffer
  // Region 3 - NoC CSR
  `ifndef AXI_MM_REG
    `define AXI_MM_REG            1
  `endif

  `ifndef AXI_WR_BFF_BASE_ADDR
    `define AXI_WR_BFF_BASE_ADDR  'h1000
  `endif

  `ifndef AXI_RD_BFF_BASE_ADDR
    `define AXI_RD_BFF_BASE_ADDR  'h2000
  `endif

  `ifndef AXI_CSR_BASE_ADDR
    `define AXI_CSR_BASE_ADDR     'h3000
  `endif

  `ifndef AXI_WR_BFF_CHN
    `define AXI_WR_BFF_CHN(x)     `AXI_WR_BFF_BASE_ADDR+(x*'h8)
  `endif

  `ifndef AXI_RD_BFF_CHN
    `define AXI_RD_BFF_CHN(x)     `AXI_RD_BFF_BASE_ADDR+(x*'h8)
  `endif

  `ifndef AXI_CSR_REG
    `define AXI_CSR_REG(x)        `AXI_CSR_BASE_ADDR+(x*'h4)
  `endif

  `ifndef RD_SIZE_VC_PKT
    `define RD_SIZE_VC_PKT(x)     (`N_CSR_REGS*'h4+x*'h4)
  `endif
  // Number of fifo slots in the ASYNC FIFO used for CDC - Must be power of 2 i.e 2,4,8
  `ifndef CDC_TAPS
      `define CDC_TAPS            2
  `endif
`endif
