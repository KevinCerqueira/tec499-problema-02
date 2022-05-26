module clock_divider1mhz(clk_50mhz, clk_1mhz);

input clk_50mhz; 
output reg clk_1mhz; 
reg[27:0] counter=28'd0;
parameter DIVISOR = 28'd50;
//5208 clock 

always @(posedge clk_50mhz)
begin
 counter <= counter + 28'd1;
 if(counter>=(DIVISOR-1))
  counter <= 28'd0;

 clk_1mhz <= (counter<DIVISOR/2)?1'b1:1'b0;

end
endmodule