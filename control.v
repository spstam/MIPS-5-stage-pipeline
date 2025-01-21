`include "constants.h"

/************** Main control in ID pipe stage  *************/
module control_main(
                output reg RegDst,
                output reg Branch,  
                output reg MemRead,
                output reg MemWrite,  
                output reg MemToReg,  
                output reg ALUSrc,  
                output reg RegWrite,  
                output reg [1:0] ALUcntrl,  
                input [5:0] opcode);

  always @(*) 
   begin
     case (opcode)
      `R_FORMAT: 
      // The control signal values
          begin 
            RegWrite<=1;
            RegDst<=1;
            ALUSrc<=0;
            Branch<=0;
            MemWrite<=0;
            MemToReg<=0;
            MemRead<=0;
            ALUcntrl<=2'b10;            
          end
       `LW :   
           begin 
            RegWrite<=1;
            RegDst<=0;
            ALUSrc<=1;
            Branch<=0;
            MemWrite<=0;
            MemToReg<=1;
            MemRead<=1;
            ALUcntrl<=2'b00;
           end
        `SW :   
           begin 
            RegWrite<=0;
            RegDst<=0;//x
            ALUSrc<=1;
            Branch<=0;
            MemWrite<=1;
            MemToReg<=0;//x
            MemRead<=0;
            ALUcntrl<=2'b00;
           end
       `BEQ:  
           begin 
            RegWrite<=0;
            RegDst<=0;//x
            ALUSrc<=0;
            Branch<=1;
            MemWrite<=0;
            MemToReg<=0;//x
            MemRead<=0;
            ALUcntrl<=2'b01;
           end
         `ADDI:
            begin
                RegWrite<=1;
                RegDst<=0;
                ALUSrc<=1;
                Branch<=0;
                MemWrite<=0;
                MemToReg<=0;
                MemRead<=0;
                ALUcntrl<=2'b00;
            end
       default:
           begin
            RegWrite<=0;//x
            RegDst<=0;//x
            ALUSrc<=0;//x
            Branch<=0;//x
            MemWrite<=0;//x
            MemToReg<=0;//x
            MemRead<=0;//x
            ALUcntrl<=2'b11;//xx
           end
      endcase
    end // always
endmodule


/**************** Module for Bypass Detection in EX pipe stage goes here  *********/

module bypassDetection(
    output reg [2:0] out1,
    output reg [2:0] out2,
    input MEM_WB_RegWrite,
    input [4:0] MEM_WB_RegisterRd,
    input [4:0] ID_EX_RegisterRs,
    input [4:0] EX_MEM_RegisterRd,
    input EX_MEM_RegWrite,
    input [4:0] ID_EX_RegisterRt
    );

    always @(*) begin
        if((EX_MEM_RegWrite == 1) && (EX_MEM_RegisterRd != 0) && (EX_MEM_RegisterRd == ID_EX_RegisterRs)) begin
             out1=3'b010;
        end else if ((MEM_WB_RegWrite == 1) && (MEM_WB_RegisterRd != 0) && (MEM_WB_RegisterRd == ID_EX_RegisterRs) &&
        ((EX_MEM_RegisterRd != ID_EX_RegisterRs) || (EX_MEM_RegWrite == 0))) begin
            out1=3'b001;
        end 
        else begin
             out1=3'b000;
        end

        if((EX_MEM_RegWrite == 1) && (EX_MEM_RegisterRd != 0) && (EX_MEM_RegisterRd == ID_EX_RegisterRt)) begin
             out2=3'b010;
        end else if ((MEM_WB_RegWrite == 1) && (MEM_WB_RegisterRd != 0) && (MEM_WB_RegisterRd == ID_EX_RegisterRt) &&
        ((EX_MEM_RegisterRd != ID_EX_RegisterRt) || (EX_MEM_RegWrite == 0))) begin
            out2=3'b001;
        end
        else begin
             out2=3'b000;
        end
    end
endmodule


/**************** Module for Stall Detection in ID pipe stage goes here  *********/

module stallDetection(output reg controlMuxSelector,
    output reg IF_IDWrite,
    output reg PC_Write,
    input ID_EX_MemRead,
    input [4:0] ID_EX_RegisterRt,
    input [4:0] IF_ID_RegisterRs,
    input [4:0] IF_ID_RegisterRt
    );
    always @(*)
    begin
        if (ID_EX_MemRead == 1 && ( ID_EX_RegisterRt == IF_ID_RegisterRs || ID_EX_RegisterRt == IF_ID_RegisterRt))
        begin
            controlMuxSelector <= 0;
            IF_IDWrite <= 0;
            PC_Write <= 0; 
        end
        else
        begin
            controlMuxSelector <= 1; 
            IF_IDWrite <= 1; 
            PC_Write <= 1;
        end
    end
endmodule
                       
/************** control for ALU control in EX pipe stage  *************/
module control_alu(output reg [3:0] ALUOp,                  
               input [1:0] ALUcntrl,
               input [5:0] func);

  always @(ALUcntrl or func)  
    begin
      case (ALUcntrl)
        2'b10: 
           begin
             case (func)
              6'b100000: ALUOp  = 4'b0010; // add
              6'b100010: ALUOp = 4'b0110; // sub
              6'b100100: ALUOp = 4'b0000; // and
              6'b100101: ALUOp = 4'b0001; // or
              6'b100111: ALUOp = 4'b1100; // nor
              6'b101010: ALUOp = 4'b0111; // slt
              6'b000000: ALUOp = 4'b0100; //sll
              6'b000100: ALUOp = 4'b0100; //sllv
              default: ALUOp = 4'b0000;       
             endcase 
          end   
        2'b00: 
              ALUOp  = 4'b0010; // add
        2'b01: 
              ALUOp = 4'b0110; // sub
        default:
              ALUOp = 4'b0000;
     endcase
    end
endmodule
