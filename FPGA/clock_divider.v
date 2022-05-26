module clock_divider(clk_50mhz, clk_9600hz);

input clk_50mhz; 
output reg clk_9600hz; 
reg[27:0] counter=28'd0;
parameter DIVISOR = 28'd5208;
//5208 clock 

always @(posedge clk_50mhz)
begin
 counter <= counter + 28'd1;
 if(counter>=(DIVISOR-1))
  counter <= 28'd0;

 clk_9600hz <= (counter<DIVISOR/2)?1'b1:1'b0;

end
endmodule
