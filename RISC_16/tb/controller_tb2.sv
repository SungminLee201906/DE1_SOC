
`define Sw 4
`define rst		4'b0000
`define IF1		4'b0001 
`define IF2 		4'b0010 
`define S1 		4'b0011
`define GetA 		4'b0100 
`define GetB 		4'b0101
`define Computations 	4'b0110
`define WriteReg 	4'b0111// final state go back to wait
`define updatepc	4'b1000

`define MREAD 		2'b00
`define MWRITE 		2'b01
`define MNONE 		2'b10




module controller_tb2();

reg clk, reset;

reg [2:0] opcode;
reg [1:0] op;

wire loada, loadb, loadc, write, asel, bsel, loads, w;
wire [1:0] vsel;
wire[2:0] nsel;
//lab 7 addiiton
wire reset_pc,load_pc,addr_sel,load_ir;
wire [1:0] mem_cmd;
wire load_addr;

controller DUT (clk, reset, w, opcode, op, loada, loadb, loadc, nsel, write, asel, bsel, vsel, loads, reset_pc,load_pc,addr_sel, mem_cmd,load_ir,load_addr );

initial begin
	clk=0; #5
	forever begin
		clk=1; #5;
		clk=0; #5;
	end
end

initial begin

reset=1;
#10
reset=0;
opcode=3'b110;
op=2'b10;

#5000;
end
endmodule

