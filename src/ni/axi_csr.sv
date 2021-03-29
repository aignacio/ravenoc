/**
 * File: axi_csr.sv
 * Description: All the NoC CSRs
 * Author: Anderson Ignacio da Silva <aignacio@aignacio.com>
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
module axi_csr import ravenoc_pkg::*; # (
  parameter ROUTER_X_ID = 0,
  parameter ROUTER_Y_ID = 0,
  parameter CDC_REQUIRED = 1
) (
  input                               clk_axi,
  input                               arst_axi,
  // Custom I/F just to exchange data
  //input   [1:0]                     size_op, // 0 - Byte, 1 - half-word, 2 - word, 3 - dword
  input                               rd_or_wr,
  input                               valid,
  output  logic                       ready,
  input   [15:0]                      addr,
  input   [`AXI_DATA_WIDTH-1:0]       data_in,
  output  logic [`AXI_DATA_WIDTH-1:0] data_out,
  output  logic                       error
  // Additional inputs
  // Additional outputs
);
  logic error_ff;
  logic next_error;
  logic [`AXI_DATA_WIDTH-1:0] mux_out_ff;
  logic [`AXI_DATA_WIDTH-1:0] next_mux_out;
  logic [`AXI_DATA_WIDTH-1:0] decoded_data;

  always_comb begin : wireup_csr
    next_error = error_ff;
    next_mux_out = '0;
    error = error_ff;
  end

  always_comb begin : csr_decoder_r
    ready = 1'b1;
    decoded_data = '0;

    unique case(addr)
      RAVENOC_VERSION: decoded_data = RAVENOC_LABEL;
      ROUTER_ROW_X_ID: decoded_data = ROUTER_X_ID;
      ROUTER_Y_ID:     decoded_data = ROUTER_Y_ID;
      default:  decoded_data = '0;
    endcase

    next_mux_out = (valid && (rd_or_wr==1'b0)) ? decoded_data : '0;
    data_out = mux_out_ff;
  end

  always_ff @ (posedge clk_axi or posedge arst_axi) begin
    if (arst_axi) begin
      error_ff <= '0;
      mux_out_ff <= '0;
    end
    else begin
      error_ff <= next_error;
      mux_out_ff <= next_mux_out;
    end
  end
endmodule
