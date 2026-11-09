module write_pointer #(
  parameter ADDR_WIDTH = 4
)(
  input  logic                  wr_clk,
  input  logic                  wr_rst,
  input  logic                  wr_inc,
  input  logic [ADDR_WIDTH:0]   rd_ptr_sync,   // Gray read pointer, synchronized

  output logic                  wr_full,
  output logic [ADDR_WIDTH:0]   wr_ptr,        // Gray write pointer
  output logic [ADDR_WIDTH-1:0] wr_addr
);

  logic [ADDR_WIDTH:0] wr_bin, wr_bin_next, wr_gptr_next;
  logic                wr_full_val;

  always_ff @(posedge wr_clk or posedge wr_rst) begin
    if (wr_rst) begin
      wr_bin  <= '0;
      wr_ptr  <= '0;
      wr_full <= 1'b0;
    end else begin
      wr_bin  <= wr_bin_next;
      wr_ptr  <= wr_gptr_next;
      wr_full <= wr_full_val;
    end
  end

  assign wr_bin_next  = (wr_inc && !wr_full) ? (wr_bin + 1'b1) : wr_bin;
  assign wr_addr      = wr_bin[ADDR_WIDTH-1:0];
  assign wr_gptr_next = wr_bin_next ^ (wr_bin_next >> 1);

  // Full: next write pointer equals read pointer with top two bits inverted
  assign wr_full_val  = (wr_gptr_next ==
                         {~rd_ptr_sync[ADDR_WIDTH:ADDR_WIDTH-1],
                           rd_ptr_sync[ADDR_WIDTH-2:0]});

endmodule
