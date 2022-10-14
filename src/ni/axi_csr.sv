/**
 * File: axi_csr.sv
 * Description: All the NoC CSRs
 * Author: Anderson Ignacio da Silva <anderson@aignacio.com>
 *
 * MIT License
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
module axi_csr
  import amba_axi_pkg::*;
  import ravenoc_pkg::*;
#(
  parameter logic [XWidth-1:0] ROUTER_X_ID = 0,
  parameter logic [YWidth-1:0] ROUTER_Y_ID = 0,
  parameter bit                CDC_REQUIRED = 1
) (
  input                                   clk_axi,
  input                                   arst_axi,
  // Custom I/F just to exchange data
  input   s_csr_req_t                     csr_req_i,
  output  s_csr_resp_t                    csr_resp_o,
  // Additional inputs
  input   [NumVirtChn-1:0]                empty_rd_bff_i,
  input   [NumVirtChn-1:0]                full_rd_bff_i,
  input   [NumVirtChn-1:0][15:0]          fifo_ocup_rd_bff_i,
  input   [NumVirtChn-1:0][PktWidth-1:0]  pkt_size_vc_i,
  // Additional outputs
  output  s_irq_ni_t                      irqs_out_o
);
  logic error_ff, error_rd, error_wr, next_error;
  logic [31:0] decoded_data;
  s_irq_ni_mux_t irq_mux;
  logic [31:0] mux_out_ff, next_mux_out;
  s_irq_ni_mux_t irq_mux_ff, next_irq_mux;
  logic [31:0] irq_mask_ff, next_irq_mask;

  always_comb begin : wireup_csr
    next_error = error_rd;
    csr_resp_o.ready    = 1'b1;
    csr_resp_o.error    = error_ff || error_wr; // We need to pull the write error
                                                // to register on b-chn
    csr_resp_o.data_out = mux_out_ff;
  end

  always_comb begin : csr_decoder_w
    error_wr = '0;
    next_irq_mux = irq_mux_ff;
    next_irq_mask = irq_mask_ff;

    if (csr_req_i.valid && csr_req_i.rd_or_wr) begin
      /* verilator lint_off WIDTH */
      unique case(csr_req_i.addr-(`AXI_CSR_BASE_ADDR & 16'hFFFF))
        RAVENOC_VERSION:  error_wr = 'h1;
        ROUTER_ROW_X_ID:  error_wr = 'h1;
        ROUTER_COL_Y_ID:  error_wr = 'h1;
        IRQ_RD_STATUS:    error_wr = 'h1;
        IRQ_RD_MUX:       next_irq_mux  = s_irq_ni_mux_t'(csr_req_i.data_in);
        IRQ_RD_MASK:      next_irq_mask = csr_req_i.data_in;
        default:          error_wr = 'h1;
      endcase
      /* verilator lint_on WIDTH */
    end
  end

  always_comb begin : csr_decoder_r
    error_rd = '0;
    decoded_data = mux_out_ff;

    if (csr_req_i.valid && ~csr_req_i.rd_or_wr) begin
      /* verilator lint_off WIDTH */
      unique case(csr_req_i.addr-(`AXI_CSR_BASE_ADDR & 16'hFFFF))
        RAVENOC_VERSION:  decoded_data = RavenocLabel;
        ROUTER_ROW_X_ID:  decoded_data = ROUTER_X_ID;
        ROUTER_COL_Y_ID:  decoded_data = ROUTER_Y_ID;
        IRQ_RD_STATUS:    decoded_data = irqs_out_o.irq_vcs;
        IRQ_RD_MUX:       decoded_data = irq_mux_ff;
        IRQ_RD_MASK:      decoded_data = irq_mask_ff;
        default: begin
          error_rd = 'h1;
          for(int i=0;i<NumVirtChn;i++) begin
            if ((csr_req_i.addr-(`AXI_CSR_BASE_ADDR & 16'hFFFF)) == `RD_SIZE_VC_PKT(i)) begin
              decoded_data = pkt_size_vc_i[i];
              error_rd = '0;
            end
          end
        end
      endcase
      /* verilator lint_on WIDTH */
    end

    next_mux_out = decoded_data;
  end

  always_comb begin : irq_handling
    irqs_out_o = s_irq_ni_t'('0);
    /* verilator lint_off WIDTH */
    irq_mux = irq_mux_ff; // Casting
    unique case(irq_mux)
      DEFAULT: begin
        for (int i=0;i<NumVirtChn;i++) begin
          irqs_out_o.irq_vcs[i] = ~empty_rd_bff_i[i];
        end
      end
      MUX_EMPTY_FLAGS: begin
        for (int i=0;i<NumVirtChn;i++) begin
          irqs_out_o.irq_vcs[i] = ~empty_rd_bff_i[i] & irq_mask_ff;
        end
      end
      MUX_FULL_FLAGS: begin
        for (int i=0;i<NumVirtChn;i++) begin
          irqs_out_o.irq_vcs[i] = full_rd_bff_i[i] & irq_mask_ff;
        end
      end
      MUX_COMP_FLAGS: begin
        for (int i=0;i<NumVirtChn;i++) begin
          irqs_out_o.irq_vcs[i] = (fifo_ocup_rd_bff_i[i] >= irq_mask_ff);
        end
      end
      default: begin
        for (int i=0;i<NumVirtChn;i++) begin
          irqs_out_o.irq_vcs[i] = ~empty_rd_bff_i[i];
        end
      end
    endcase
    /* verilator lint_on WIDTH */

    irqs_out_o.irq_trig = |irqs_out_o.irq_vcs;
  end

  always_ff @ (posedge clk_axi or posedge arst_axi) begin
    if (arst_axi) begin
      error_ff    <= '0;
      mux_out_ff  <= '0;
      irq_mux_ff  <= s_irq_ni_mux_t'('0);
      irq_mask_ff <= '1;
    end
    else begin
      error_ff    <= next_error;
      mux_out_ff  <= next_mux_out;
      irq_mux_ff  <= next_irq_mux;
      irq_mask_ff <= next_irq_mask;
    end
  end
endmodule
