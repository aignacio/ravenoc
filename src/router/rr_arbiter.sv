/**
 * File: rr_arbiter.sv
 * Description: Round-Robin Arbiter
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
module rr_arbiter #(
  parameter int N_OF_INPUTS = 2
)(
  input                           clk,
  input                           arst,
  input                           update_i,
  input         [N_OF_INPUTS-1:0] req_i,
  output  logic [N_OF_INPUTS-1:0] grant_o
);
  logic [N_OF_INPUTS-1:0] mask_ff, next_mask;
  logic [N_OF_INPUTS-1:0] grant_ff, next_grant;

  always_comb begin
    next_mask  = mask_ff;
    next_grant = grant_ff;
    grant_o    = grant_ff;

    // We only check the inputs during the update == 1
    if (update_i) begin
      next_grant = '0;

      // Checking each master against the mask
      for (int i=0; i<N_OF_INPUTS; i++) begin
        if (req_i[i] && mask_ff[i]) begin
          next_grant[i] = 1'b1;
          next_mask[i]  = 1'b0;
          break;
        end
      end

      // If all masters were served
      if ((mask_ff & req_i) == '0) begin
        next_mask = '1;
        for (int i=(N_OF_INPUTS-1); i>=0; i--) begin
          if (req_i[i] == 1'b1) begin
            next_grant[i] = 1'b1;
            next_mask[i]  = 1'b0;
            break;
          end
        end
      end
    end
  end

  always_ff @ (posedge clk or posedge arst) begin
    if (arst) begin
      mask_ff  <= '1;
      grant_ff <= '0;
    end
    else begin
      mask_ff  <= next_mask;
      grant_ff <= next_grant;
    end
  end
endmodule
