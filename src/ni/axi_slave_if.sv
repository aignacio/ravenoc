/**
 * File: axi_slave_if.sv
 * Description: AXI Slave interface to receive requests from the
 *              PE.
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
module axi_slave_if import ravenoc_pkg::*; (
  input   s_axi_glb_t       axi_global,

  // AXI I/F with PE
  input   s_axi_mosi_t      axi_mosi_if,
  output  s_axi_miso_t      axi_miso_if,

  // Interface with the Packet Generator
  // AXI Slave -> Pkt Gen
  output  s_pkt_gen_req_t   pkt_out_req,
  input   s_pkt_gen_resp_t  pkt_out_resp,

  // AXI Salve <- Pkt Gen
  input   s_pkt_in_req_t    pkt_in_req,
  output  s_pkt_in_resp_t   pkt_in_resp
);
  // FIFO variables
  logic                       write_data;
  logic                       full;
  logic                       empty;
  logic [`AXI_DATA_WIDTH-1:0] data_fifo_out;

  // AXI Variables
  logic [4:0]                 ot_wr_cnt_ff;
  logic [4:0]                 ot_rd_cnt_ff;
  logic [4:0]                 next_ot_wr_cnt;
  logic [4:0]                 next_ot_rd_cnt;

  // Functions
  function automatic s_noc_addr_t axi_dec_noc(logic [`AXI_ADDR_WIDTH-1:0] axi_addr);
    s_noc_addr_t noc_addr;
    noc_addr.x_dest = x_width_t'('0);
    noc_addr.y_dest = y_width_t'('0);
    noc_addr.invalid = '1;
    for (int i=0;i<(NOC_SIZE-1);i++) begin
      if (axi_addr >= noc_addr_map[`ADDR_BASE][i] && axi_addr <= noc_addr_map[`ADDR_UPPER][i]) begin
        noc_addr.x_dest  = x_width_t'(noc_addr_map[`X_ADDR][i]);
        noc_addr.y_dest  = y_width_t'(noc_addr_map[`Y_ADDR][i]);
        noc_addr.invalid = '0;
      end
    end

    return noc_addr;
  endfunction

  always_comb begin
    next_ot_wr_cnt = ot_wr_cnt_ff;
    next_ot_rd_cnt = ot_rd_cnt_ff;
  end

  always_ff @ (posedge axi_global.aclk or negedge axi_global.arstn) begin
    if (~axi_global.arstn) begin
      ot_wr_cnt_ff <= '0;
      ot_rd_cnt_ff <= '0;
    end
    else begin
      ot_wr_cnt_ff <= next_ot_wr_cnt;
      ot_rd_cnt_ff <= next_ot_rd_cnt;
    end
  end

  always_comb begin : addr_ch_handshake
    axi_miso_if = s_axi_miso_t'('0);
  end

  //***************************
  // Outstanding TXN buffers
  //***************************
  //fifo # (
    //.SLOTS(`AXI_MAX_OUTSTD_RD),
    //.WIDTH(color o tamanho do noc_size+setup de txn)
  //) u_fifo_axi_ot_rd (
    //.clk      (axi_global.aclk),
    //.arst     (~axi_global.aresetn),
    //.write_i  (),
    //.read_i   (),
    //.data_i   (),
    //.data_o   (),
    //.full_o   (),
    //.empty_o  ()
  //);

  ///[>**************************
  //// FIFO buffer
  ///[>**************************
  //always_comb begin : drive_read_fifo
    //write_data = ~full && pkt_in_req.valid;
    //pkt_in_resp.ready = ~full;
  //end

  //fifo # (
    //.SLOTS(`AXI_RD_BUFFER_SIZE/(`AXI_DATA_WIDTH/8)),
    //.WIDTH(`AXI_DATA_WIDTH)
  //) u_fifo_read_pkt (
    //.clk      (axi_global.aclk),
    //.arst     (~axi_global.aresetn),
    //.write_i  (write_data),
    //.read_i   ('0),
    //.data_i   (pkt_in_req.flit_data),
    //.data_o   (data_fifo_out),
    //.full_o   (full),
    //.empty_o  (empty)
  //);
endmodule
