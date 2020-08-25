/**
 * File: vc_ctrl.sv
 * Description: Virtual Channel Controller
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
module vc_ctrl import ravenoc_pkg::*; # (
  parameter VC_ID = 0
)(
  input   clk,
  input   arst,
  // Input interface - from external input module
  input   in_valid,
  output  in_ready,
  // Output Interface - to Router Ctrl
  output  out_valid,
  input   out_ready,
  output  s_test_t saida
);
  assign saida = 0;
/*
  fifo # (
    .SLOTS(SLOTS),
    .WIDTH(WIDTH)
  )(
    clk(),
    arst(),
    write_i,(),
    read_i,(),
    data_i,(),
    data_o,(),
    error_o(),
    full_o(),
    empty_o()
  );
*/
endmodule
