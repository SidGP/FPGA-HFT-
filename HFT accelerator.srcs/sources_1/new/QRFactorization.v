`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/30/2024 09:55:53 AM
// Design Name: 
// Module Name: QRFactorization
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// does QR factorization to give Q and R such that QR = Matrix. 
module QRFactorization(
    input clk, 
    input Load, 
    input [255:0] K, 
    
    output reg [255:0] R,  
    output reg [255:0] Q, 
    output reg UnLoad
    );
    
  
    reg [2:0] Stage; 
  
    wire [127:0]X1in; 
    wire [127:0]X2in;  
    wire [127:0]Y1in; 
    wire [127:0]Y2in;
    
    wire [127:0]X1out; 
    wire [127:0]X2out;  
    wire [127:0]Y1out; 
    wire [127:0]Y2out;

//// remaining variables. 
    reg [511:0] MatrixIntermediate; 
    wire NextStage1; 
    wire NextStage2; 
    reg LoadCT1; 
    reg LoadCT2; 
    
 // Declaring rows.     
    wire [127:0]R1; 
    assign R1 = MatrixIntermediate[127:0];  
    wire [127:0] R2; 
    assign R2 = MatrixIntermediate[255:128]; 
    wire [127:0] R3; 
    assign R3 = MatrixIntermediate[383:256]; 
    wire [127:0] R4; 
    assign R4 = MatrixIntermediate[511:384]; 
    
//Input wires for Cordic
    assign X1in = Stage[1] ? (Stage[0] ? R3>>32 : R2>>16) : (Stage[0] ? R1 : R1); 
    assign Y1in = Stage[1] ? (Stage[0] ? R4>>32 : R3>>16) : (Stage[0] ? R3 : R2); 
    assign X2in = Stage[0] ? R2>>16 : R3; 
    assign Y2in = Stage[0] ? R4>>16 : R4; 


// Instantaitng Cordics.   
    Cordic3 CT1(clk, LoadCT1, X1in, Y1in, X1out, Y1out, NextStage1);
    Cordic3 CT2(clk, LoadCT2, X2in, Y2in, X2out, Y2out, NextStage2);        
 
    reg StageChanged; 
    
// Control Logic.     
    always @ (posedge clk) begin 
    
        // Load MatrixIntermediate, Set Stage. 
        if (Load) begin 
            MatrixIntermediate = {64'h003e8_0000_0000_0000, K[255:192], 
                                  64'h0000_003e8_0000_0000, K[191:128],
                                  64'h0000_0000_003e8_0000, K[127:64], 
                                  64'h0000_0000_0000_003e8 , K[63:0]} ; 
            Stage = 3'd0; 
            LoadCT1 = 1; 
            LoadCT2 = 1; 
            UnLoad = 0; 
            StageChanged = 0; 
            end 
         
         //UnLoad 
         else if (Stage == 3'b100) begin 
            UnLoad =1; 
            Q = {MatrixIntermediate[511:448], MatrixIntermediate[383:320], MatrixIntermediate[255:192], MatrixIntermediate[127:64]};
            R = {MatrixIntermediate[447:384], MatrixIntermediate[319:256], MatrixIntermediate[191:128], MatrixIntermediate[63:0]}; 
         end  
         
         //Update to next Stage. 
         else if (NextStage1 && NextStage2 && ~StageChanged) begin 
                case (Stage)
                3'b000: begin 
                        MatrixIntermediate[127:0] = X1out; 
                        MatrixIntermediate[255:128] = Y1out; 
                        MatrixIntermediate[383:256] = X2out; 
                        MatrixIntermediate[511:384] = Y2out;                 
                        LoadCT1 = 1; LoadCT2 = 1; 
                        Stage = 3'b001;
                        StageChanged = 1; 
                        end 
                3'b001: begin 
                        MatrixIntermediate[127:0] = X1out; 
                        MatrixIntermediate[383:256] = Y1out; 
                        MatrixIntermediate[255:128] = X2out<<16; 
                        MatrixIntermediate[511:384] = Y2out<<16;                 
                        LoadCT1 = 1; LoadCT2 = 1; 
                        Stage = 3'b010; 
                        StageChanged = 1; 
                        end
                3'b010: begin 
                        MatrixIntermediate[255:128] = X1out<<16; 
                        MatrixIntermediate[383:256] = Y1out<<16;   
                        LoadCT1 = 1; LoadCT2 = 0; 
                        Stage = 3'b011;
                        StageChanged = 1; 
                        end
                3'b011: begin 
                        MatrixIntermediate[383:256] = X1out<<32; 
                        MatrixIntermediate[511:384] = Y1out<<32;                
                        LoadCT1 = 1; LoadCT2 =0; 
                        Stage = 3'b100; 
                        StageChanged =1; 
                        end 
                3'b100: begin 
                        LoadCT1 =0; LoadCT2 =0; 
                        StageChanged = 1; 
                        end 
                default: begin 
                        LoadCT1 = 0; LoadCT2 =0;
                        end  
                endcase 
        end 
        
        else begin 
            LoadCT1 = 0; 
            LoadCT2 = 0; 
            StageChanged =0; 
        end 
    end 
endmodule
