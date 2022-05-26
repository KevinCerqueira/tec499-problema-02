module dht11(start_sensor, sensor_data, clk_1mhz, sensor_pin, error);

inout sensor_pin;
//Registradores de controle do tristate
reg dir, dht_out;
wire dht_in;

input start_sensor, clk_1mhz;
output reg error;

output [0:39]sensor_data;
reg [0:39]sensor_data;

reg [0:3]state;
		parameter IDLE = 0,
					 START_0 = 1,
					 START_1 = 2,
					 RESPONCE = 3,
					 SYNC_0 = 4,
					 SYNC_1 = 5,
					 DATA = 6,
					 STOP = 7,
					 ERROR = 8;
					 
integer counter;
integer counter_data;

tris tris_0(
	.port(sensor_pin),
	.dir(dir),
	.dht_out(dht_out),
	.dht_in(dht_in)
);

					 
always @(posedge clk_1mhz) begin
case(state)
	IDLE:
		begin
			//Habilita canal para envio
			dir <= 1'b1;
			if(start_sensor)begin
				state <= START_0;
				error <= 1'b0;
			end else begin
				//Coloca a porta em modo saída e envia um sinal alto.
				dht_out <= 1'b1;
				state <= IDLE;
			end
		end
	START_0:
		begin
			if(counter > 18000) begin
				counter = 0;
				state <= START_1;
			end
			else begin
				//Envia um sinal baixo por 18ms para iniciar comunicação.
				dht_out <= 1'b0;
				counter = counter + 1;
				state <= START_0;
			end
		end
	START_1:
		begin
			if(counter > 20) begin
				counter = 0;
				dir = 1'b0;
				state <= RESPONCE;
			end
			else begin
				//Manda um sinal alto de 20us.
				dht_out <= 1'b1;
				counter = counter + 1;
				state <= START_1;
			end
		end
	RESPONCE:
		begin	
			//Aguarda 60us de delay ou até o canal for alterado pelo sensor
			if(counter < 60 && dht_in == 1'b1) begin
				counter = counter + 1;
				state <= RESPONCE;
			end else begin
				if(dht_in == 1'b1) begin
					counter = 0;
					state <= ERROR;
				end else begin
					counter = 0;
					state <= SYNC_0;
				end
			end
		end
	SYNC_0:
		begin
			//bloco de sincronização
			//Aguarda 80us de sinal baixo enviado pelo sensor
			if(dht_in == 1'b0 && counter < 88) begin
				counter = counter + 1;
				state <= SYNC_0;
			end else begin
				if(dht_in == 1'b0) begin
					counter = 0;
					state <= ERROR;
				end else begin
					counter =0;
					state <= SYNC_1;
				end
			end
		end
	SYNC_1:
		begin
			//Aguarda 80us de sinal alto enviado pelo sensor
			if(dht_in == 1'b1 && counter < 88) begin
				counter = counter + 1;
				state <= SYNC_1;
			end else begin
				if(dht_in == 1'b1) begin
					counter = 0;
					state <= ERROR;
				end else begin
					counter = 0;
					state <= DATA;
				end
			end
		end
	DATA:
		begin
			//leitura de dados do canal do sensor
			//Conta o tempo de cada pulso alto que segue um pulso baixo
			if(dht_in == 1'b0 && counter != 0) begin
				
				
				//Pulsos maiores que 50us significam '1'
				//E Pulsos menores que 30us significam '0'
				if(counter > 50) 
					sensor_data[counter_data] = 1'b1;
				 else 
					sensor_data[counter_data] = 1'b0;
					
				
				counter_data = counter_data + 1;	
				counter = 0;
			
				if(counter_data > 39) begin
					counter_data = 0;
					state <= STOP;
				end else begin
					state <= DATA;
				end
				
			end else if (dht_in == 1'b1) begin
			
				counter = counter + 1;
				//Caso o sinal alto dure mais que 32ms houve um erro.
				if(counter > 32000) begin
					counter = 0;
					state <= ERROR;
				end else begin
					state <= DATA;
				end
			end else begin
				state <= DATA;
			end
		end
	STOP:
		begin
			//Envia sinal de finalização da leitura do sensor
			//Fecha leitura do canal e coloca-o em sinal alto
			dir = 1'b1;
			dht_out = 1'b1;
			state <= IDLE;
		end
	ERROR:
		begin
			error <= 1'b1;
			dir = 1'b1;
			dht_out = 1'b1;
			state <= IDLE;

		end
endcase
end


endmodule



module tris(
	port,
	dir,
	dht_out,
	dht_in
);
	inout port;
	input dir, dht_out;
	output dht_in;
	
	assign port = dir ? dht_out : 1'bz;
	assign dht_in = dir ? 1'bz : port;
	
endmodule


