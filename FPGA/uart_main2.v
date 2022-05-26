module uart_main2(clock, rxIn, txOut, led, sensor);
	input clock;
	input rxIn;
	inout sensor;
	output txOut;
	output reg [2:0] led;
	wire baud_rt;
	
	baud_gen baud_gen(
		clock,
		0,
		baud_rt
	);
	
	// UART RX
	
	reg rxEn = 1'b1;
	wire rxDone, rxBusy, rxError;
	wire [7:0] rxOut;
	reg [7:0] command;
	
	Uart8Receiver rx(
		.clk(baud_rt),
		.en(rxEn),
		.in(rxIn),
		.out(rxOut),
		.done(rxDone),
		.busy(rxBusy),
		.err(rxError)
	);
	
	// DHT 11
	
	wire dht_clock;
	reg dhtEn = 1'b0;
	wire dhtReady, dhtBusy, dhtError;
	wire [39:0] measure;
	reg [7:0] measure_mux;
	
	// DHT 11 CONTROLLER
	
	wire c_done;
	wire c_start;
	wire [7:0] c_in, c_out;
	wire data_received;
	wire start_sensor;	
	wire clk_9600hz;
	wire c_error;
	
	clock_divider divider_0(
		.clk_50mhz(clock),
		.clk_9600hz(clk_9600hz)
	);

	//Controladora principal dos sensores
	sensor_controller sensor_controller_0(
		.start(c_start),
		.data_in(c_in),
		.data_out(c_out),
		.reset(0),
		.data_received(data_received),
		.sensor_data(measure),
		.clk_9600hz(clk_9600hz),
		.start_sensor(start_sensor),
		.error(c_error),
		.done(c_done)
	);
	
	wire clk_1mhz;

	//Divisor de clock para 1Mhz
	clock_divider1mhz divider_1(
		.clk_50mhz(clock),
		.clk_1mhz(clk_1mhz)
	);


	//Bloco interface com o sensor de humidade e temperatura
	dht11 dht11_0(
		.clk_1mhz(clk_1mhz),
		.sensor_data(measure),
		.start_sensor(start_sensor),
		.sensor_pin(sensor),
		.error(dhtError)
	);

	
	// UART TX
	
	reg txEn = 1'b0;
	wire txDone, txBusy, txError;
	reg [7:0] response;
	reg [7:0] txIn;
	
	
	Uart8Transmitter(
		.clk(baud_rt),
		.en(txEn),
		.in(txIn),
		.out(txOut),
		.done(txDone),
		.busy(txBusy)
	);
	
	// MÁQUINA DE ESTADO PARA UART
	
	localparam HUM = 1, TEMP = 2;
	localparam IDLE = 0, RECEIVING = 1, MEASURING = 2, TRANSMITTING_P1 = 3, TRANSMITTING_P2 = 4, RESET = 5;
	reg [2:0] uart_state;

	always @ (posedge baud_rt) begin
		case(uart_state)
			IDLE: begin
				if(rxBusy) begin
					led <= 3'b001;
					uart_state <= RECEIVING;
				end
			end
			RECEIVING: begin
				if(rxDone) begin
					response <= 8'b00000101;
					measure_mux <= 8'b00010101;
					uart_state <= TRANSMITTING_P1;
					command <= rxOut;
				end
			end
			MEASURING: begin
				rxEn <= 1'b0;
				dhtEn <= 1'b1;
				if(c_done) begin
					case(command)
						4: begin // temperatura
							response <= 8'b00000010;
							measure_mux <= measure[23:16];
						end
						5: begin // umidade
							response <= 8'b00000001;
							measure_mux <= measure[39:32];
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
				led <= 3'b100;
				rxEn <= 1'b1;
				txEn <= 1'b0;
				dhtEn <= 1'b0;
				measure_mux <= 8'b00000000;
				response <= 8'b00000000;
				txIn <= 8'b00000000;
				command <= 8'b00000000; 
				uart_state <= IDLE;
			end
		endcase
	end
	
endmodule