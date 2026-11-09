module async_FIFO #(
  parameter DATA_WIDTH = 8,
  parameter ADDR_WIDTH = 4
)(
  input  logic                  wr_clk,
  input  logic                  wr_rst,
  input  logic                  wr_inc,
  input  logic [DATA_WIDTH-1:0] wr_data,
  output logic                  wr_full,

  input  logic                  rd_clk,
  input  logic                  rd_rst,
  input  logic                  rd_inc,
  output logic [DATA_WIDTH-1:0] rd_data,
  output logic                  rd_empty
);

  logic [ADDR_WIDTH-1:0] wr_addr, rd_addr;
  logic [ADDR_WIDTH:0]   wr_ptr, rd_ptr;
  logic [ADDR_WIDTH:0]   wr_ptr_sync, rd_ptr_sync;

  write_pointer #(.ADDR_WIDTH(ADDR_WIDTH)) wptr_inst (
    .wr_clk      (wr_clk),
    .wr_rst      (wr_rst),
    .wr_inc      (wr_inc),
    .rd_ptr_sync (rd_ptr_sync),
    .wr_full     (wr_full),
    .wr_ptr      (wr_ptr),
    .wr_addr     (wr_addr)
  );

  read_pointer #(.ADDR_WIDTH(ADDR_WIDTH)) rptr_inst (
    .rd_clk      (rd_clk),
    .rd_rst      (rd_rst),
    .rd_inc      (rd_inc),
    .wr_ptr_sync (wr_ptr_sync),
    .rd_empty    (rd_empty),
    .rd_ptr      (rd_ptr),
    .rd_addr     (rd_addr)
  );

  synchronizer #(.WIDTH(ADDR_WIDTH+1)) sync_w2r (
    .clk (rd_clk),
    .rst (rd_rst),
    .in  (wr_ptr),
    .out (wr_ptr_sync)
  );

  synchronizer #(.WIDTH(ADDR_WIDTH+1)) sync_r2w (
    .clk (wr_clk),
    .rst (wr_rst),
    .in  (rd_ptr),
    .out (rd_ptr_sync)
  );

  async_FIFO_mem #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) mem_inst (
    .rd_data (rd_data),
    .wr_data (wr_data),
    .wr_addr (wr_addr),
    .rd_addr (rd_addr),
    .wr_clk  (wr_clk),
    .wr_en   (wr_inc),
    .wr_full (wr_full)
  );

endmodule
