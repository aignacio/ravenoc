`ifndef _ravenoc_axi_fnc_
  `define _ravenoc_axi_fnc_
  //`include "ravenoc_axi_structs.svh"

  function automatic logic valid_addr_rd(axi_addr_t addr,logic [N_VIRT_CHN-1:0] empty_rd_arr);
    logic valid;

    valid = 0;

    for (int i=0;i<N_VIRT_CHN;i++) begin
      if (addr == `AXI_RD_BFF_CHN(i)) begin
        valid = ~empty_rd_arr[i];
      end
    end

    for (int i=0;i<`N_CSR_REGS;i++) begin
      if (addr == `AXI_CSR_REG(i)) begin
        valid = 1;
      end
    end

    return valid;
  endfunction

  function automatic logic valid_addr_wr(axi_addr_t addr);
    logic valid;

    valid = 0;

    for (int i=0;i<N_VIRT_CHN;i++) begin
      if (addr == `AXI_WR_BFF_CHN(i)) begin
        valid = 1;
      end
    end

    for (int i=0;i<`N_CSR_REGS;i++) begin
      if (addr == `AXI_CSR_REG(i)) begin
        valid = 1;
      end
    end

    return valid;
  endfunction

  function automatic s_axi_mm_dec_t check_mm_req(axi_addr_t addr);
    s_axi_mm_dec_t req;
    req.virt_chn_id = '0;
    req.region = NONE;

    for (int i=0;i<N_VIRT_CHN;i++) begin
      if (addr == `AXI_WR_BFF_CHN(i)) begin
        req.virt_chn_id = i[VC_WIDTH-1:0];
        req.region = NOC_WR_FIFOS;
      end
      else if (addr == `AXI_RD_BFF_CHN(i)) begin
        req.virt_chn_id = i[VC_WIDTH-1:0];
        req.region = NOC_RD_FIFOS;
      end
    end

    for (int i=0;i<`N_CSR_REGS;i++) begin
      if (addr == `AXI_CSR_REG(i)) begin
        req.region = NOC_CSR;
      end
    end

    return req;
  endfunction
`endif
