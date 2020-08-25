/**
 * File: ravenoc.sv
 * Description: RaveNoC top module
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
module ravenoc # (
  parameter SLOTS = 10,
  parameter WIDTH = 34
)(
  input                     clk,
  input                     arst,
  input                     write_i,
  input                     read_i,
  input         [WIDTH-1:0] data_i,
  output  logic [WIDTH-1:0] data_o,
  output  logic             error_o,
  output  logic             full_o,
  output  logic             empty_o
);

  fifo # (
    .SLOTS(SLOTS),
    .WIDTH(WIDTH)
  ) u_fifo (
    .clk(clk),
    .arst(arst),
    .write_i(write_i),
    .read_i(read_i),
    .data_i(data_i),
    .data_o(data_o),
    .error_o(error_),
    .full_o(full_o),
    .empty_o(empty_o)
  );
endmodule
