`define MREAD 2'b00
`define MWRITE 2'b01
`define MNONE 2'b10


module execute(clk,write,mem_cmd,addr_sel,reset_pc,load_pc,read_data,load_addr,write_data);

input clk,write,load_pc,reset_pc,addr_sel;
input [1:0] mem_cmd;
input addr_sel;
input load_addr;
output [15:0] write_data;
output [15:0] read_data;

reg [8:0] read_addr; // address to read from
reg [8:0] write_addr; // address to write to
reg [8:0] mem_addr;
reg [8:0] next_pc;
reg [8:0] PC;
reg c1,c2,msel; //c1 is the comparator result for read and c2 is for write 

reg [8:0] data_address; //data address register
reg [8:0] data_address_in;
reg[15:0] write_data;
reg[15:0] din;
reg[15:0]dout;


//instantiate RAM
RAM MEM(clk,read_addr,write_addr,write,din,dout);


//reset pc multiplexer
assign next_pc=reset_pc? 9'b000000000: pc_out+1;
//pc register
always_ff@(posedge clk) begin
	if(load_pc)
		PC<=next_pc;
end
//address select multiplexer
assign mem_addr=addr_sel? pc_out:data_address;
assign write_address=mem_addr;
assign read_address=mem_addr;

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

assign read_data=enable? dout:{16{1'bz}};

//lab 6 stage 2 continued...

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

assign write=c2&msel;

assign din=write_data;

endmodule