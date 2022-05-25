module baud_rate_gen(clk_in, rst, baud_out);

	input clk_in;
	input rst;
	
	output reg baud_out;
	
	reg [11:0] counter;
	
	always @ (posedge clk_in) begin
		if (rst) begin
			baud_out <= 1'b0;
		end else begin
			if (counter > 12'd3472) begin	// 12'd3472
				baud_out <= ~baud_out;
				counter <= 12'd0;
			end else begin
				counter <= counter + 12'd1;
			end
		end
	end
	
endmodule


module uart_main(clock, reset, rx, rxEn, tx, txEn, busy);
	input clock, reset;
	
	input rx;
	input rxEn;	
	
	input txEn;
	output reg tx;
	
	output busy;
	
	reg[0:7] dataIn;
	reg[0:7] dataOut;
	
	reg[0:3] rxCount = 2'd0;
	reg[0:3] txCount = 2'd8;
	
	wire baud;
	
	baud_rate_gen baud_gen(clock, reset, baud);
	
	always @(posedge baud) begin
		if(rxEn == 1) begin
			dataIn[rxCount] <= rx;
			rxCount <= rxCount + 2'd1;
		end
		if (txEn == 1) begin
			dataOut = dataIn;
			tx <= dataOut[txCount];
			txCount <= txCount - 2'd1;
		end
		if (rxCount >= 2'd8) begin
			rxCount <= 2'd0;
		end
		if (txCount <= 2'd0) begin
			txCount <= 2'd8; 
		end
	end
	
	always @(posedge reset) begin
		dataOut = 2'd8;
		dataIn = 2'd0;
		tx <= 1'b1;
	end
	
endmodule
