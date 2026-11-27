`define MREAD 2'b00
`define MWRITE 2'b01
`define MNONE 2'b10

module cpu(clk, reset,out, N, V, Z, w,mwrite,write_addr,read_addr,read_data,write_data,enable); //dout is da new in brutha

input clk, reset;
input[15:0] read_data;
output [15:0] write_data;
output [15:0] out;
output N,V,Z,w;
output mwrite;
output [7:0] write_addr;
output [7:0] read_addr;
output enable;

reg  [15:0] IR_out;
reg  [8:0]  PC;                 // program counter (declared before use)
wire write, loads, loadb, asel, bsel, loadc, loada;
wire [1:0]  vsel;
wire [2:0]  readnum;
wire [2:0]  writenum;
wire [1:0]  shift;
wire [1:0]  ALUop;
wire [15:0] mdata;
wire [15:0] sximm8;
wire [15:0] sximm5;
wire [2:0]  nsel;
wire [2:0]  opcode;
wire [1:0]  op;
wire        load_ir;
wire        reset_pc, load_pc, addr_sel, load_addr;   // controller outputs (were implicit 1-bit wires)
wire [1:0]  mem_cmd;                                  // must be 2 bits for MREAD / MWRITE / MNONE



always_ff @(posedge clk) begin
	if(load_ir) begin
		IR_out<=read_data;
	
	end
end

datapath DP(clk, write, vsel, loada, loadb, asel, bsel, 
                   loadc, loads, readnum, writenum, shift, ALUop,out,mdata,sximm8,PC,sximm5,N,V,Z);

controller CL(clk, reset, w, opcode, op, loada, loadb, loadc, nsel, write, asel, bsel, vsel, loads, reset_pc,load_pc,addr_sel, mem_cmd,load_ir,load_addr );

decoder DECODER(IR_out, ALUop, sximm5, sximm8, shift, readnum, writenum, nsel, opcode, op);

assign write_data = out;        // STR data and LDR/STR address come from the datapath output (C)
assign mdata      = read_data;  // LDR: memory data into the register file

reg [8:0] mem_addr;
reg [8:0] next_pc;
reg c1,c2,msel; 					//c1 is the comparator result for read and c2 is for write
reg [8:0] data_address; 			//data address register
reg [8:0] data_address_in;


//reset pc multiplexer
assign next_pc=reset_pc? 9'b000000000: PC+1;
//pc register
always_ff@(posedge clk) begin
	if(load_pc)
		PC<=next_pc;
end
//address select multiplexer
assign mem_addr=addr_sel? PC:data_address;
assign write_addr=mem_addr[7:0];
assign read_addr=mem_addr[7:0];

//comparator for MREAD
always_comb begin
	if(mem_cmd==`MREAD) begin
		c1=1'b1;
	end else begin
		c1=1'b0;
	end
end

//comparator for MSEl
always_comb begin
	if(mem_addr[8]==1'b0) begin
		msel=1'b1;
	end else begin
		msel=1'b0;
	end
end

assign enable=c1&msel;



assign data_address_in=write_data;

always_ff@(posedge clk) begin
	if(load_addr) begin
		data_address<=data_address_in;
	end
end	

always_comb begin
	if(mem_cmd==`MWRITE) begin
		c2=1'b1;
	end else begin
		c2=1'b0;
	end
end

assign mwrite=c2&msel;


endmodule






