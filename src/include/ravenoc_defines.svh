`ifndef _ravenoc_defines_
  `define _ravenoc_defines_

  `ifndef FLIT_DATA_WIDTH
    `define  FLIT_DATA_WIDTH      32        // Flit width data in bits
  `endif

  `ifndef FLIT_TP_WIDTH
    `define FLIT_TP_WIDTH         2         // Flit Width type
  `endif

  `ifndef FLIT_BUFF
    `define  FLIT_BUFF            4         // Number of flits buffered in the virtual channel fifo, MUST BE POWER OF 2 1..2..4..8
  `endif

  `ifndef N_VIRT_CHN
    `define N_VIRT_CHN            3         // Number of virtual channels
  `endif

  `ifndef H_PRIORITY
    `define H_PRIORITY            0         // 1= Priority descending on Virtual channel - low priority VC_ID (0)
  `endif

  `ifndef NOC_CFG_SZ_ROWS
    `define NOC_CFG_SZ_ROWS       2         // NoC size rows
  `endif

  `ifndef NOC_CFG_SZ_COLS
    `define NOC_CFG_SZ_COLS       2         // NoC size cols
  `endif

  `ifndef ROUTING_ALG
    `define ROUTING_ALG           X_Y_ALG   // Routing algorithm
  `endif

  `ifndef MAX_SZ_PKT
    `define MAX_SZ_PKT            256       // Max number of flits per packet
  `endif

  `ifndef MIN_SIZE_FLIT
    `define MIN_SIZE_FLIT         1         // The smallest flit size
  `endif

  `ifndef N_CSR_REGS
    `define N_CSR_REGS            5         // Total number of CSR regs
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

  // Not used these signals in the logic for now
  `ifndef AXI_USER_REQ_WIDTH
      `define AXI_USER_REQ_WIDTH  2
  `endif

  `ifndef AXI_USER_DATA_WIDTH
      `define AXI_USER_DATA_WIDTH 2
  `endif

  `ifndef AXI_USER_RESP_WIDTH
      `define AXI_USER_RESP_WIDTH 2
  `endif

  // Number of flits that each read buffer
  // in the AXI slave can hold it (per VC)
  `ifndef RD_AXI_BFF
    `define RD_AXI_BFF(x) 1<<x
  `endif

  // MM regions
  // Region 0 - Send flit buffers
  // Region 1 - Receive flit buffer
  // Region 3 - NoC CSR
  `ifndef AXI_MM_REG
    `define AXI_MM_REG    1
  `endif


  `ifndef AXI_WR_BFF_CHN
    `define AXI_WR_BFF_CHN(x) 'h1000+(x*'h8)
  `endif

  `ifndef AXI_RD_BFF_CHN
    `define AXI_RD_BFF_CHN(x) 'h2000+(x*'h8)
  `endif

  `ifndef AXI_CSR_REG
    `define AXI_CSR_REG 1
    localparam int AXI_CSR [`N_CSR_REGS-1:0] = '{
      'h3000, // IRQ_ID, IRQ_ACTIVE, IRQ_STATUS
      'h3008, // IRQ_CFG
      'h300C, // NOC_VERSION
      'h3010, // SPARE_1
      'h3018  // SPARE_2
    };
  `endif
`endif
