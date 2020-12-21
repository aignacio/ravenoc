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
  output  s_pkt_out_req_t   pkt_out_req,
  input   s_pkt_out_resp_t  pkt_out_resp,

  // AXI Salve <- Pkt Gen
  input   s_pkt_in_req_t    pkt_in_req,
  output  s_pkt_in_resp_t   pkt_in_resp
);
  localparam OT_FIFO_WIDTH = 2+8+16;

  // AXI Variables
  logic                                       vld_axi_txn_wr;
  logic                                       vld_axi_txn_rd;

  // WRITE signals
  logic                                       fifo_wr_req_empty;
  logic                                       fifo_wr_req_full;
  logic                                       write_wr;
  logic                                       read_wr;
  s_ot_fifo_t                                 in_fifo_wr_data;
  s_ot_fifo_t                                 out_fifo_wr_data;
  logic                                       head_flit_ff;
  logic                                       next_head_flit;
  logic                                       bresp_ff;
  logic                                       next_bresp;
  s_axi_mm_dec_t                              decode_req_wr;
  logic                                       ready_from_in_buff;


  // READ signals
  logic [N_VIRT_CHN-1:0]                      full_rd_arr;
  logic [N_VIRT_CHN-1:0]                      empty_rd_arr;
  logic [N_VIRT_CHN-1:0]                      write_rd_arr;
  logic [N_VIRT_CHN-1:0]                      read_rd_arr;
  logic [N_VIRT_CHN-1:0][`AXI_DATA_WIDTH-1:0] data_rd_buff;
  logic [`AXI_DATA_WIDTH-1:0]                 data_rd_sel;
  logic                                       fifo_rd_req_empty;
  logic                                       fifo_rd_req_full;
  logic                                       write_rd;
  logic                                       read_rd;
  s_ot_fifo_t                                 in_fifo_rd_data;
  s_ot_fifo_t                                 out_fifo_rd_data;
  s_axi_mm_dec_t                              decode_req_rd;
  logic [`AXI_ALEN_WIDTH:0]                   beat_count_ff;
  logic [`AXI_ALEN_WIDTH:0]                   next_beat_count;
  logic                                       txn_rd_ff;
  logic                                       next_txn_rd;
  logic                                       data_rvalid;
  logic                                       read_txn_done;

  // **************************
  // Main AXI functions
  // **************************
  //function automatic s_noc_addr_t axi_dec_noc(logic [`AXI_ADDR_WIDTH-1:0] axi_addr);
    //s_noc_addr_t noc_addr;
    //noc_addr.x_dest = x_width_t'('0);
    //noc_addr.y_dest = y_width_t'('0);
    //noc_addr.invalid = '1;
    //for (int i=0;i<(NOC_SIZE-1);i++) begin
      //if (axi_addr >= noc_addr_map[`ADDR_BASE][i] && axi_addr <= noc_addr_map[`ADDR_UPPER][i]) begin
        //noc_addr.x_dest  = x_width_t'(noc_addr_map[`X_ADDR][i]);
        //noc_addr.y_dest  = y_width_t'(noc_addr_map[`Y_ADDR][i]);
        //noc_addr.invalid = '0;
      //end
    //end
    //return noc_addr;
  //endfunction

  function automatic s_axi_mm_dec_t check_mm_req (axi_addr_t addr);
    s_axi_mm_dec_t req;
    req.virt_chn_id = '0;
    req.region = NONE;

    for (int i=0;i<N_VIRT_CHN;i++) begin
      if (addr == AXI_WR_BFF_FLIT[i]) begin
        req.virt_chn_id = i[VC_WIDTH-1:0];
        req.region = NOC_WR_FIFOS;
      end
      else if (addr == AXI_RD_BFF_FLIT[i]) begin
        req.virt_chn_id = i[VC_WIDTH-1:0];
        req.region = NOC_RD_FIFOS;
      end
    end

    for (int i=0;i<`N_CSR_REGS;i++) begin
      if (addr == AXI_CSR[i]) begin
        req.region = NOC_CSR;
      end
    end
  endfunction

  always_comb begin : axi_protocol_handshake
    axi_miso_if = s_axi_miso_t'('0);
    pkt_out_req = s_pkt_out_req_t'('0);

    // ----------------------------------
    // WRITE AXI CHANNEL (ADDR+DATA+RESP)
    // ----------------------------------
    // We define the write channel availability based
    // on size of outstanding txns in the wr fifo
    axi_miso_if.awready = ~fifo_wr_req_full;
    vld_axi_txn_wr = axi_mosi_if.awvalid &&
                     axi_miso_if.awready;
    // We translate the last req. in the OT fifo to get the address space + virtual channel ID (if applicable)
    decode_req_wr = check_mm_req({16'h0,out_fifo_wr_data.addr});
    // Pkg generator must know if it's a new packet or not, so we generate this
    // every time we starting sending the burst
    next_head_flit = (axi_mosi_if.wlast && axi_miso_if.wready) ? axi_mosi_if.wlast : head_flit_ff;
    if (~fifo_wr_req_empty) begin
      unique case(decode_req_wr.region)
        NOC_WR_FIFOS: begin
          pkt_out_req.vc_id   = decode_req_wr.virt_chn_id;
          pkt_out_req.req_new = head_flit_ff;
          /* verilator lint_off WIDTH */
          pkt_out_req.pkt_sz  = out_fifo_wr_data.alen == 'h0 ? (2**out_fifo_wr_data.asize) :
                                                               (out_fifo_wr_data.alen+'h1)*(`AXI_DATA_WIDTH/8);
          /* verilator lint_on WIDTH */
          ready_from_in_buff = pkt_out_resp.ready;
          if (axi_mosi_if.wvalid) begin
            pkt_out_req.valid     = 1;
            pkt_out_req.flit_data = axi_mosi_if.wdata;
          end
        end
        NOC_CSR: begin
        end
        NOC_RD_FIFOS:  assert (0) else $error("[AXI_SLAVE] It should not decode a read op. in this fifo!");
        default:  ready_from_in_buff = 'h1;
      endcase
    end
    // When sending the flit, our availability is based on input buffer fifo
    // if the req fifo is empty is means that master has transferred all
    axi_miso_if.wready = fifo_wr_req_empty ? '1 : ready_from_in_buff;
    // We send a write response right after we finished the write
    // it's not implemented error handling on this channel
    axi_miso_if.bvalid = bresp_ff;
    // We stop sending bvalid when the master accept it
    next_bresp = bresp_ff ? ~axi_mosi_if.bready : axi_mosi_if.wvalid && axi_mosi_if.wlast && axi_miso_if.wready;

    // ----------------------------------
    // READ AXI CHANNEL (ADDR+DATA)
    // ----------------------------------
    axi_miso_if.arready = ~fifo_rd_req_full;
    vld_axi_txn_rd = axi_mosi_if.arvalid &&
                     axi_miso_if.arready;
    decode_req_rd = check_mm_req({16'h0,out_fifo_rd_data.addr})

    next_txn_rd = '0;
    next_beat_count = '0;

    if (next_txn_rd) begin
      axi_miso_if.rvalid = data_rvalid;
      axi_miso_if.rdata = data_rvalid ? data_rd_sel;
    end

    if ((beat_count_ff == out_fifo_rd_data.alen) && (axi_miso_if.rvalid)) begin
      axi_miso_if.rlast = axi_miso_if.rvalid;
    end

    read_txn_done = axi_mosi_if.rready && axi_miso_if.rvalid;

    if (~fifo_rd_req_empty) begin
      unique case(decode_req_wr.region)
        NOC_WR_FIFOS: assert (0) else $error("[AXI_SLAVE] It should not decode a write op. in this fifo!");
        NOC_CSR: begin
        end
        NOC_RD_FIFOS: begin
          if (~txn_rd_ff) begin
            next_txn_rd = '1;
            next_beat_count = 'd0;
          end
          else begin
            if (beat_count_ff < out_fifo_rd_data.alen)
              next_beat_count = beat_count_ff + (read_txn_done ? 'd1 : 'd0);
            else
              next_beat_count = beat_count_ff;

            if (read_txn_done && beat_count_ff == out_fifo_rd_data.alen)
              next_txn_rd = '0;
            else
              next_txn_rd = '1;
          end
        end
        default: next_txn_rd = '0;
      endcase
    end
  end

  // **************************
  //
  // Write AXI
  //
  // **************************
  // In the case of a WRITE, master will
  // write in the input buffers depending
  // the virtual channel availability
  always_ff @ (posedge axi_global.aclk or posedge axi_global.arst) begin
    if (axi_global.arst) begin
      head_flit_ff <= '1;
      bresp_ff     <= '0;
    end
    else begin
      head_flit_ff <= next_head_flit;
      bresp_ff     <= next_bresp;
    end
  end

  always_comb begin : ctrl_fifo_ot_write
    // Address channel fifo frame
    // ----------------------------------------------------
    // | axi.awsize[1:0] | axi.alen[7:0] | axi.addr[15:0] |
    // ----------------------------------------------------
    in_fifo_wr_data.addr  = axi_mosi_if.araddr[15:0];
    in_fifo_wr_data.alen  = axi_mosi_if.arlen;
    in_fifo_wr_data.asize = axi_mosi_if.arsize[1:0];
    write_wr = vld_axi_txn_wr;
    read_wr  = ~fifo_wr_req_empty &&
               axi_mosi_if.wvalid  &&
               axi_mosi_if.wlast   &&
               pkt_out_resp.ready;
  end

  // **************************
  // Outstanding WR TXN buffers
  // **************************
  fifo # (
    .SLOTS(`AXI_MAX_OUTSTD_WR),
    .WIDTH(OT_FIFO_WIDTH)
  ) u_fifo_axi_ot_wr (
    .clk      (axi_global.aclk),
    .arst     (axi_global.arst),
    .write_i  (write_wr),
    .read_i   (read_wr),
    .data_i   (in_fifo_wr_data),
    .data_o   (out_fifo_wr_data),
    .full_o   (fifo_wr_req_full),
    .empty_o  (fifo_wr_req_empty),
    .error_o  ()
  );

  // **************************
  //
  // Read AXI
  //
  // **************************
  always_comb begin : ctrl_fifo_ot_read
    // Address channel fifo frame
    // ----------------------------------------------------
    // | axi.awsize[1:0] | axi.alen[7:0] | axi.addr[15:0] |
    // ----------------------------------------------------
    in_fifo_rd_data.addr  = axi_mosi_if.araddr[15:0];
    in_fifo_rd_data.alen  = axi_mosi_if.arlen;
    in_fifo_rd_data.asize = axi_mosi_if.arsize[1:0];
    write_rd = vld_axi_txn_rd;
    read_rd  = ~fifo_rd_req_empty &&
               read_txn_done      &&
               axi_miso_if.rlast;

  end

  always_ff @ (posedge axi_global.aclk or posedge axi_global.arst) begin
    if (axi_global.arst) begin
      beat_count_ff <= '0;
      txn_rd_ff <= '0;
    end
    else begin
      beat_count_ff <= next_beat_count;
      txn_rd_ff <= next_txn_rd;
    end
  end

  // **************************
  // Outstanding RD TXN buffers
  // **************************
  // In the case of a READ, master will
  // read from one of the buffers of a virtual
  // channel, this means we need to store only
  // which virtual ch he wants to read and how many
  // bytes of the txn
  fifo # (
    .SLOTS(`AXI_MAX_OUTSTD_RD),
    .WIDTH(OT_FIFO_WIDTH)
  ) u_fifo_axi_ot_rd (
    .clk      (axi_global.aclk),
    .arst     (axi_global.arst),
    .write_i  (write_rd),
    .read_i   (read_rd),
    .data_i   (in_fifo_rd_data),
    .data_o   (out_fifo_rd_data),
    .full_o   (fifo_rd_req_full),
    .error_o  (),
    .empty_o  (fifo_rd_req_empty)
  );

  always_comb begin : ctrl_rx_buffers
    write_rd_arr  = '0;
    read_rd_arr   = '0;
    pkt_in_resp   = s_pkt_in_resp_t'('0);
    data_rd_buff  = '0;
    data_rd_sel   = '0;
    data_rvalid   = '0;
    pkt_in_resp.ready = ~full_rd_arr[pkt_in_req.rq_vc];

    for (int i=0;i<N_VIRT_CHN;i++) begin
      write_rd_arr[i] = (pkt_in_req.rq_vc == i[VC_WIDTH-1:0]) &&
                        (pkt_in_req.valid)                    &&
                        ~full_rd_arr[i];
    end

    for (int i=0;i<N_VIRT_CHN;i++) begin
      if (txn_rd_ff && (i[VC_WIDTH-1:0] == decode_req_rd.virt_chn_id) && ~empty_rd_arr[i]) begin
        read_rd_arr[i] = axi_mosi_if.rready;
        data_rd_sel = data_rd_buff[i];
        data_rvalid = '1;
        break;
      end
    end
  end

  // **************************
  // [BUFFERs] Read buff of packets
  // **************************
  // Here are the instances of all buffers
  // that'll store the packets temporarily
  genvar buff_idx;
  generate
    for (buff_idx=0; buff_idx<N_VIRT_CHN-1; buff_idx++) begin : rx_vc_buffer
      fifo # (
        .SLOTS(AXI_RD_SZ_ARR[buff_idx]),
        .WIDTH(FLIT_WIDTH-FLIT_TP_WIDTH)
      ) u_vc_buffer (
        .clk      (axi_global.aclk),
        .arst     (axi_global.arst),
        .write_i  (write_rd_arr[buff_idx]),
        .read_i   (read_rd_arr[buff_idx]),
        .data_i   (pkt_in_req.flit_data),
        .data_o   (data_rd_buff[buff_idx]),
        .full_o   (full_rd_arr[buff_idx]),
        .error_o  (),
        .empty_o  (empty_rd_arr[buff_idx])
      );
    end
  endgenerate
endmodule
