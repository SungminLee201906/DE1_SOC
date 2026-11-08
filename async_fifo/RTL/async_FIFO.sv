module async_FIFO (
  input  logic       wr_clk,
  input  logic       rd_clk,

  input  logic       wr_rst,
  input  logic       rd_rst,

  input  logic       wr_inc,
  input  logic       rd_inc,
  input  logic [7:0] wr_data,

  output logic [7:0] rd_data,
  output logic       wr_full,
  output logic       rd_empty
);

  logic [3:0] wr_addr, rd_addr;
  logic [4:0] wr_ptr, rd_ptr;           // Gray pointers, own clock domain
  logic [4:0] wr_ptr_sync, rd_ptr_sync; // Gray pointers, synchronized into the other domain

  // Write pointer logic (write clock domain)
  write_pointer wptr_inst (
    .wrclk   (wr_clk),
    .wr_rst  (wr_rst),
    .wr_inc  (wr_inc),
    .r_ptr   (rd_ptr_sync),   // read pointer, synchronized into write domain
    .wr_full (wr_full),
    .wr_ptr  (wr_ptr),
    .wr_addr (wr_addr)
  );

  // Read pointer logic (read clock domain)
  read_pointer rptr_inst (
    .rd_clk   (rd_clk),
    .rd_rst   (rd_rst),
    .rd_inc   (rd_inc),
    .wr_ptr   (wr_ptr_sync),  // write pointer, synchronized into read domain
    .rd_empty (rd_empty),
    .rd_ptr   (rd_ptr),
    .rd_addr  (rd_addr)
  );

  // Write pointer -> read clock domain
  synchronizer #(.WIDTH(5)) sync_w2r (
    .clk (rd_clk),
    .rst (rd_rst),
    .in  (wr_ptr),
    .out (wr_ptr_sync)
  );

  // Read pointer -> write clock domain
  synchronizer #(.WIDTH(5)) sync_r2w (
    .clk (wr_clk),
    .rst (wr_rst),
    .in  (rd_ptr),
    .out (rd_ptr_sync)
  );

  // Memory
  async_FIFO_mem mem_inst (
    .rd_data    (rd_data),
    .wr_data    (wr_data),
    .wr_addr    (wr_addr),
    .rd_addr    (rd_addr),
    .wr_clk     (wr_clk),
    .wr_clk_en  (wr_inc),
    .wr_full    (wr_full)
  );

endmodule