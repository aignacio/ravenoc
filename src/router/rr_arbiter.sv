/**
 * File: rr_arbiter.sv
 * Description: Round-Robin Arbiter
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
module rr_arbiter #(
  parameter int N_OF_INPUTS = 2
)(
  input                           clk,
  input                           arst,
  input                           update_i,
  input         [N_OF_INPUTS-1:0] req_i,
  output  logic [N_OF_INPUTS-1:0] grant_o
);
  logic [N_OF_INPUTS-1:0] mask_ff;
  logic [N_OF_INPUTS-1:0] next_mask;
  logic [N_OF_INPUTS-1:0] mask_req;
  logic [N_OF_INPUTS-1:0] raw_grant;
  logic [N_OF_INPUTS-1:0] masked_grant;

  high_prior_arbiter#(
    .N_OF_INPUTS(N_OF_INPUTS)
  ) u_high_p_arb_raw (
    .req_i  (req_i),
    .grant_o(raw_grant)
  );

  high_prior_arbiter#(
    .N_OF_INPUTS(N_OF_INPUTS)
  ) u_high_p_arb_masked (
    .req_i  (mask_req),
    .grant_o(masked_grant)
  );

  always_comb begin
    mask_req = mask_ff & req_i;
    next_mask = mask_ff;

    grant_o = mask_req == '0 ? raw_grant : masked_grant;

    //if (update_i) begin
      for (int i=0;i<N_OF_INPUTS;i++) begin
        if (grant_o[i[$clog2(N_OF_INPUTS)-1:0]]) begin
          next_mask = '0;
          for (int j=i+1;j<N_OF_INPUTS;j++)
            next_mask[j[$clog2(N_OF_INPUTS)-1:0]] = 1'b1;
          break;
        end
      end
    //end
  end

  always_ff @ (posedge clk or posedge arst) begin
    if (arst) begin
      mask_ff <= '1;
    end
    else begin
      mask_ff <= update_i ? next_mask : mask_ff;
    end
  end
endmodule : rr_arbiter


