module dht11_controller(
	input clk,
	input en,
	input rst,
	inout dht_data,
	output [7:0] hum_int,
	output [7:0] hum_float,
	output [7:0] temp_int,
	output [7:0] temp_float,
	output [7:0] check_sum,
	output reg busy,
	output reg error
);

reg dht_out, dir, busy_reg;

reg [25:0] counter;
reg [5:0] index;
reg [39:0] data;

wire dht_in;

tristate tris(
	.port(dht_data),
	.dir(dir),
	.send(dht_out),
	.read(dht_in)
);

assign hum_int[7] = data[0];
assign hum_int[6] = data[1];
assign hum_int[5] = data[2];
assign hum_int[4] = data[3];
assign hum_int[3] = data[4];
assign hum_int[2] = data[5];
assign hum_int[1] = data[6];
assign hum_int[0] = data[7];

assign hum_float[7] = data[8];
assign hum_float[6] = data[9];
assign hum_float[5] = data[10];
assign hum_float[4] = data[11];
assign hum_float[3] = data[12];
assign hum_float[2] = data[13];
assign hum_float[1] = data[14];
assign hum_float[0] = data[15];

assign temp_int[7] = data[16];  
assign temp_int[6] = data[17];
assign temp_int[5] = data[18];
assign temp_int[4] = data[19];
assign temp_int[3] = data[20];
assign temp_int[2] = data[21];
assign temp_int[1] = data[22];
assign temp_int[0] = data[23]; 

assign temp_float[7] = data[24];
assign temp_float[6] = data[25];
assign temp_float[5] = data[26];
assign temp_float[4] = data[27];
assign temp_float[3] = data[28];
assign temp_float[2] = data[29];
assign temp_float[1] = data[30];
assign temp_float[0] = data[31];	

assign check_sum[7] =  data[32];
assign check_sum[6] =  data[33];
assign check_sum[5] =  data[34];
assign check_sum[4] =  data[35];
assign check_sum[3] =  data[36];
assign check_sum[2] =  data[37];
assign check_sum[1] =  data[38];
assign check_sum[0] =  data[39];


reg [3:0] STATE; // Máquina de estados

//Definição de estados
parameter S0=1, S1=2, S2=3, S3=4, S4=5, S5=6, S6=7, S7=8, S8=9, S9=10, STOP=0, START=11;

always @(posedge clk) 
	begin: FSM
		 if (en == 1'b1) 
		 begin
			  if(rst == 1'b1)
			  begin
					dht_out <= 1'b1;
					busy <= 1'b0;
					counter <= 26'b00000000000000000000000000;
					data <= 40'b0000000000000000000000000000000000000000;
					dir <= 1'b1;
					error <= 1'b0;
					STATE <= START;
			  end 
			  else begin
					case (STATE)
						 START: 
							  begin
									busy <= 1'b1;
									dir <= 1'b1;
									dht_out <= 1'b1;
									STATE <= S0;
							  end
						 
						 S0:
							  begin
									dir <= 1'b1;
									dht_out <= 1'b1; 
									busy <= 1'b1; 
									error <= 1'b0;
									if (counter < 1800000) 
									begin
										 counter <= counter +1'b1;    
									end else begin
										 counter <= 26'b00000000000000000000000000;
										 STATE <= S1;
									end
							  end
						 S1:
							  begin
									dht_out <= 1'b0; 
									busy <= 1'b1; 
			  
									if (counter < 1800000) 
									begin
										 counter <= counter +1'b1;    
									end else begin
										 counter<=26'b00000000000000000000000000;
										 STATE <= S2;
									end
							  end

						 S2:
							  begin
									dht_out <= 1'b1; 
						 
			  
									if (counter < 20000) 
									begin
										 counter <= counter +1'b1;    
									end else begin
										 dir <= 1'b0;
										 STATE <= S3;
									end
							  end

						 S3:
							  begin
									if (counter < 6000 && dht_in == 1'b1)
									begin
										 counter <= counter +1'b1;
										 STATE<=S3;    
									end else begin
										 if (dht_in == 1'b1) 
										 begin
											  error <= 1'b1;
											  counter<= 26'b00000000000000000000000000;
											  STATE<=S4;
										 end
									end
							  end

						 S4:
							  begin
									if (counter < 8800 && dht_in == 1'b0)
									begin
										 counter <= counter +1'b1;
										 STATE<=S4;    
									end else begin
										 if (dht_in == 1'b0) 
										 begin
											  error <= 1'b1;
											  counter<= 26'b00000000000000000000000000;
											  STATE<=S5;
										 end else begin
											  STATE<=S5;
											  counter<= 26'b00000000000000000000000000;
										 end
									end
							  end

						 S5:
							  begin
									if (counter < 8800 && dht_in == 1'b1)
									begin
										 counter <= counter +1'b1;
										 STATE<=S5;    
									end else begin
										 if (dht_in == 1'b1) 
										 begin
											  error <= 1'b1;
											  counter<= 26'b00000000000000000000000000;
											  STATE<=STOP;
										 end else begin
											  STATE<=S6;
											  counter<= 26'b00000000000000000000000000;
										 end
									end
							  end

						 S6:
							  begin
									if (dht_in == 1'b0) begin

										 STATE<=S7;    
									end 
									else begin
											  error <= 1'b1;
											  counter<= 26'b00000000000000000000000000;
											  STATE<=STOP;
									end
							  end
						 S7:
							  begin
									if (dht_in == 1'b1)
									begin
										 counter<= 26'b00000000000000000000000000;
										 STATE<=S8;    
									end else begin
											  if (counter<3200000)
											  begin
													counter<=counter+1'b1;
													STATE<=S7;    
											  end else begin
													counter<= 26'b00000000000000000000000000;
													error <= 1'b1;
													STATE<=STOP;    
											  end 
										 end
							  end

						 S8:
							  begin
									if (dht_in == 1'b0)
									begin
										 if (counter>5000)
										 begin
											data[index]<=1'b1;
										 end else begin
											data[index]<=1'b0;
										 end
										 if (index<39) 
										 begin
											  counter<= 26'b00000000000000000000000000;
											  STATE<=S9;
										 end else begin
											  error <= 1'b0;
											  STATE<=STOP;  
										 end  
									end else begin
										 counter<=counter+1'b1;
										 if (counter>3200000) 
										 begin
											 error <= 1'b0;
											 STATE<=STOP; 
										 end
												  
										 end
							  end

						 S9:
							  begin
									index<=index+1'b1;
									STATE <= S6;
							  end

						 STOP: 
							  begin
									STATE <= STOP;
									if (error == 1'b0) begin
										 dht_out<=1'b1;
										 busy<=1'b0;
										 counter<= 26'b00000000000000000000000000;
										 dir<=1'b1;
										 error<= 1'b0;
										 index<= 6'b000000;  
									end 
									else begin
										if (counter<3200000) begin
													data<=40'b0000000000000000000000000000000000000000;
													counter<=counter+1'b1;
													error<=1'b1;
													busy<=1'b1;
													dir<=1'b0;
										end 
										else begin
													error<=1'b0;
										end    
									end  
								end 

					endcase
		 end
		 
	end
end

endmodule
