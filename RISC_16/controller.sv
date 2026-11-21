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
`define LDR1		4'b1001
`define LDR2		4'b1010
`define STR1		4'b1011
`define STR2		4'b1100
`define HALT		4'b1101
`define dec		4'b1110

`define MREAD 		2'b00
`define MWRITE 		2'b01
`define MNONE 		2'b10


module controller(clk, reset, w, opcode, op, loada, loadb, loadc, nsel, write, asel, bsel, vsel, loads, reset_pc,load_pc,addr_sel, mem_cmd,load_ir,load_addr );

input clk, reset;

input [2:0] opcode;
input [1:0] op;
reg [23:0] next;

output loada, loadb, loadc, write, asel, bsel, vsel, loads, w,addr_sel,load_addr;
output reg [2:0] nsel;
//lab 7 addiiton
output reset_pc,load_pc,addr_sel,load_ir;
output [1:0] mem_cmd;

reg loada;
reg loadb;
reg loadc;

reg write;
reg asel;
reg bsel;
reg [1:0]vsel;
reg loads;
reg w;

//lab7 additions
reg reset_pc;
reg load_pc;
reg addr_sel;
reg [1:0] mem_cmd;
reg load_ir;
reg load_addr;
wire [`Sw-1:0] next_state_reset,present_state,next_state;

vDFF #(`Sw) STATE(clk,next_state,present_state);

//assign next_state_reset=reset? `rst : next_state; 

assign {next_state, loada, loadb, loadc, nsel, write, asel, bsel, vsel, loads, w, reset_pc, load_pc, addr_sel, mem_cmd, load_ir, load_addr} = next; 
   	       					

always@(*) begin

		casex({present_state,opcode, op,reset}) 
		{4'bxxxx,3'bxxx,2'bxx,1'b1} : next = {`rst, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b1, 1'b1, 1'b1, 1'b0, `MNONE, 1'b0,1'b0};	
		{`rst,3'bxxx, 2'bxx,1'b0} : next = {`IF1, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1, `MREAD, 1'b0,1'b0}; // 		
		{`IF1,3'bxxx,2'bxx,1'b0} : next = {`IF2, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1, `MREAD,1'b1,1'b0};
		{`IF2,3'bxxx,2'bxx,1'b0} : next =  {`updatepc, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, `MNONE, 1'b0,1'b0};
		//{`updatepc,3'bxxx,2'bxx,1'b0} : next = {`dec, 1'b0,1'b0,1'b0,3'b000,1'b0,1'b0,1'b0,2'b00,1'b0,1'b0,1'b0,1'b0,`MNONE,1'b0,1'b0};
		//for MOV Rn,#<im8> instruction
		{`updatepc,3'b110, 2'b10,1'b0} : next = {`S1, 1'b0, 1'b0, 1'b0, 3'b001, 1'b1, 1'b0, 1'b0, 2'b01, 1'b0,1'b0,1'b0,1'b0,1'b0,`MNONE,1'b0,1'b0}; // for MOV instruction
		{`S1,3'b110, 2'b10,1'b0} : next = {`IF1, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1, `MREAD, 1'b0,1'b0}; // once written to register go back to wait state
		
		//for MOV Rd,Rm,{,<sh_op>}
		{`updatepc,3'b110, 2'b00,1'b0} : next = {`GetB,1'b0, 1'b1, 1'b0, 3'b100, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0,1'b0,1'b0,1'b0,1'b0,`MNONE,1'b0,1'b0};  // load register b
		{`GetB,3'b110, 2'b00,1'b0} : next = {`Computations,1'b0, 1'b0, 1'b1, 3'b100, 1'b0, 1'b1, 1'b0, 2'b01, 1'b0,1'b0,1'b0,1'b0,1'b0,`MNONE,1'b0,1'b0};  // perform computations
		{`Computations,3'b110, 2'b00,1'b0} : next = {`WriteReg,1'b0, 1'b0, 1'b0, 3'b010, 1'b1, 1'b0, 1'b0, 2'b00, 1'b0,1'b0,1'b0,1'b0,1'b0,`MNONE,1'b0,1'b0}; // write to register
		
		{`WriteReg,3'bxxx, 2'bxx,1'b0} : next = {`IF1, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1, `MREAD, 1'b0,1'b0}; // go back to waiting state
		
		//for all ALU instruction 
		{`updatepc,3'b10x,2'bx,1'b0} : next = {`GetA, 1'b1,1'b0,1'b0,3'b001,1'b0,1'b0,1'b0,2'b00,1'b0,1'b0,1'b0,1'b0,1'b0,`MNONE,1'b0,1'b0}; //GET A value
		{`GetA,3'b10x,2'bx,1'b0} : next = {`GetB, 1'b0, 1'b1, 1'b0,3'b100,1'b0,1'b0,1'b0,2'b00,1'b0,1'b0,1'b0,1'b0,1'b0,`MNONE,1'b0,1'b0}; //GET B value

		//ADD Rd,Rn,Rm{,<sh_op>}
		{`GetB,3'b10x,2'b00,1'b0} : next = {`Computations,1'b0, 1'b0, 1'b1, 3'b010, 1'b0, 1'b0, 1'b0, 2'b01, 1'b0,1'b0,1'b0,1'b0,1'b0,`MNONE,1'b0,1'b0}; //perform computations
		{`Computations,3'b10x,2'b00,1'b0} : next = {`WriteReg,1'b0,1'b0,1'b0,3'b010,1'b1,1'b0,1'b0,2'b00,1'b0,1'b0,1'b0,1'b0,1'b0,`MNONE,1'b0,1'b0};//write back to register Rd
		
		
		//CMP Rn,Rm{,<sh_op>}
		{`GetB,3'b10x,2'b01,1'b0} : next = {`Computations,1'b0, 1'b0, 1'b0, 3'b100, 1'b0, 1'b0, 1'b0, 2'b01, 1'b1,1'b0,1'b0,1'b0,1'b0,`MNONE,1'b0,1'b0}; //loads
		{`Computations,3'b10x,2'b01,1'b0} : next = {`IF1, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1, `MREAD, 1'b0,1'b0}; // go back to waiting state
		
		
		//AND Rd,Rn,Rm{,<sh_op>}
		{`GetB,3'b10x,2'b10,1'b0} : next = {`Computations,1'b0, 1'b0, 1'b1, 3'b010, 1'b0, 1'b0, 1'b0, 2'b01, 1'b0,1'b0,1'b0,1'b0,1'b0,`MNONE,1'b0,1'b0}; //perform computations	
		{`Computations,3'b10x,2'b10,1'b0} : next = {`WriteReg,1'b0,1'b0,1'b0,3'b010,1'b1,1'b0,1'b0,2'b00,1'b0,1'b0,1'b0,1'b0,1'b0,`MNONE,1'b0,1'b0}; // write back to register Rd

		//MVN Rd,Rm{,<sh_op>} Note: we dont need to loada
		
		{`GetB,3'b10x,2'b11,1'b0} : next = {`Computations,1'b0, 1'b0, 1'b1, 3'b010, 1'b0, 1'b0, 1'b0, 2'b01, 1'b0,1'b0,1'b0,1'b0,1'b0,`MNONE,1'b0,1'b0};
		{`Computations,3'b10x,2'b11,1'b0} : next = {`WriteReg,1'b0,1'b0,1'b0,3'b010,1'b1,1'b0,1'b0,2'b00,1'b0,1'b0,1'b0,1'b0,1'b0,`MNONE,1'b0,1'b0};		


		//LDR Rd,[Rn{,#<im5>}
		{`updatepc,3'b011,2'b00,1'b0} : next = {`GetA, 1'b1,1'b0,1'b0,3'b001,1'b0,1'b0,1'b0,2'b00,1'b0,1'b0,1'b0,1'b0,1'b0,`MNONE,1'b0,1'b0}; //Get value stored in Rn
		{`GetA, 3'b011,2'b00,1'b0} : next = {`Computations,1'b0, 1'b0, 1'b1, 3'b001, 1'b0, 1'b0, 1'b1, 2'b01, 1'b0,1'b0,1'b0,1'b0,1'b0,`MNONE,1'b0,1'b0}; //Add sximm5 to value in Rn
		{`Computations,3'b011,2'b00,1'b0} : next = {`LDR1,1'b0, 1'b0, 1'b0, 3'b001, 1'b0, 1'b0, 1'b1, 2'b01, 1'b0,1'b0,1'b0,1'b0,1'b0,`MREAD,1'b0,1'b0}; //wait two clock cycle to read data from memory
		{`LDR1 ,3'b011,2'b00,1'b0} : next = {`LDR2,1'b0, 1'b0, 1'b0, 3'b001, 1'b0, 1'b0, 1'b1, 2'b01, 1'b0,1'b0,1'b0,1'b0,1'b0,`MREAD,1'b0,1'b1};
		{`LDR2, 3'b011,2'b00,1'b0} : next = {`WriteReg,1'b0,1'b0,1'b0,3'b010,1'b1,1'b0,1'b0,2'b11,1'b0,1'b0,1'b0,1'b0,1'b0,`MNONE,1'b0,1'b0}; // write to register Rd

		//STR Rd,[Rn{,#<im5>}]
		{`updatepc,3'b100,2'b00,1'b0} : next = {`GetA, 1'b1,1'b0,1'b0,3'b001,1'b0,1'b0,1'b0,2'b00,1'b0,1'b0,1'b0,1'b0,1'b0,`MNONE,1'b0,1'b0}; //get value stored in Rn
		{`GetA, 3'b100,2'b00,1'b0} : next = {`Computations,1'b0, 1'b0, 1'b1, 3'b001, 1'b0, 1'b0, 1'b1, 2'b01, 1'b0,1'b0,1'b0,1'b0,1'b0,`MNONE,1'b0,1'b0}; //Add sximm5 to value in Rn and loadc 
		{`Computations,3'b100,2'b00,1'b0} : next = {`STR1,1'b0, 1'b0, 1'b0, 3'b001, 1'b0, 1'b0, 1'b1, 2'b01, 1'b0,1'b0,1'b0,1'b0,1'b0,`MNONE,1'b0,1'b1}; //set load_addr=1
		{`STR1,3'b100,2'b00,1'b0} : next = {`STR2,1'b0, 1'b1, 1'b1, 3'b010, 1'b0, 1'b0, 1'b1, 2'b01, 1'b0,1'b0,1'b0,1'b0,1'b0,`MWRITE,1'b0,1'b0}; //get b value and loadc
		{`STR2,3'b100,2'b00,1'b0} : next = {`IF1, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1, `MREAD, 1'b0,1'b0};

		//HALT instruction
		{`updatepc,3'b111,2'bxx,1'b0} : next = {`HALT, 1'b0,1'b0,1'b0,3'b000,1'b0,1'b0,1'b0,2'b00,1'b0,1'b1,1'b0,1'b0,1'b0,`MNONE,1'b0,1'b0};

		default: next = {`rst, 1'b0, 1'b0, 1'b0, 3'b000, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b1, 1'b1, 1'b1, 1'b0, `MNONE, 1'b0};
	endcase
end

endmodule