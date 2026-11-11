module lfsr_step (
  input  logic [7:0] cur,
  output logic [7:0] nxt
);
  // Galois LFSR, taps 8,6,5,4 (mask 0xB8): cycles through all 255 non-zero values
  assign nxt = {1'b0, cur[7:1]} ^ (cur[0] ? 8'hB8 : 8'h00);
endmodule
