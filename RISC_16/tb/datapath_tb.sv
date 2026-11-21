module datapath_tb;

reg [15:0] datapath_in;
wire [15:0] datapath_out;
reg clk;
reg write;
reg vsel,loada,loadb,asel,bsel,loadc,loads;
reg [2:0] readnum;
reg [2:0] writenum;
reg [1:0] ALUop;
reg [1:0] shift;
reg err;

wire Z_out;
wire [15:0] R0 = DUT.REGFILE.R0;
wire [15:0] R1 = DUT.REGFILE.R1;
wire [15:0] R2 = DUT.REGFILE.R2;
wire [15:0] R3 = DUT.REGFILE.R3;
wire [15:0] R4 = DUT.REGFILE.R4;
wire [15:0] R5 = DUT.REGFILE.R5;
wire [15:0] R6 = DUT.REGFILE.R6;
wire [15:0] R7 = DUT.REGFILE.R7;

datapath DUT (clk,datapath_in, write, vsel, loada, loadb, asel, bsel, 
                   loadc, loads, readnum, writenum, shift, ALUop,datapath_out,Z_out);

initial begin
	clk=0; #5
	forever begin
		clk=1; #5;
		clk=0; #5;
	end
end


/* MOV R0, #7 ; this means, take the absolute number 7 and store it in R0
MOV R1, #2 ; this means, take the absolute number 2 and store it in R1
ADD R2, R1, R0, LSL#1 ; this means R2 = R1 + (R0 shifted left by 1) = 2+14=16 */

initial begin
datapath_in = 0;
write = 0; vsel=0; loada=0; loadb=0; asel=0; bsel=0; loadc=0; loads=0;
readnum = 0; writenum=0;
shift = 0; ALUop=0;
err=1'b0;
loads=1;
#10;



write=1'b1;
writenum=3'b000;
datapath_in=16'b0000000000000111;
vsel=1'b1;
#10;

//MOV R0, #7
$display("checking if 7 is stored in R0");
	if(R0!=16'b0000000000000111) begin
		$display("**ERROR value is %b, expected is %b", R0, 16'b0000000000000111);
		err=1'b1;
	end

// MOV R1, #2
write=1'b1;
writenum=3'b001;
datapath_in=16'b0000000000000010;
vsel=1'b1;
#10;

$display("checking if 2 is stored in R1");
	if(R1!=16'b0000000000000010) begin
		$display("**ERROR value is %b, expected is %b",R1, 16'b0000000000000010);
		err=1'b1;
	end

//ADD R2,R1,R0, LSL#1
write=1'b0;
#5;
//read value from R1 and load in a (first cycle)
readnum=3'b001;
loada=1'b1;
#20;


//second cycle
loada=1'b0;
readnum=3'b000;
loadb=1'b1;
#20;



//Third cycle
loadb=1'b0;
shift=2'b01;
asel=1'b0;
bsel=1'b0;
ALUop=2'b00;
loadc=1'b1;
#20;



//fourth cycle
loadc=1'b0;
vsel=1'b0;
write=1'b1;
writenum=3'b010;
#20;

$display("checking if 16 (2+4=16) is stored in register 3 after arithmetic and shift computations");
	if(R3!=16'b0000000000010000) begin
		$display("**ERROR value is %b, output is %b",R3,16'b0000000000010000);
		err=1'b1;
	end

//check if datapath_out outputs correctly
$display("checking if output is correct");
	if (datapath_out!=16'b0000000000010000) begin
		$display("**ERROR value output is %b, expected is %b",datapath_out,16'b0000000000010000);
		err=1'b1;
	end
/*check if z output is zero since the computated output is not equal to zero*/

$display("checking for Z output");
	if(Z_out!=0) begin
		$display("**ERROR value output is %b, expected is %b", Z_out, 1'b0);
	end

/*----------------------------------------------------------------------------------------------------------------------------*/








if(~err) begin
	$display("PASSED");
	$stop;
end
		
end
	
endmodule 