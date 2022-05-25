module dht11(
	input clock,
	inout dht_data,
	input enable,
	output reg [15:0] result,
	output wire [7:0] check_sum,
	input [1:0] request,
	output reg done,
	output wire err
);

reg MEASURE_STATE;
parameter IDLE = 0, ENABLED = 1;

reg sensor_en;
wire[7:0] hum_int;
wire [7:0] hum_float;
wire [7:0] temp_int;
wire [7:0] temp_float;
wire busy;
reg sensor_rst;

dht11_controller sensor(
	.clk(clock),
	.en(en),
	.dht_data(dht_data),
	.hum_int(hum_int),
	.hum_float(hum_float),
	.temp_int(temp_int),
	.temp_float(temp_float),
	.busy(busy),
	.error(err),
	.check_sum(check_sum),
	.rst(sensor_rst)
);

always @(posedge clock) begin
	if(enable) begin
		MEASURE_STATE = ENABLED;
		if (request > 2'b00) begin
			sensor_en <= 1'b1;
			case (request)
				2'b01: begin //temperatura
					result[15:8] <= temp_int;
					result[7:0] <= temp_float;
				end
				2'b10: begin //humidade
					result[15:8] <= hum_int;
					result[7:0] <= hum_float;
				end
			endcase
		end
		else begin
			if(err) begin
				sensor_rst <= 1'b1;
				MEASURE_STATE = IDLE;
			end
		end
	end
	else begin
		MEASURE_STATE = IDLE;
		sensor_rst <= 1'b0;
	end
end

endmodule
