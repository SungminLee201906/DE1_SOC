# Clocks: 50 MHz write, ~37 MHz read
create_clock -name wr_clk -period 20.000 [get_ports wr_clk]
create_clock -name rd_clk -period 27.000 [get_ports rd_clk]

# Derive PLL clocks (none yet) and clock uncertainty
derive_pll_clocks
derive_clock_uncertainty

# The two clock domains are unrelated: don't time paths between them
set_clock_groups -asynchronous -group {wr_clk} -group {rd_clk}