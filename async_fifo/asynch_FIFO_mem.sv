module async_FIFO_mem(
  output logic [7:0] rd_data,   // data to be read

  input  logic [7:0] wr_data,   // data to be written
  input  logic [3:0] wr_addr,   // address of data to be written to
  input  logic [3:0] rd_addr,   // address of data to be read from

  input  logic       wr_clk,
  input  logic       wr_clk_en,
  input  logic       wr_full
);

  logic [7:0] mem [0:15];       // 16 slots, matches 4-bit address

  assign rd_data = mem[rd_addr];

  always_ff @(posedge wr_clk) begin
    if (wr_clk_en && !wr_full)
      mem[wr_addr] <= wr_data;
  end

endmodule