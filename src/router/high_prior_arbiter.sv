/**
 * File: high_prior_arbiter.sv
 * Description: High priority Arbiter
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
/*verilator coverage_off*/
module high_prior_arbiter # (
  parameter int N_OF_INPUTS = 2
) (
  input         [N_OF_INPUTS-1:0] req_i,
  output  logic [N_OF_INPUTS-1:0] grant_o
);
  always_comb begin
    grant_o = '0;

    for (int i=0;i<N_OF_INPUTS;i++) begin
      if (req_i[i[$clog2(N_OF_INPUTS)-1:0]]) begin
        grant_o = 1<<i[$clog2(N_OF_INPUTS)-1:0];
        break;
      end
    end
  end
endmodule : high_prior_arbiter
/*verilator coverage_on*/
