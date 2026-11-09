module async_FIFO_mem #(
  parameter DATA_WIDTH = 8,
  parameter ADDR_WIDTH = 4
)(
  output logic [DATA_WIDTH-1:0] rd_data,

  input  logic [DATA_WIDTH-1:0] wr_data,
  input  logic [ADDR_WIDTH-1:0] wr_addr,
  input  logic [ADDR_WIDTH-1:0] rd_addr,

  input  logic                  wr_clk,
  input  logic                  wr_en,
  input  logic                  wr_full
);

  (* ramstyle = "logic" *) logic [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

  assign rd_data = mem[rd_addr];

  always_ff @(posedge wr_clk) begin
    if (wr_en && !wr_full)
      mem[wr_addr] <= wr_data;
  end

endmodule
