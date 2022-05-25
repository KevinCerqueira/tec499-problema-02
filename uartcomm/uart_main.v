module uart_main(clock, rxIn, txOut, led);
	input clock;
	input rxIn;
	output txOut;
	output reg [2:0] led;
	
	wire baud_rt;
	reg rxEn = 1'b1;
	reg txEn = 1'b0;
	
	wire rxDone, rxBusy, rxError;
	wire [7:0] rxOut;
	reg [7:0] command;
	
	localparam IDLE = 0, RECEIVING = 1, DECODING = 2, TRANSMITTING = 3, RESET = 4;
	reg [2:0] uart_state;
	
	baud_gen baud_gen(
		clock,
		0,
		baud_rt
	);
	
	Uart8Receiver rx(
		.clk(baud_rt),
		.en(rxEn),
		.in(rxIn),
		.out(rxOut),
		.done(rxDone),
		.busy(rxBusy),
		.err(rxError)
	);
	
	always @ (posedge baud_rt) begin
		case(uart_state)
			IDLE: begin
				if(rxBusy) begin
					uart_state <= RECEIVING;
				end
			end
			RECEIVING: begin
				if(rxDone) begin
					uart_state <= DECODING;
					command <= rxOut;
				end
			end
			DECODING: begin
				rxEn <= 1'b0;
				case(command)
					3: led <= 3'b001;
				endcase
				uart_state <= RESET;
			end
			RESET: begin
				rxEn = 1'b1;
				txEn = 1'b0;
				uart_state <= IDLE;
			end
		endcase
	end
	
endmodule
