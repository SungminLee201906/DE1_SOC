module regfile(data_in,writenum,write,readnum,clk,data_out);
input [15:0] data_in;
input [2:0] writenum, readnum;
input write, clk;
output reg[15:0] data_out;

//registers from R0 to R7
//read is combinational
//readnum is the register to be read from
//writenum is the register to be written to
//the value of writenum is decoded 3:8

//load register
reg [15:0] R0 ;
reg [15:0] R1 ;
reg [15:0] R2 ;
reg [15:0] R3 ;
reg [15:0] R4 ;
reg [15:0] R5 ;
reg [15:0] R6 ;
reg [15:0] R7 ;

reg [7:0]Dec_wreg;  //after decoding write 
reg [7:0]load;      //load register after Dec_reg is ANDed with write
reg [7:0]Dec_rreg;  //decoding readnum



assign Dec_wreg=1<<writenum;	
assign Dec_rreg=1<<readnum;

assign  load[0]=Dec_wreg[0] & write;
assign  load[1]=Dec_wreg[1] & write;
assign	load[2]=Dec_wreg[2] & write;
assign	load[3]=Dec_wreg[3] & write;
assign	load[4]=Dec_wreg[4] & write;
assign	load[5]=Dec_wreg[5] & write;
assign	load[6]=Dec_wreg[6] & write;
assign	load[7]=Dec_wreg[7] & write; 


//write to register at rising clock of the edge
always_ff @(posedge clk) begin	
		
		if(write) begin	

		case(load) //store the data in the appropriate register
			8'b00000001: R0 <= data_in; 
			8'b00000010: R1 <= data_in; 
			8'b00000100: R2 <= data_in; 
			8'b00001000: R3 <= data_in; 
			8'b00010000: R4 <= data_in; 
			8'b00100000: R5 <= data_in; 
			8'b01000000: R6 <= data_in; 
			8'b10000000: R7 <= data_in; 
		endcase
	end
end



//combinational block that reads from register regardless of clock happening at all times
always_comb begin
	//Dec_rreg=1<<readnum;
	case(Dec_rreg) 
		8'b00000001: data_out=R0; 
		8'b00000010: data_out=R1;
		8'b00000100: data_out=R2;
		8'b00001000: data_out=R3;
		8'b00010000: data_out=R4; 
		8'b00100000: data_out=R5; 
		8'b01000000: data_out=R6; 
		8'b10000000: data_out=R7; 
	default: data_out=16'bx;
	endcase
		
	
end


endmodule






