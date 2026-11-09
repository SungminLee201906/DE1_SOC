module read_pointer #(
  parameter ADDR_WIDTH = 4
)(
  input  logic                  rd_clk,
  input  logic                  rd_rst,
  input  logic                  rd_inc,
  input  logic [ADDR_WIDTH:0]   wr_ptr_sync,   // Gray write pointer, synchronized

  output logic                  rd_empty,
  output logic [ADDR_WIDTH:0]   rd_ptr,        // Gray read pointer
  output logic [ADDR_WIDTH-1:0] rd_addr
);

  logic [ADDR_WIDTH:0] rd_bin, rd_bin_next, rd_gptr_next;
  logic                rd_empty_val;

  always_ff @(posedge rd_clk or posedge rd_rst) begin
    if (rd_rst) begin
      rd_bin   <= '0;
      rd_ptr   <= '0;
      rd_empty <= 1'b1;
    end else begin
      rd_bin   <= rd_bin_next;
      rd_ptr   <= rd_gptr_next;
      rd_empty <= rd_empty_val;
    end
  end

  assign rd_bin_next  = (rd_inc && !rd_empty) ? (rd_bin + 1'b1) : rd_bin;
  assign rd_addr      = rd_bin[ADDR_WIDTH-1:0];
  assign rd_gptr_next = rd_bin_next ^ (rd_bin_next >> 1);
  assign rd_empty_val = (rd_gptr_next == wr_ptr_sync);

endmodule
