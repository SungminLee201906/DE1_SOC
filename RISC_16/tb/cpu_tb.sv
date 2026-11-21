//define all instructions
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

module cpu_tb();

reg sim_clk,sim_reset;
reg[15:0]sim_in;
reg err;
wire [15:0]sim_out;
wire sim_N,sim_V,sim_Z,sim_w;

cpu DUT(sim_clk,sim_reset,sim_in,sim_out,sim_N,sim_V,sim_Z,sim_w);

wire [15:0] R0 = DUT.DP.REGFILE.R0;
wire [15:0] R1 = DUT.DP.REGFILE.R1;
wire [15:0] R2 = DUT.DP.REGFILE.R2;
wire [15:0] R3 = DUT.DP.REGFILE.R3;
wire [15:0] R4 = DUT.DP.REGFILE.R4;
wire [15:0] R5 = DUT.DP.REGFILE.R5;
wire [15:0] R6 = DUT.DP.REGFILE.R6;
wire [15:0] R7 = DUT.DP.REGFILE.R7;

initial begin
	sim_clk=0; #5
	forever begin
		sim_clk=1; #5;
		sim_clk=0; #5;
	end
end

initial begin
//set initial values for error s and load and in
 err = 0;
    sim_reset = 1;  sim_in = 16'b0;
    #10;
    sim_reset = 0; 
    #10;
//MOV R0, #7
    sim_in = 16'b1101000000000111;
    
    #10;
   
   
    #10
   
    #10;
    if (R0 !== 16'h7) begin
      err = 1;
      $display("FAILED: MOV R0, #7");
      $stop;
    end
//MOV R1, #2
sim_in = 16'b1101000100000010;
    
    #10;
   
    #10
   
    #10
if (R1 !== 16'h2) begin
      err = 1;
      $display("FAILED: MOV R1, #2");
      $stop;
    end

//ADD R2,R1, R0, LSL#1
sim_in = 16'b1010000101001000;
  
    #10;

    #10;
   
    #100;
if (R2 !== 16'h10) begin
      err = 1;
      $display("FAILED: ADD R2, R1, R0, LSL#1");
      $stop;
    end
   

//CMP R1,R0

sim_in = 16'b1010100100000000;
    
    #10;
 
    #10;
   
    #100;
if (sim_Z!== 1'b0) begin
      err = 1;
      $display("FAILED: CMP R1,R0");
      $stop;
    end
if (sim_V!== 1'b0) begin
      err = 1;
      $display("FAILED: CMP R1,R0");
      $stop;
    end
if (sim_N!== 1'b1) begin
      err = 1;
      $display("FAILED: CMP R1,R0");
      $stop;
    end
/*
//AND R5,R2,R0,LSL#1   
sim_in = 16'b1011001010101000;
    sim_load = 1;
    #10;
    sim_load = 0;
    sim_s = 1;
    #10;
    sim_s = 0;
    #100;
if (R5 !== 16'h0) begin
      err = 1;
      $display("FAILED: AND R5,R2,R0,LSL#1 ");
      $stop;
    end
//MVN R3,R5,LSL#1
sim_in = 16'b1011100001101101;
    sim_load = 1;
    #10;
    sim_load = 0;
    sim_s = 1;
    #10;
    sim_s = 0;
    #100;
if (R3 !== 16'hffff) begin
      err = 1;
      $display("FAILED: R5,R3,LSL#1 ");
      $stop;
    end

/*****************************************************************************************************************************************************/
/*
//ADD R3,R2,R1,LSR#1
sim_in = 16'b1010001011111001;
    sim_load = 1;
    #10;
    sim_load = 0;
    sim_s = 1;
    #10;
    sim_s = 0;
    #100;
if (R7!== 16'h0011) begin
      err = 1;
      $display("FAILED: ADD R3,R2,R1,LSR#1");
      $stop;
    end
//MOV R4,#-30
sim_in = 16'b1101010011100010;
    sim_load = 1;
    #10;
    sim_load = 0;
    sim_s = 1;
    #10;
    sim_s = 0;
    #100;
if (R4!== 16'hffe2) begin
      err = 1;
      $display("FAILED: MOV R4,#-30");
      $stop;
    end

//CMP R2,R4,LSR#1
sim_in = 16'b101010100011100;
    sim_load = 1;
    #10;
    sim_load = 0;
    sim_s = 1;
    #10;
    sim_s = 0;
    #100;
if (sim_Z!== 1'b0) begin
      err = 1;
      $display("FAILED: CMP R2,R4,LSR#1");
      $stop;
    end
if (sim_V!== 1'b0) begin
      err = 1;
      $display("FAILED: CMP R2,R4,LSR#1");
      $stop;
    end
if (sim_N!== 1'b1) begin
      err = 1;
      $display("FAILED: CMP R2,R4,LSR#1");
      $stop;
    end


//AND R6,R3,R4,LSR#1
sim_in = 16'b1011001111011100;
    sim_load = 1;
    #10;
    sim_load = 0;
    sim_s = 1;
    #10;
    sim_s = 0;
    #100;
if (R6 !== 16'hfff1) begin
      err = 1;
      $display("FAILED: AND R6,R3,R4,LSR#1");
      $stop;
    end

//MVN R5,R4,LSR#1
sim_in = 16'b1011100010111100;
    sim_load = 1;
    #10;
    sim_load = 0;
    sim_s = 1;
    #10;
    sim_s = 0;
    #100;
if (R5 !== 16'h000e) begin
      err = 1;
      $display("FAILED: MVN R5,R4,LSR#1");
      $stop;
    end
/******************************************************************************************************************************************************/
/*
//ADD R1,R2,ASR#1
sim_in = 16'b1010001000110010;
    sim_load = 1;
    #10;
    sim_load = 0;
    sim_s = 1;
    #10;
    sim_s = 0;
    #100;
if (R1!== 16'h0018) begin
      err = 1;
      $display("FAILED: ADD R1,R2,ASR#1");
      $stop;
    end
// CMP R7,R0,ASR#1
sim_in = 16'b1010100000010111;
    sim_load = 1;
    #10;
    sim_load = 0;
    sim_s = 1;
    #10;
    sim_s = 0;
    #100;
if (sim_Z!== 1'b0) begin
      err = 1;
      $display("FAILED: CMP R7,R0,ASR#1");
      $stop;
    end
if (sim_V!== 1'b0) begin
      err = 1;
      $display("FAILED: CMP R7,R0,ASR#1");
      $stop;
    end
if (sim_N!== 1'b1) begin
      err = 1;
      $display("FAILED: CMP R7,R0,ASR#1");
      $stop;
    end
//AND R0,R3,R2,ASR#1
sim_in = 16'b1011001100010010;
    sim_load = 1;
    #10;
    sim_load = 0;
    sim_s = 1;
    #10;
    sim_s = 0;
    #100;
if (R0!== 16'h0008) begin
      err = 1;
      $display("FAILED: AND R0,R3,R2,ASR#1");
      $stop;
    end

//MVN R4,R2,ASR#1
sim_in = 16'b1011100010010010;
    sim_load = 1;
    #10;
    sim_load = 0;
    sim_s = 1;
    #10;
    sim_s = 0;
    #100;
if (R4 !== 16'hfff7) begin
      err = 1;
      $display("FAILED: MVN R4,R2,ASR#1");
      $stop;
    end
*/

if (~err) $display("INTERFACE OK");
    $stop;

end
endmodule
