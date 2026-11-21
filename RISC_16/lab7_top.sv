
`define MREAD 2'b00
`define MWRITE 2'b01
`define MNONE 2'b10

module lab7_top(KEY,SW,LEDR,HEX0,HEX1,HEX2,HEX3,HEX4,HEX5);
input [3:0] KEY;
input [9:0] SW;
output [9:0] LEDR;
output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;








assign clk=~KEY[0];
assign reset=~KEY[1];

RAM MEM(clk,read_addr,write_addr,mwrite,write_data,dout);

assign read_data=enable? dout:{16{1'bz}};
