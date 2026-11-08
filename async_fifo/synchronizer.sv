module synchronizer #(parameter WIDTH = 1)(
  input  logic clk,
  input  logic rst,
  input  logic [WIDTH-1:0] in,
  output logic [WIDTH-1:0] out
);


logic [WIDTH-1:0] ff1;

always_ff @(posedge clk or posedge rst) begin
	if (rst)
		ff1<='0;
	else
		ff1<=in; 
end


always_ff @(posedge clk or posedge rst) begin
	if(rst)
		out <='0;
	else
		out<=ff1;
end

endmodule