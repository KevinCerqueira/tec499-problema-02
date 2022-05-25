module uart_main2(clock, rxIn, txOut, led);
	input clock;
	input rxIn;
	output txOut;
	output reg [2:0] led;
	wire baud_rt;
	
	// UART RX
	
	reg rxEn = 1'b1;
	wire rxDone, rxBusy, rxError;
	wire [7:0] rxOut;
	reg [7:0] command;
	
	// DHT 11
	
	wire dht_clock;
	reg dhtEn = 1'b0;
	wire dhtDone, dhtBusy;
	wire [39:0] measure;
	reg [7:0] measure_mux;
	
	// UART TX
	
	reg txEn = 1'b0;
	wire txDone, txBusy, txError;
	reg [7:0] response;
	reg [7:0] txIn;
	
	
	// MÁQUINAS DE ESTADO
	
	localparam HUM = 1, TEMP = 2;
	localparam IDLE = 0, RECEIVING = 1, MEASURING = 2, TRANSMITTING_P1 = 3, TRANSMITTING_P2 = 4, RESET = 5;
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
	
	Uart8Transmitter(
		.clk(baud_rt),
		.en(txEn),
		.in(txIn),
		.out(txOut),
		.done(txDone),
		.busy(txBusy)
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
					uart_state <= MEASURING;
					command <= rxOut;
				end
			end
			MEASURING: begin
				rxEn <= 1'b0;
				dhtEn <= 1'b1;
				if(dhtDone) begin
					case(command)
						4: begin // temperatura
							response <= 8'b00000010
							measure_mux <= measure[23:16] 
						end
						5: begin // umidade
							response <= 8'b00000001
							measure_mux <= measure[39:32] 
						end
					endcase
					uart_state <= TRANSMITTING_P1;
				end
			end
			TRANSMITTING_P1: begin
				txEn <= 1'b1;
				dhtEn <= 1'b0;
				txIn <= response;
				if(txDone) begin
					uart_state <= TRANSMITTING_P2;
				end
			end
			TRANSMITTING_P2: begin
				txEn <= 1'b1;
				dhtEn <= 1'b0;
				txIn <= measure_mux;
				if(txDone) begin
					uart_state <= RESET;
				end
			end
			RESET: begin
				rxEn <= 1'b1;
				txEn <= 1'b0;
				dhtEn <= 1'b0;
				measure <= 40'b0000000000000000000000000000000000000000;
				measure_mux <= 8'b00000000;
				response <= 8'b00000000;
				txIn <= 8'b00000000;
				command <= 8'b00000000; 
				uart_state <= IDLE;
			end
		endcase
	end
	
endmodule
