`ifndef _RAVENOC_AXI_FNC_
  `define _RAVENOC_AXI_FNC_
  function automatic logic valid_op_size(axi_addr_t addr, axi_size_t asize);
    logic csr, buff, valid;

    csr = '0;
    buff = '0;
    valid = '0;

    for (int i=0;i<NumVirtChn;i++) begin
      if (addr == `AXI_WR_BFF_CHN(i) || addr == `AXI_RD_BFF_CHN(i)) begin
        buff = 1;
      end
    end

    for (int i=0;i<`N_CSR_REGS+`N_VIRT_CHN;i++) begin
      if (addr == `AXI_CSR_REG(i)) begin
        csr = 1;
      end
    end

    if (buff && (asize == ((`AXI_DATA_WIDTH == 32) ? AXI_WORD : AXI_DWORD))) begin
      valid = 'h1;
    end

    if (csr && (asize == AXI_WORD)) begin
      valid = 'h1;
    end

    return valid;
  endfunction

  function automatic logic valid_addr_rd(axi_addr_t addr,logic [NumVirtChn-1:0] empty_rd_arr);
    logic valid;

    valid = 0;

    for (int i=0;i<NumVirtChn;i++) begin
      if (addr == `AXI_RD_BFF_CHN(i)) begin
        valid = 1'b1; // Previously we were using this ~empty_rd_arr[i]; but now with mult. burst read, that's not needed
      end
    end

    for (int i=0;i<`N_CSR_REGS+`N_VIRT_CHN;i++) begin
      if (addr == `AXI_CSR_REG(i)) begin
        valid = 1;
      end
    end

    return valid;
  endfunction

  function automatic logic valid_addr_wr(axi_addr_t addr);
    logic valid;

    valid = 0;

    for (int i=0;i<NumVirtChn;i++) begin
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

    /* verilator lint_off WIDTH */
    for (int i=0;i<NumVirtChn;i++) begin
      if (addr == (`AXI_WR_BFF_CHN(i) & 16'hFFFF)) begin
        req.virt_chn_id = i[VcWidth-1:0];
        req.region = NOC_WR_FIFOS;
      end
      else if (addr == (`AXI_RD_BFF_CHN(i) & 16'hFFFF)) begin
        req.virt_chn_id = i[VcWidth-1:0];
        req.region = NOC_RD_FIFOS;
      end
    end

    for (int i=0;i<`N_CSR_REGS+`N_VIRT_CHN;i++) begin
      if (addr == (`AXI_CSR_REG(i) & 16'hFFFF)) begin
        req.region = NOC_CSR;
      end
    end

    /* verilator lint_on WIDTH */
    return req;
  endfunction
`endif
