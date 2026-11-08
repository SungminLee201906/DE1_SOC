module async_FIFO (
input logic wr_clk,
input logic rd_clk,

input logic wr_inc,
input logic rd_inc,

input logic wr_rst,
input logic rd_rst,

output logic [7:0] data,
output logic wr_full,
output logic rd_full
);

logic [3:0] wr_addr, rd_addr;
logic	[4:0] wr_ptr, wr_sq_ptr, rd_ptr, rd_sq_ptr;


endmodule