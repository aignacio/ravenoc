/**
 * File              : axi_st.h
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 09.01.2021
 * Last Modified Date: 09.01.2021
 * Last Modified By  : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 */
#ifndef AXI_ST_H
#define AXI_ST_H

typedef int axi_addr_t;

typedef enum int {
  BYTE,
  HALF_WORD,
  WORD,
  DWORD,
  BYTES_16,
  BYTES_32,
  BYTES_64,
  BYTES_128
} asize_t;

typedef enum int {
  FIXED,
  INCR,
  WRAP,
  RESERVED
} aburst_t;

typedef enum int {
  OKAY,
  EXOKAY,
  SLVERR,
  DECERR
} aerror_t;

typedef enum int {
  NONE,
  NOC_CSR,
  NOC_RD_FIFOS,
  NOC_WR_FIFOS
} axi_mm_reg_t;

typedef struct  {
  axi_mm_reg_t            region;
  int                     virt_chn_id;
} s_axi_mm_dec_t;

typedef struct  {
  // Globals
  int                     aclk;
  int                     arst;
} s_axi_glb_t;

typedef struct  {
  // Write Addr channel
  int                     awready;
  // Write Data channel
  int                     wready;
  // Write Response channel
  int                     bid;
  aerror_t                bresp;
  int                     buser;
  int                     bvalid;
  // Read addr channel
  int                     arready;
  // Read data channel
  int                     rid;
  int                     rdata;
  aerror_t                rresp;
  int                     rlast;
  int                     ruser;
  int                     rvalid;
} s_axi_miso_t;

typedef struct  {
  // Write Address channel
  int                     awid;
  axi_addr_t              awaddr;
  int                     awlen;
  asize_t                 awsize;
  aburst_t                awburst;
  int                     awlock;
  int                     awcache;
  int                     awprot;
  int                     awqos;
  int                     awregion;
  int                     awuser;
  int                     awvalid;
  // Write Data channel
  int                     wid;
  int                     wdata;
  int                     wstrb;
  int                     wlast;
  int                     wuser;
  int                     wvalid;
  // Write Response channel
  int                     bready;
  // Read Address channel
  int                     arid;
  axi_addr_t              araddr;
  int                     arlen;
  asize_t                 arsize;
  aburst_t                arburst;
  int                     arlock;
  int                     arcache;
  int                     arprot;
  int                     arqos;
  int                     arregion;
  int                     aruser;
  int                     arvalid;
  // Read Data channel
  int                     rready;
} s_axi_mosi_t;

#endif
