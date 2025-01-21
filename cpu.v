/***********************************************************************************************/
/*********************************  MIPS 5-stage pipeline implementation ***********************/
/***********************************************************************************************/
`include "library.v"
`include "control.v"

module cpu(input clock, input reset);
 reg [31:0] PC; 
 reg [31:0] IFID_PCplus4;
 reg [31:0] IFID_instr;
 reg [31:0] IDEX_rdA, IDEX_rdB, IDEX_signExtend;
 reg [4:0]  IDEX_instr_rt, IDEX_instr_rs, IDEX_instr_rd;                            
 reg        IDEX_RegDst, IDEX_ALUSrc;
 reg [1:0]  IDEX_ALUcntrl;
 reg        IDEX_Branch, IDEX_MemRead, IDEX_MemWrite; 
 reg        IDEX_MemToReg, IDEX_RegWrite;                
 reg [4:0]  EXMEM_RegWriteAddr, EXMEM_instr_rd; 
 reg [31:0] EXMEM_ALUOut;
 reg        EXMEM_Zero;
 reg [31:0] EXMEM_MemWriteData;
 reg        EXMEM_Branch, EXMEM_MemRead, EXMEM_MemWrite, EXMEM_RegWrite, EXMEM_MemToReg;
 reg [31:0] MEMWB_DMemOut;
 reg [4:0]  MEMWB_RegWriteAddr, MEMWB_instr_rd; 
 reg [31:0] MEMWB_ALUOut;
 reg        MEMWB_MemToReg, MEMWB_RegWrite;               
 wire [31:0] instr, ALUInA, ALUInB, ALUOut, rdA, rdB, signExtend, DMemOut, wRegData, PCIncr;
 wire Zero, RegDst, MemRead, MemWrite, MemToReg, ALUSrc, RegWrite, Branch;
 wire [5:0] opcode, func;
 wire [4:0] instr_rs, instr_rt, instr_rd, RegWriteAddr;
 wire [3:0] ALUOp;
 wire [1:0] ALUcntrl;
 wire [15:0] imm;
 wire [31:0] shamt;
 reg [31:0] IDEX_Shamt;
wire PC_Write;
wire IF_IDWrite;
wire controlMuxSelector;
wire  [2:0]muxAluSelector1,muxAluSelector2;


/***************** Instruction Fetch Unit (IF)  ****************/
 always @(posedge clock or negedge reset)
  begin 
    if (reset == 1'b0)begin     
       PC <= -1;  
    end   
    else if (PC == -1)
       PC <= 0;
    else
        if(PC_Write!=0) begin//HU
            PC <= PC + 4;
        end
  end
  
  // IFID pipeline register
 always @(posedge clock or negedge reset)
  begin 
    if(IF_IDWrite == 1'b1) begin//HU
      if (reset == 1'b0)     
        begin
        IFID_PCplus4 <= 32'b0;    
        IFID_instr <= 32'b0;
      end 
      else 
        begin
        IFID_PCplus4 <= PC + 32'd4;
        IFID_instr <= instr;
      end
    end
  end
  
// Instantiation of the Instruction Memory
  
  
    Memory cpu_IMem (
        .clock(clock),
        .reset(reset),
        .ren(1'b1),        
        .wen(1'b0),         
        .addr(PC >> 2),
        .din(32'h0),        
        .dout(instr) 
    );
  

/***************** Instruction Decode Unit (ID)  ****************/

assign opcode = IFID_instr[31:26];
assign func = IFID_instr[5:0];
assign instr_rs = IFID_instr[25:21];
assign instr_rt = IFID_instr[20:16];
assign instr_rd = IFID_instr[15:11];
assign imm = IFID_instr[15:0];
assign shamt = {{27{1'b0}},IFID_instr[10:6]};
assign signExtend = {{16{imm[15]}}, imm};

// Register file
RegFile cpu_regs(clock, reset, instr_rs, instr_rt, MEMWB_RegWriteAddr, MEMWB_RegWrite, wRegData, rdA, rdB);
  // IDEX pipeline register
 always @(posedge clock or negedge reset)
  begin 
    if (reset == 1'b0)
      begin
       IDEX_rdA <= 32'b0;    
       IDEX_rdB <= 32'b0;
       IDEX_signExtend <= 32'b0;
       IDEX_instr_rd <= 5'b0;
       IDEX_instr_rs <= 5'b0;
       IDEX_instr_rt <= 5'b0;
       IDEX_RegDst <= 1'b0;
       IDEX_ALUcntrl <= 2'b0;
       IDEX_ALUSrc <= 1'b0;
       IDEX_Branch <= 1'b0;
       IDEX_MemRead <= 1'b0;
       IDEX_MemWrite <= 1'b0;
       IDEX_MemToReg <= 1'b0;                  
       IDEX_RegWrite <= 1'b0;
       IDEX_Shamt <= 5'b0;
    end 
    else 
      begin
            IDEX_rdA <= rdA;
            IDEX_rdB <= rdB;
            IDEX_signExtend <= signExtend;
            IDEX_instr_rd <= instr_rd;
            IDEX_instr_rs <= instr_rs;
            IDEX_instr_rt <= instr_rt;
            IDEX_RegDst <= RegDst;
            IDEX_ALUcntrl <= ALUcntrl;
            IDEX_ALUSrc <= ALUSrc;
            IDEX_Branch <= Branch;
            IDEX_MemRead <= MemRead;
            IDEX_MemWrite <= MemWrite;
            IDEX_MemToReg <= MemToReg;                  
            IDEX_RegWrite <= RegWrite;
            IDEX_Shamt <= shamt;
        end

    if(controlMuxSelector==0)begin//HU
      IDEX_RegDst <=0;
      IDEX_Branch <=0;
      IDEX_MemRead <=0;
      IDEX_MemWrite <=0; 
      IDEX_MemToReg <=0;
      IDEX_ALUSrc <=0;
      IDEX_RegWrite <=0;
      IDEX_ALUcntrl <= 2'b0;
    end
   end

// Main Control Unit
control_main control_main (
                  RegDst,
                  Branch,
                  MemRead,
                  MemWrite,
                  MemToReg,
                  ALUSrc,
                  RegWrite,
                  ALUcntrl,
                  opcode);

// Instantiation of Control Unit that generates stalls

stallDetection Stall(
    controlMuxSelector,
    IF_IDWrite,
    PC_Write,
    IDEX_MemRead,
    IDEX_instr_rt,
    instr_rs,
    instr_rt
);    
/***************** Execution Unit (EX)  ****************/
                 
assign ALUInA = ((IDEX_signExtend[5:0]== 6'b0) && (ALUOp==4'b0100)) ? IDEX_Shamt : IDEX_rdA; //CHECK IF FUNC==6'b0
assign ALUInB =  IDEX_rdB;

//  ALU
ALU  #(32) cpu_alu(ALUOut, Zero,
  (muxAluSelector1==3'b010)?  EXMEM_ALUOut : ((muxAluSelector1==3'b001) ? wRegData : ALUInA),
 (IDEX_ALUSrc == 1'b0) ? ((muxAluSelector2==3'b010)? EXMEM_ALUOut :((muxAluSelector2==3'b001) ? wRegData : ALUInB)) : IDEX_signExtend,
  ALUOp);

assign RegWriteAddr = (IDEX_RegDst==1'b0) ? IDEX_instr_rt : IDEX_instr_rd;

 // EXMEM pipeline register
 always @(posedge clock or negedge reset)
  begin 
    if (reset == 1'b0)     
      begin
       EXMEM_ALUOut <= 32'b0;    
       EXMEM_RegWriteAddr <= 5'b0;
       EXMEM_MemWriteData <= 32'b0;
       EXMEM_Zero <= 1'b0;
       EXMEM_Branch <= 1'b0;
       EXMEM_MemRead <= 1'b0;
       EXMEM_MemWrite <= 1'b0;
       EXMEM_MemToReg <= 1'b0;                  
       EXMEM_RegWrite <= 1'b0;
      end 
    else 
      begin
       EXMEM_ALUOut <= ALUOut;    
       EXMEM_RegWriteAddr <= RegWriteAddr;
       EXMEM_MemWriteData <= ((muxAluSelector2==3'b010)? EXMEM_ALUOut : (muxAluSelector2==3'b001) ? wRegData : ALUInB);
       EXMEM_Zero <= Zero;
       EXMEM_Branch <= IDEX_Branch;
       EXMEM_MemRead <= IDEX_MemRead;
       EXMEM_MemWrite <= IDEX_MemWrite;
       EXMEM_MemToReg <= IDEX_MemToReg;                  
       EXMEM_RegWrite <= IDEX_RegWrite;
      end
  end
  
  // ALU control
  control_alu control_alu(ALUOp, IDEX_ALUcntrl, IDEX_signExtend[5:0]);
  
   // TO FILL IN: Instantiation of control logic for Forwarding goes here 

    bypassDetection bypass(
      muxAluSelector1,
      muxAluSelector2,
      MEMWB_RegWrite,
      MEMWB_RegWriteAddr,
      IDEX_instr_rs,
      EXMEM_RegWriteAddr,
      EXMEM_RegWrite,
      IDEX_instr_rt
    );

  
/***************** Memory Unit (MEM)  ****************/  

// Data memory 1KB
// Instantiation of the Data Memory

   Memory cpu_DMem(
        .clock(clock),
        .reset(reset),
        .ren(EXMEM_MemRead),
        .wen(EXMEM_MemWrite),
        .addr(EXMEM_ALUOut),
        .din(EXMEM_MemWriteData),
        .dout(DMemOut)
    );


// MEMWB pipeline register
 always @(posedge clock or negedge reset)
  begin 
    if (reset == 1'b0)     
      begin
       MEMWB_DMemOut <= 32'b0;    
       MEMWB_ALUOut <= 32'b0;
       MEMWB_RegWriteAddr <= 5'b0;
       MEMWB_MemToReg <= 1'b0;                  
       MEMWB_RegWrite <= 1'b0;
      end 
    else 
      begin
       MEMWB_DMemOut <= DMemOut;
       MEMWB_ALUOut <= EXMEM_ALUOut;
       MEMWB_RegWriteAddr <= EXMEM_RegWriteAddr;
       MEMWB_MemToReg <= EXMEM_MemToReg;                  
       MEMWB_RegWrite <= EXMEM_RegWrite;
      end
  end

  
  
  

/***************** WriteBack Unit (WB)  ****************/
// Write Back logic 

assign wRegData = ((MEMWB_MemToReg) ? MEMWB_DMemOut : MEMWB_ALUOut ); 

endmodule
