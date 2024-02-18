// the first step is to define the global variables outside the module 
reg [2:0]current_state;  // 0--> Instruction Fetch 1--> Instruction Decode 2-->Execution 3--> Memory access 4--> Write Back Data 
reg [2:0]next_state; // takes the same range of values of the current_state
reg [31:0]IR;  // ISA of 32-bit 

module multiCycleProcessor(	// determine the control signals 
input clk,input reset,
output reg [1:0] PcCont,output reg ExtOp,
output reg 	Wport1,
output reg  Wport2,output reg Alusrc,output reg [1:0] AluOp1,
output reg MemAdd,output reg DataIn,output reg  Mrd,
output reg  MWr, output reg Wbdata , output reg SPorAlu2,
output reg AluSpOp,

///Instruction Decode Part 
output reg [31:0] Rs1, // (Bus A )Output data from register 1
output reg [31:0] Rs2, // (Bus B) Output data from register 2
output reg [31:0] Rd, // (Bus W) Output data from register 3   

 ///ALU Part
output reg [31:0] outputOfALU, // Just to verify that the ALU works properly 
///immediate16 Part
output reg [31:0]extended_immediate16, 
///immediate26 Part
);			 

 // variables will be used in the instruction fetch stage  
reg [31:0] InstMem [0:31]; 	 // bit width of each element in the array (InstMem) is 32-bit 	
//and The range [31:0] indicates that the least significant bit (LSB) is 0, and the most significant bit (MSB) is 31.
reg [31:0] PC;
reg [31:0] SP;  
reg [5:0] OpCode1; 

// Decode Stage
reg [31:0] mux_2Output;
reg [31:0] toRegFile; // the data will be stored in the register file 
reg [3:0] RegisterFile[0:31];  // 16 Registers 32-bit each 
reg [3:0] RdAddress; // Address for Rd
reg [3:0] Rs1Address; // Address for RS1
reg [3:0] Rs2Address; // Address for RS2   
reg [31:0] PCmuxOut;  // the decided value of the PC   
reg [31:0] sequentialPC ;
reg [31:0] jumpTargetAddress;
reg [31:0] branchTargetAddress;
// Alu Part
reg [31:0] firstOperand;
reg [31:0] secondOperand; 
reg zero;
reg overflow;  

// Memory access part  
reg [31:0] address,data_in;	 // data_in represent the data itself which will enter the memory not the selection	  the same for address 
reg [31:0] secondAddress,SPfinalResult; // this represent the output value of the SP mux 
reg [31:0] data_out;
reg [31:0] data_memory [31:0];	 

//Extenders 16 and 26
reg [15:0] immediate16; 
reg [25:0] immediate26;	  

// Stack Pointer Part 

reg [31:0] SP_AluResult; // increment or decrement the SP 
reg [31:0] out_SP_mux; // to select either sp or alu result

// variable i for the loop 
reg [7:0] i; // Example declaration for an 8-bit register "i"

initial
	begin	 
		InstMem[0]= 32'h14854000;//LW  0000000100001010100000000000000
		//InstMem[1]= 32'h04890000;//ADD
		//InstMem[2]= 32'h01980000;//AND
		//InstMem[3]= 32'h2998C000;//BEQ
		//InstMem[4]= 32'h3D800000;//PUSH
		//InstMem[5]= 32'h18048001;//LW.POI
		//InstMem[6]= 32'h40800000;//POP
		//InstMem[7]= 32'h09288000;//SUB
		//InstMem[8]= 32'hC4480000;//BGT
		//InstMem[9]= 32'h0C000000;//ANDI
		//InstMem[10]= 32'h10440000;//ADDI
		//InstMem[11]= 32'h1C518000;//SW
		//InstMem[12]= 32'h0489C000;//BLT
		//InstMem[13]= 32'h34000028;//JMP
		//InstMem[14]= 32'h2D88000C;//CALL
		//InstMem[15]= 32'h2E98C000;//BNE
		//InstMem[16]= 32'h38000000;//RET
		
	end	
	// addapt the clk setting to move between states 
	always @(posedge clk) 
case (current_state) 
0: 
next_state = 1;
1: 
next_state = 2;
2: 
next_state = 3;
3: 
next_state = 4;
4: 
next_state = 0;
endcase

  // change the current state to it's next at each clk	positive edge
always @(posedge clk) 
current_state = next_state;	 


always @(posedge clk, posedge reset)
if (reset) 
	begin 
    current_state = 4;
     PC = 32'h00000000;
     Rs1 = 32'd0;
     Rs2 = 32'd0;
     Rd = 32'd0;
     mux_2Output = 32'h00000000;
     for (i = 0; i < 31; i = i + 1)
     RegisterFile[i] <= 32'h00000000;
end  

///////////// Start Instruction tour Besmellah /////////////////////////	 
	else if (current_state == 0) begin	
//instruction fetch
IR = InstMem[PC]; // the current instruction is the value of PC
OpCode1 = IR[31:26];	// the 6 MSB from IR always for the opcode  
 
	
if (OpCode1 == 6'b000000)  begin ///AND
	
		PcCont = 2'b00;
		Alusrc = 2'b00;
		AluOp1 = 2'b01;
		Mrd = 1'b0;
        MWr = 1'b0; 		
		Wport1 = 1'b1;	
		Wport2 = 1'b0;
        Wbdata = 1'b0;
		
end	   

else if (OpCode1 == 6'b000001)	begin//ADD
		PcCont = 2'b00;
       	Alusrc = 2'b00;
		AluOp1 = 2'b00;
		Mrd = 1'b0;
        MWr = 1'b0; 		
		Wport1 = 1'b1;	
		Wport2 = 1'b0;
        Wbdata = 1'b0;
		
end		  

else if (OpCode1 == 6'b000010) begin	 //SUB
	
	    PcCont = 2'b00;
		Alusrc = 2'b00;
		AluOp1 = 2'b10;
		Mrd = 1'b0;
        MWr = 1'b0; 	
		Wport1 = 1'b1;	
		Wport2 = 1'b0;
        Wbdata = 1'b0;
			  
end	    

else if (OpCode1== 6'b000011) begin	 //ANDI
	
	    PcCont = 2'b00;
		ExtOp = 1'b0;
		Alusrc = 2'b01;
		AluOp1 = 2'b01;
		Mrd = 1'b0;
        MWr = 1'b0; 		
		Wport1 = 1'b1;	
		Wport2 = 1'b0;
        Wbdata = 1'b0;
		
end	  

else if (OpCode1 == 6'b000100) begin	//ADDI 
	
	    PcCont = 2'b00;
		ExtOp = 1'b0;
		Alusrc = 2'b01;
		AluOp1 = 2'b00;
		Mrd = 1'b0;
        MWr = 1'b0; 		
		Wport1 = 1'b1;	
		Wport2 = 1'b0;
        Wbdata = 1'b0;
			
end		   

else if (OpCode1 == 6'b000101) begin   //LW  			
	
	    PcCont = 2'b00;
		ExtOp = 1'b1;
		Alusrc = 2'b01;
		AluOp1 = 2'b00;
		Mrd = 1'b1;
        MWr = 1'b0; 
		MemAdd= 1'b0;
		Wport1 = 1'b1;	
		Wport2 = 1'b0;
        Wbdata = 1'b1;
			
end	  

else if (OpCode1 == 6'b000110) begin   //LW.POI  			
	
	    PcCont = 2'b00;
		ExtOp = 1'b1;
		Alusrc = 2'b01;
		AluOp1 = 2'b00;
		Mrd = 1'b1;
        MWr = 1'b0;
		MemAdd= 1'b0;
		Wport1 = 1'b1;	
		Wport2 = 1'b1;
        Wbdata = 1'b1;
		
end		  

else if (OpCode1 == 6'b000111) begin   //SW 					
		PcCont = 2'b00;
		ExtOp = 1'b1;
		Alusrc = 2'b01;
		AluOp1 = 2'b00;
		Mrd = 1'b0;
        MWr = 1'b1; 
		MemAdd= 1'b0;
		DataIn = 1'b0;
		Wport1 = 1'b0;	
		Wport2 = 1'b0;    
			 
end		  

else if (OpCode1 == 6'b001000) begin    //BGT 					
		PcCont = 2'b01;
		ExtOp = 1'b1;
		Alusrc = 2'b10;
		AluOp1 = 2'b10;
		Mrd = 1'b0;
        MWr = 1'b0; 		
		Wport1 = 1'b0;	
		Wport2 = 1'b0;    	 
end		  


		else if (OpCode1 == 6'b001001) begin    //BLT 					
		PcCont = 2'b01;
		ExtOp = 1'b1;
		Alusrc = 2'b10;
		AluOp1 = 2'b10;
		Mrd = 1'b0;
        MWr = 1'b0; 	
		Wport1 = 1'b0;	
		Wport2 = 1'b0;    
	
end	   
		
else if (OpCode1 == 6'b001010)begin     //BEQ 					
		PcCont = 2'b01;
		ExtOp = 1'b1;
		Alusrc = 2'b10;
		AluOp1 = 2'b10;
		Mrd = 1'b0;
        MWr = 1'b0; 	
		Wport1 = 1'b0;	
		Wport2 = 1'b0;    
		
end	  	 

else if (OpCode1 == 6'b001011)  begin  //BNE 					
		PcCont = 2'b01;
		ExtOp = 1'b1;
		Alusrc = 2'b10;
		AluOp1 = 2'b10;
		Mrd = 1'b0;
        MWr = 1'b0; 		
		Wport1 = 1'b0;	
		Wport2 = 1'b0;    
	 
end	 

else if (OpCode1 == 6'b001100) begin   //JMP 					
		PcCont = 2'b01;
		Mrd = 1'b0;
        MWr = 1'b0; 		
		Wport1 = 1'b0;	
		Wport2 = 1'b0;    
end	   

else if (OpCode1 == 6'b001101) begin   //CALL 					
		PcCont = 2'b01;
		Mrd = 1'b0;
        MWr = 1'b0; 
		MemAdd= 1'b1;
		DataIn = 1'b1;
		Wport1 = 1'b0;	
		Wport2 = 1'b0;    
		SPorAlu2= 1'b1;
		AluSpOp = 1'b0;	
end	   

else if (OpCode1 == 6'b001110)begin    //RET 					
		PcCont = 2'b11;
		Mrd = 1'b0;
        MWr = 1'b0; 		
		Wport1 = 1'b0;	
		Wport2 = 1'b0;    
		SPorAlu2= 1'b0;
		AluSpOp = 1'b1;				
end	 

else if (OpCode1 == 6'b001111) begin   //PUSH 					
		PcCont = 2'b00;
		Mrd = 1'b0;
        MWr = 1'b1; 
		MemAdd= 1'b1;
		DataIn =1'b0;
		Wport1 = 1'b0;	
		Wport2 = 1'b0;    
		SPorAlu2= 1'b1;
		
end	   

else if (OpCode1 == 6'b010000) begin   //POP					
		PcCont = 2'b00;
		Mrd = 1'b1;
        MWr = 1'b0; 
		MemAdd= 1'b1;
		DataIn =1'b1;
		Wport1 = 1'b0;	
		Wport2 = 1'b0;
        Wbdata = 1'b1;
		SPorAlu2= 1'b0;
		AluSpOp = 1'b1;
end	   


end	   // the end of Instruction Fetch stage 	  	

else if (current_state == 1) begin
	
	// Instruction Decode stage 
	// get the values of the extended and unextended immediates 
immediate16 = IR[29:14];
// initialy extend the value of immediate16 to 32-bit with zero's temporarly 
extended_immediate16 = {16'b0000000000000000, immediate16}; // temporarly zero extension   

immediate26 = IR[31:6];	// This value will not be extended 		

// here, we will fill the registers as needed  

RegisterFile[2]=32'h00000003;  // R1=3 
RegisterFile[10]=32'h00000005;  // R3=4 
RegisterFile[4]=32'h0000000E;  // R4=10	   
RegisterFile[5]=32'h00000007; // R5=7 
RegisterFile[8]=32'h00000000; // R8=0 
RegisterFile[9]=32'h00000001; // R9=1

///Getting the addresses for the RS1,RS2,Rd	 	 
RdAddress  = IR[9:6]; // is the address of(Rd) Register (write operand)
Rs1Address = IR[13:10]; //is the address of(Rs1) Register ==> first address for read operand
Rs2Address = IR[17:14]; // is the address of(Rs2) Register ==> second address for read operand

// get the source and the distenation registers from the register file via their addresses 
Rs1 = RegisterFile[Rs1Address];
Rs2 = RegisterFile[Rs2Address];
Rd  = RegisterFile[RdAddress];    

// determine the control signal which will determine the second AluSrc 
case (Alusrc)
 2'b00: mux_2Output = Rs2;
 2'b01: mux_2Output = extended_immediate16; //Output of the Extender 16
 2'b10: mux_2Output = Rd;
endcase    

// determine the control signal which will determine the PC Content
case (PcCont)
 2'b00: PCmuxOut = sequentialPC;  // pc=pc+1
 2'b01: PCmuxOut = branchTargetAddress; 	// pc=pc+sign_ExtImm16	 // this part will be done in PC adder 
 2'b10: PCmuxOut = jumpTargetAddress;	 // pc=concatenation result
 2'b11: PCmuxOut = data_memory[SP];			// pc= stack pointer 
 
endcase  

// determine the control signal which will determine the data_in to access the memory 

case (DataIn) 
	1'b0: data_in=	Rd;	 // ALU RESULT
	1'b1: data_in=	PC+1; // To push up the address of the next instrucion 
	
endcase		 

case (MemAdd) 
	 1'b0: address= outputOfALU;
	 1'b1: address=	 secondAddress;
endcase	  

case (SPorAlu2)   
	 1'b0: secondAddress = SP;
	 1'b1: secondAddress = SPfinalResult; // either SP+1 or SP-1
endcase	 

case (AluSpOp)  
	
	1'b0: SPfinalResult= SP+1;
	1'b1: SPfinalResult= SP-1;
endcase

case (Wbdata)  // to determine the output of the mux in the bottom 
	1'b0: toRegFile= outputOfALU;
	1'b1: toRegFile= data_out; 
endcase	 

// Now we will check if the instruction is JMP, 
	if(OpCode1==6'b001100)begin 
		
		current_state = 4; 
		jumpTargetAddress={PC[31:26],immediate26};	
		PC =jumpTargetAddress;
		
	end	   // the end of JMP Instruction Decode	  
	

// Now we will check if the instruction is CALL, 
	if(OpCode1==6'b001101)begin 
		
		jumpTargetAddress={PC[31:26],immediate26};	
		PC =jumpTargetAddress;
		
	end	   // the end of CALL Instruction Decode	 
	

end    // the end of Instruction Decode stage	 

else if (current_state == 2)  begin 
	// ALU STAGE === Execution  
	
	firstOperand=Rs1; 
	secondOperand= mux_2Output; 
	
	case(AluOp1)
	    2'b00: outputOfALU = firstOperand + secondOperand;     // Addition
	    2'b01: outputOfALU = firstOperand & secondOperand;     // Bitwise AND
	    2'b10: outputOfALU = firstOperand - secondOperand;     // SUBTRACTION
	    default: outputOfALU = 32'b0;                   // Default case: result is 0   
			
	  endcase	 
	  
	  if (outputOfALU==0)begin 
		  
		  zero=1'b1; // set the zero flag if the output of the alu is zero 
		  
		  end   
		  
	 if (outputOfALU < 0) begin 
		 
		 overflow=1'b1; // set the overflow flag if the output of alu is negative, that's mean Rs1>Rd 
		 
		 end	 
	
	// Now we will check if the instruction is BEQ  
		if (OpCode1==6'b001010) begin 
			
			if(zero == 1'b1 ) begin 
				
				// the branch is taken and the two numbers are equal 
				branchTargetAddress = PC + extended_immediate16; 
				current_state = 4; 
				//PC=	branchTargetAddress;  
				PcCont=1;
				
			end	  
			
		else if (zero == 1'b0 ) begin 
			
			// Branch doesnt taken 	
			//PC=PC+1; 
			PcCont=0;
			current_state = 4; 
			
			end
			
		end // the end of BEQ 		  
		
		
// Now we will check if the instruction is BNE 
		if (OpCode1==6'b001011) begin 
			
			if(zero == 1'b0 ) begin 
				
				// the branch is taken and the two numbers are NOT equal 
				branchTargetAddress = PC + extended_immediate16; 
				current_state = 4; 
				PcCont=1;
				
			end	  
			
		else if (zero == 1'b1 ) begin 
			
			// Branch doesnt taken 	
			//PC=PC+1; 	  
			PcCont=0;
			current_state = 4; 
			
			end
			
		end // the end of BNE 	 
		
// Now we will check if the instruction is BGT // if Rd> Rs1 then the result of the alu is negative then overflow is 1
	if (OpCode1==6'b001000)	begin 
		
		if(overflow == 1'b1 ) begin 
				
				// the branch is taken and the two numbers are equal 
				branchTargetAddress = PC + extended_immediate16; 
				current_state = 4; 
				//PC=	branchTargetAddress; 
				  PcCont=1;
			end	  
			
		else if (overflow == 1'b0 ) begin 
			
			// Branch doesnt taken 	
			//PC=PC+1; 	 
			PcCont=0;
			current_state = 4; 
			
			end
		
	end /// the end of BGT 	  
	
// Now we will check if the instruction is BLT // if Rd< Rs1 then the result of the alu is positive then overflow is 0
	if (OpCode1==6'b001001)	begin 
		
		if(overflow == 1'b0 ) begin 
				
				// the branch is taken and the two numbers are equal 
				branchTargetAddress = PC + extended_immediate16; 
				current_state = 4; 
				//PC=	branchTargetAddress;  
				PcCont=1;
				
			end	  
			
		else if (overflow == 1'b1 ) begin 
			
			// Branch doesnt taken 	
			//PC=PC+1;  
			PcCont=0;
			current_state = 4; 
			
			end
		
		end /// the end of BLT 
	
	
end // the end of ALU stage  

else if (current_state == 3) begin 
	
	// start with load instruction and LW.POI
	if(OpCode1== 6'b00101 || OpCode1== 6'b000110 )begin		  
								   
	if (Mrd && !MWr) begin 	 
		
		data_memory[8]=32'h00000002;
		data_out= data_memory[outputOfALU];
		
	end 	 
	end	  // the end of load instruction   
	
	// check if the instruction is store 
	if (OpCode1== 6'b000111) begin 
		   if (!Mrd && MWr) begin 	
			   
			 data_memory[outputOfALU]= Rd; 
			 end
			   
	end // the end of Store instruction	 
	
	// here the RET instruction will be a little similar to load instruction == address from the memory 
	if (OpCode1== 6'b001110) begin 	   
		
		if (Mrd && !MWr)  begin
		PC=data_memory[SP]; // next PC is the top of the stack 	
		SP=SP-1; // decrement the value of SP 
		
		end
	end // the end of RET instruction   
	
	// here we will check for the instruction CALL 
		
		  if (OpCode1== 6'b001101) begin 
		   if (!Mrd && MWr) begin 	
			   
			 SP=SP+1;
			 data_memory[SP]= PC+1; 
			 end
			   
	end // the end of CALL instruction 	  
	
	
	// Check if the instruction is PUSH 
		
		if (OpCode1 == 6'b001111) begin 
			
			if (!Mrd && MWr) begin  
				 
			 SP=SP+1;
			 data_memory[SP]= Rd; 
				
				end
			
		end // the end of PUSH 	 
		
		// Check if the instruction is POP 	 
			if (OpCode1==6'b010000) begin 
				
				Rd=data_memory[SP];
				SP=SP-1;
				
			end	 // THE END OF POP INSTRUCTION 	
			
	
end // the end of MEMORY STAGE 	    

else if (current_state == 4) begin 						
	
	if (Wbdata == 1'b0) begin 	  
		toRegFile= outputOfALU;
		
	end	 
else if (Wbdata == 1'b1 ) begin 
		 toRegFile= data_out;
end	 

if (Wport1 ==1'b1) begin 
	// we will write back the result on the register file 
	RegisterFile [RdAddress]=  toRegFile;
	end
else if (Wport2 == 1'b1 ) begin  // so we are in the LW.POI instruction 
	
	  RegisterFile [Rs1Address]= Rs1+1;
	
end	  

PC=PC+1;  // take the next instruction
current_state=0;

	 
end // the end of the write backStage
	
	endmodule		 
	

module TestBench (); 
	
reg clk;
reg reset;	  
	
	///Instruction Decode Part
	wire [31:0] Rs1; // (Bus A )Output data from register 1
    wire [31:0] Rs2; // (Bus B) Output data from register 2
    wire [31:0] Rd; // Rd	 
	
	// control signals 
	
	wire [2:0]PcCont;
	wire [2:0]Alusrc ;
	wire [2:0]AluOp1;
	wire Mrd ;
    wire MWr; 		
	wire Wport1;	
	wire Wport2;
    wire Wbdata ;
	wire ExtOp;
	wire SPorAlu2;
	wire AluSpOp;
	wire DataIn;
	wire MemAdd; 
	
	wire [31:0] outputOfALU;
	wire [31:0]extended_immediate16;  
	wire [31:0] mux_2Output;
    wire [31:0] toRegFile; // the data will be stored in the register file 
	wire [31:0] PCmuxOut; 
	wire [31:0] data_out;
	wire [31:0] IR;
	
	multiCycleProcessor  MCP (clk, reset, PcCont, ExtOp, Wport1, Wport2, Alusrc,AluOp1,MemAdd, DataIn, Mrd, MWr, Wbdata, SPorAlu2,
	AluSpOp, Rs1,Rs2,Rd,outputOfALU, extended_immediate16);	  
	
	initial begin 
	
	
	current_state = 0; 
	clk = 0; 
	reset = 1;
	#1ns reset = 0; 
	end    
	
	always #2ns clk = ~clk;  
   
    initial #100ns $finish;
	
	
endmodule