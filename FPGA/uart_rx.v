module uart_rx
  #(parameter CLKS_PER_BIT = 6944) // 50mhz/7200
  (
   input        clk,
	input			en,
   input        rxIn,
   output reg rxDone,
	output reg [12:0]     r_Clock_Count,
   output reg [7:0] rxOut
   );
   
  parameter IDLE         = 3'b000;
  parameter RX_START_BIT = 3'b001;
  parameter RX_DATA_BITS = 3'b010;
  parameter RX_STOP_BIT  = 3'b011;
  parameter CLEANUP      = 3'b100;
  
  reg [2:0]     r_Bit_Index   = 0; //8 bits total
  reg [2:0]     r_SM_Main     = 3'b000;
  
  
  // Purpose: Control RX state machine
  always @(posedge clk) begin
	 if(!en) begin
		r_SM_Main <= 3'b100;
	 end
    case (r_SM_Main)
      3'b000 :
        begin
          rxDone      <= 1'b0;
          r_Clock_Count <= 0;
          r_Bit_Index   <= 0;
          
          if (rxIn == 1'b0) begin     // Start bit detected
            r_SM_Main <= 3'b001;
          end
        end
      
      // Check middle of start bit to make sure it's still low
      3'b001 :
        begin
          if (r_Clock_Count == (CLKS_PER_BIT-1)/2)
          begin
            if (rxIn == 1'b0)
            begin
              r_Clock_Count <= 0;  // reset counter, found the middle
              r_SM_Main     <= 3'b010; // RX_DATA_BITS;
            end
            else
              r_SM_Main <= 3'b000;
          end
          else
          begin
            r_Clock_Count <= r_Clock_Count + 1;
            r_SM_Main     <= 3'b001;
          end
        end // case: RX_START_BIT
      
      
      // Wait CLKS_PER_BIT-1 clock cycles to sample serial data
      3'b010: //RX_DATA_BITS :
        begin
          if (r_Clock_Count < CLKS_PER_BIT-1)
          begin
            r_Clock_Count <= r_Clock_Count + 1;
            r_SM_Main     <= 3'b010; //RX_DATA_BITS;
          end
          else
          begin
            r_Clock_Count          <= 0;
            rxOut[r_Bit_Index] <= rxIn;
            
            // Check if we have received all bits
            if (r_Bit_Index < 7)
            begin
              r_Bit_Index <= r_Bit_Index + 1;
              r_SM_Main   <= 3'b010; //RX_DATA_BITS;
            end
            else
            begin
              r_Bit_Index <= 0;
              r_SM_Main   <= 3'b011; // RX_STOP_BIT;
            end
          end
        end // case: RX_DATA_BITS
      
      
      // Receive Stop bit.  Stop bit = 1
      3'b011 : //RX_STOP_BIT
        begin
          // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
          if (r_Clock_Count < CLKS_PER_BIT-1)
          begin
            r_Clock_Count <= r_Clock_Count + 1;
     	    r_SM_Main     <= 3'b011; //RX_STOP_BIT;
          end
          else
          begin
       	    rxDone      <= 1'b1;
            r_Clock_Count <= 0;
            r_SM_Main     <= 3'b100; //CLEANUP;
          end
        end // case: RX_STOP_BIT
      
      
      // Stay here 1 clock
      3'b100: //CLEANUP :
        begin
          r_SM_Main <= 3'b000; //IDLE;
          rxDone  <= 1'b0;
        end
      
      
      default :
        r_SM_Main <= 3'b000; // IDLE;
      
    endcase
  end    
  
endmodule // UART_RX