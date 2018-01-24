/************************************/
		/*CPU Instructions*/

`define		Multiply			4'b0000
`define 	Move				4'b0001
`define		Add				4'b0010
`define		Sub				4'b0011
`define		AND				4'b0100
`define		NAND				4'b0101
`define		OR				4'b0110
`define 	NOR				4'b0111
`define 	Load				4'b1000
`define		Ror				4'b1010
`define		Rol				4'b1011
`define		Not				4'b1100
`define		Jump				4'b1111
`define 	Shl				4'b1101
`define		Shr				4'b1110
/*************************************/





/************************************/
		/*Alu Instructions*/

`define		AluMultiply			4'b0000
`define		AluAdd			4'b0010
`define		AluSub			4'b0011
`define		AluAND			4'b0100
`define		AluNAND			4'b0101
`define		AluOR				4'b0110
`define 	AluNOR			4'b0111
`define		AluRor			4'b1010
`define		AluRol				4'b1011
`define		AluNot			4'b1100
`define		AluShl				4'b1101
`define		AluShr				4'b1110
/*************************************/
			  
//Top level module proc which include the code for control unit and instantiate all other sub modules.

	    //Externally generated inputs
module proc (Resetp, Holdp, Clockp,

			//Input&output ports just for simulation purpose
			led1h, led2h, Clock, PCount, pcoutput, Count, R0, R1, R2, R3, A, G);
 
//Port Decleration

	input Clockp;		//Externally generated clock signal
	input Resetp;		//Externally generated active high Reset signal
	input Holdp;		//Externally generated active low Hold signal


//The below given ports are only for simulation purpose

	output [6:0] led1h, led2h;	//input for the seven segment LED display
	output [7:0] PCount;		//8-bit output from the program counter
	output [15:0] pcoutput;		//16-bit instruction fetched from RAM
	output [1:0] Count;		//2-bit output from the machine cycle counter

	output [7:0] R0, R1, R2, R3, A, G;	//8-bit registers
	output Clock;				//output clock signal for simulation	


//Variables of type reg declaration
							 
reg [7:0] BusWires;		//Used to store value for bus BusWires
reg [7:0] Exe;			//Used to store the value to be displayed on 7 segment display
reg [7:0] Data;			//Used to store the decoded data from 16-bit instruction
reg [7:0] Jmp;			//Used to store the jump address
reg [1 : 0] Rx, Ry;		//Used to store the 2-bit value Rx & Ry, which act as input for 2to4 decoder
reg [3 : 0] F;			//Used to store the 4-bit operand of the  16-bit instruction
reg [3:0] AddSub;		//Store 4-bit value which identify operation to be performed by ALU
reg [0:3] Rin, Rout;		//Store 4-bit value which identify one of the 4 registers to be activated for a given operation
reg  Done;			//Store 1-bit value which identify the successful execution of an instruction
reg  Ain, Gin;			//Store two 1-bit values and are used to save data in the A and G register
reg  Extern, Gout;		//Store two 1-bit values and are used in bus BusWires implementation
reg  Jset;			//Store 1-bit value and is used for the jump instruction

//Variables of type wire declaration

wire [7:0] Sum;		//8-bit signal hold the output result from ALU
wire catch;		//1-bit enable signal for decoding of 16-bit instruction
wire JZ;		//1-bit signal used for jump instruction	
wire [1:0] Count;	//2-bit output signal from machine cycle counter
wire [3:0] I;		//4-bit signal which identify the instruction function
wire [0:3] Xreg, Y;	//4-bit signal for the activation of any register form the 4 registers

wire [7:0] R0, R1, R2, R3, A, G;	//These 8 bit signals used to carry data for these registers
wire [7:0] PCount;                  	//8-bit output signal form the program counter
wire [1:8] FuncReg;			//8-bit signal for control unit
wire [1:8] Func; 			//8-bit signal for control unit
wire [15:0] pcoutput;			//16-bit signal from the RAM
wire [6:0] led1, led2, led1h, led2h;	//7-bit signal for Display unit


//1-bit signal used for various operations 
	wire  Clock, ClockS, Reset, Hold, Clockp, Resetp, Locked;

// Delay Locked Loop Buffer

	dll dll(Clockp, ClockS, Locked);

// Assign Clockp signal to Clock wire

	assign Clock = Locked ? ClockS : 1'b0 ;

// Input Buffers for Reset and Hold 
	
	IBUF rst(.I(Resetp), .O(Reset));
	IBUF hld(.I(Holdp), .O(Hold));

// Output Buffers for Display

	OBUF led10(.I(led1[0]), .O(led1h[0]));
	OBUF led11(.I(led1[1]), .O(led1h[1]));
	OBUF led12(.I(led1[2]), .O(led1h[2]));
	OBUF led13(.I(led1[3]), .O(led1h[3]));
	OBUF led14(.I(led1[4]), .O(led1h[4]));
	OBUF led15(.I(led1[5]), .O(led1h[5]));
	OBUF led16(.I(led1[6]), .O(led1h[6]));

	OBUF led20(.I(led2[0]), .O(led2h[0]));
	OBUF led21(.I(led2[1]), .O(led2h[1]));
	OBUF led22(.I(led2[2]), .O(led2h[2]));
	OBUF led23(.I(led2[3]), .O(led2h[3]));
	OBUF led24(.I(led2[4]), .O(led2h[4]));
	OBUF led25(.I(led2[5]), .O(led2h[5]));
	OBUF led26(.I(led2[6]), .O(led2h[6]));


// Clear Signal generation
	
	wire Clear = Reset | (~Locked) ; 

//Program Counter
	 
	pcounter progcounter (Hold, Clear, Clock, Jmp, Jset, PCount, cmd, JZ);
	 
//State Machine Counter
	
	upcount counter (Clear, Clock, Count, cmd, catch);

//Read RAM

	Ram ramreadload(Clock, cmd, PCount, Reset, pcoutput, catch );


//ALU
	alu alu(AddSub, A, BusWires, Sum);

//LED Display

	Display Dis1(Exe[3:0], Clock, Done, led1);
	Display Dis2(Exe[7:4], Clock, Done, led2);
				   
//Control Unit
	//Instruction Decoding

	always @(catch or pcoutput)
		begin
			F = pcoutput[15:12];
			Rx = pcoutput[11:10];
			Ry = pcoutput[9:8];
			Data = pcoutput[7:0];
			
		end

	assign Func = {F, Rx, Ry};
	wire FRin = catch & ~Count[1] & ~Count[0];
	regn functionreg (Func, FRin, Clock, FuncReg);

	assign I = FuncReg[1:4];
	dec2to4 decX (FuncReg[5:6], 1'b1, Xreg);
	dec2to4 decY (FuncReg[7:8], 1'b1, Y);
	
	//Instruction implementation
	
	always @(Count or I or Xreg or Y  or Data or BusWires or G or JZ)
	
	begin	
			Extern = 1'b0;
			Done = 1'b0;
			Ain = 1'b0;
			Gin = 1'b0;
			Gout = 1'b0;
			AddSub = 3'b000;
			Rin = 4'b0;
			Rout = 4'b0;

	begin


			case (Count) 

				2'b00: ;	//No operation in T0
		
				2'b01:   	//define signals in time step T1
				
				begin
					if (JZ == 1)			// Check Jmp
						begin
						Jset = 1'b0;
						Jmp = 8'b00000000;
						end

					case (I)
						
						`Jump: 			//Jump
						begin
							
							Jset = 1'b1;
							Jmp = Data;
							Done = 1'b1;
							Exe = Data;

						end

						`Load: 			//Load
						begin
						
							Extern = 1;
							Rin = Xreg;
							Done = 1'b1;
							Exe = Data;

						end

						`Move: 			//Move
						begin 
			
							Rout = Y;
							Rin = Xreg;
							Done = 1'b1;
							Exe = BusWires;

						end

						`Add, `Sub, `Multiply, `And, `Or, `Not, `Nor, `Nand, `Ror, `Rol, `Shl, `Shr:	//Add, Sub, Logical, Shift
						begin
							Rout = Xreg;
							Ain = 1'b1;
						end
					
					    default: ;

					   endcase
					end
						
				  2'b10:   //define signals in time step T2

					case (I)  

						`Not: 			//Not
						 begin
							AddSub = `AluNot;
							Gin = 1'b1;
						 end

						`Ror: 			//Rotate Right
						 begin
							AddSub = `AluRor;
							Gin = 1'b1;
						 end

						`Rol: 			//Rotate Left
						 begin
							AddSub = `AluRol;
							Gin = 1'b1;
						 end

						`Shl: 			//Shift Left
						 begin
							AddSub = `AluShl;
							Gin = 1'b1;
						 end

						`Shr: 			//Shift Right
						 begin
							AddSub = `AluShl;
							Gin = 1'b1;
						 end
											
						`Add: 			//Add
						 begin
							Rout = Y;
							AddSub = `AluAdd;
							Gin = 1'b1;
						 end

						 `Sub: 			//Sub
						 begin
							Rout = Y;
							AddSub = `AluSub;
							Gin = 1'b1;
						 end

						 `Multiply: 		//Multiplication
						 begin
							Rout = Y;
							AddSub = `AluMultiply;
							Gin = 1'b1;
						 end

						 `And:			//and
						 begin
							Rout = Y;
							AddSub = `AluAnd;
							Gin = 1'b1;
						 end

						 `Nand:			//nand
						 begin
							Rout=Y;
							AddSub = `AluNand;
							Gin=1'b1;
						 end

						 `Or:			//or
						 begin
							Rout=Y;
							AddSub = `AluOr;
							Gin=1'b1;
						 end

						 `Nor: 			//nor
						 begin
							Rout=Y;
							AddSub = `AluNor;
							Gin=1'b1;
						 end

						 default: ;


					   endcase

					2'b11: 		//define signals in time step T2
					begin
					
						case (I) 
	
						`Add, `Sub, `Multiply:			// Add,Sub
						begin
							Gout = 1'b1;
							Rin = Xreg;
							Done = 1'b1;
							Exe = G;
						end

						`And, `Or, `Nand, `Nor, `Not:		//And, Or, Nand, Nor, Not
						begin
							Gout = 1'b1;
							Rin = Xreg;
							Done = 1'b1;
							Exe = G;
						end

						`Ror, `Rol, `Shl, `Shr: 		//Rotate right, Rotate left, Shift left, Shift right
						 begin
							Gout = 1'b1;
							Rin = Xreg;
							Done = 1'b1;
							Exe = G;
						end
						
						default: ;

						endcase

					end	
				endcase
		end
	end		

//Register Creation

	regn reg_0 (BusWires[7:0], Rin[0], Clock, R0);
	regn reg_1 (BusWires[7:0], Rin[1], Clock, R1);
	regn reg_2 (BusWires[7:0], Rin[2], Clock, R2);
	regn reg_3 (BusWires[7:0], Rin[3], Clock, R3);

	regn reg_A (BusWires, Ain, Clock, A);

	regn reg_G (Sum, Gin, Clock, G);


//8 Bit Bus BusWires Implementation using Multiplexer
	
	wire [1:6] Sel = {Rout, Gout, Extern};

	always @(Sel or R0 or R1 or R2 or R3 or G or Data)
	begin
	if (Sel == 6'b100000)
		BusWires = R0;
    	else if (Sel == 6'b010000)
		BusWires = R1;
	else if (Sel == 6'b001000)
		BusWires = R2;
	else if (Sel == 6'b000100)
		BusWires = R3;
	else if (Sel == 6'b000010)
		BusWires = G;
	else if (Sel == 6'b000001)
    		BusWires = Data;
	else 
		BusWires = 8'bz;

	end

endmodule


//Machine Cycle(T) Counter

module upcount(Clear, Clock, Q, cmd, catch);
	
	input Clear, Clock, cmd, catch;
	output [1:0] Q;
	
	wire Clear, Clock, cmd, catch;	
	reg [1:0] Q;

	reg [3:0] RT1;

	
	always @(posedge Clock)
	begin
			if (Clear == 1)
			begin
				Q <= 2'b00;
				RT1 <= 4'b0000;
			end

			else if (cmd == 0)
			begin
				Q <= 2'b00;
				RT1 <= 4'b0000;
			end

			else
			begin
				if (catch == 1'b1)
				begin
					if (RT1 < 8'b0100)
					begin
						RT1 <= RT1 + 1;
						Q <= Q + 1 ;	
					end

					else if (RT1 == 8'b1111)
					begin
						RT1 <= 4'b0100;
					end

					else
						RT1 <= RT1 + 1;
				end
				else
				begin
					Q <= 2'b0;
					RT1 <= 4'b0000;
				end
			end
	end


endmodule


//2-4 Decoder

module dec2to4(W, En, Y);
	input [1:0] W;
	input En;

	wire [1:0] W;
	wire En;

	output [0:3] Y;
	reg [0:3] Y;
	
	always @(W or En)
	begin
		if (En == 1)
			case (W)
				0: Y = 4'b1000;
	   	    		1: Y = 4'b0100;
				2: Y = 4'b0010;
				3: Y = 4'b0001;
			endcase
		else 
			Y = 4'bz;
	end
endmodule


//8-Bit Register

module regn(R, Rin, Clock, Q);
	parameter n = 8;

	input [n-1:0] R;
	input Rin, Clock;

	wire [n-1:0] R;
	wire Rin, Clock;

	output [n-1:0] Q;
	reg [n-1:0] Q;

	always @(posedge Clock)
	 	if (Rin)
			Q <= R;
	
endmodule

// 40K Block SRAM
//Read Ram 
module Ram(Clock, cmd, PcAddr, Reset, Inst, En);

	input Clock, cmd;
	input [7:0] PcAddr;
	input Reset;
	output [15:0] Inst;
	output En;

	wire Clock, cmd;
	wire [7:0] PcAddr;
	wire Reset;

	wire [15:0] Inst;	
	reg En, We, stop;

	reg [7:0]  WAddr, S;
	reg [15:0] WData;
	reg [15:0] Memory [0:10];
	reg enable, DoJob;	

	wire [7:0] Store;
	
	integer  count;

	always @(Reset)
	begin
		if (Reset == 1)
			begin
				Memory[0] =	16'h80FA;
				Memory[1] =	16'h84F5;
				Memory[2] =	16'h8822;
				Memory[3] =	16'h2400;
				Memory[4] =	16'h1D00;
				Memory[5] =	16'h3B00;
				Memory[6] =	16'h4400;
				Memory[7] =	16'h5400;
				Memory[8] =	16'h6400;
				Memory[9] =	16'h7400;
				Memory[10] =	16'hF409;
				enable = 1;	
	
			end
		else
			begin 
				enable = 0;	
			end
	end

		
	always @(posedge Clock)
	begin	
	if (Reset == 1)
		begin
			if (enable == 1)
			begin	
				if (count <= 10)
				begin
	
				WData = Memory[count];
				WAddr <= WAddr + 1;
				count <= count + 1;
				DoJob = 1'b1;
				end
	
			end
		end

	else	
		begin

		DoJob = 1'b0;
		count <= 0;
		WAddr <= 8'b0;
		WData = 16'b0;
		En = cmd;
		end

	end
	
	always @(negedge Clock)
	begin
		if (DoJob == 1)
		begin
			stop = 1'b1;
			We = 1'b1;
			S = WAddr;
		end
		else if (cmd == 1)
		begin
			stop = 1'b1;
			We = 1'b0;
			S = PcAddr; 

		end
		else
		begin
			stop = 1'b0;
			We = 1'b0; 
		end
	end 

	RAMB4_S16 ram(.DO(Inst), .ADDR(S), .CLK(Clock), .DI(WData),
						.EN(stop), .RST(1'b0), .WE(We));

endmodule

//Program Counter

module pcounter(HButton, ClearCr, Clock, Jmp, Jset, Q1, cmd, Jz);
	
	input ClearCr, Clock;
	input HButton;
	input Jset;
	input [7:0] Jmp;

	wire ClearCr, Clock;
	wire HButton;
	wire Jset;
	wire [7:0] Jmp;

	output [7:0] Q1;
	output cmd;
	output Jz;

	reg [7:0] Q1;

	reg  work, cmd, Jz;


	always @(posedge Clock)
	begin
	
		if (ClearCr == 1)
		begin
			Q1 <= 0;
			work = 1'b0;
		end
			
		else	if (HButton == 0)
		begin
			if (work != 1'b1)
			begin 
			cmd = 1'b1;
			work = 1'b1;
				begin
				if (Jset == 1)
					begin
					Q1 <= Jmp;
					Jz = 1'b1;
					end
				else
					Q1 <= Q1 + 1 ;
				end
			end
		end
		else
		begin
			cmd = 1'b0;
			work = 1'b0;
			Jz = 1'b0;
		end
	end	

endmodule



//Arthematic Logic Unit

module alu (Inst, A, BusWires, Result);

	input [3:0] Inst;
	input [7:0] A, BusWires;

	wire [3:0] Inst;
	wire [7:0] A, BusWires;

	output [7:0] Result;
	//output Cout, Zout, Sout;

	reg [7:0] Result;
	reg Zout, Sout, Cout;
			
	always @(Inst  or A or BusWires or Result)

	begin
		Zout	= 1'b0;
		Sout	= 1'b0;
		Cout = 1'b0;
		Result = 8'b0;


    	case (Inst)  // synopsis  parallel_case
	

		`AluMultiply:	
					begin 
					{Cout,Result}  = (A * BusWires);
					//Cout = Result[8]; 
					if (Result == 8'h00) 
					Zout = 1'b1; 
					if (Result[7] == 1) 
					Sout = 1'b1; 
					end

		`AluShl: 		Result = {A[6:0], 1'b0};				
		`AluShr: 		Result = {1'b0, A[7:1]};

		`AluRol: 		Result = {A[6:0], A[7]};
		`AluRor: 		Result = {A[0], A[7:1]};

		`AluAdd:		begin 
					{Cout,Result}  = (A + BusWires);
					//Cout = Result[8];
					if (Result == 8'h00) 
					Zout = 1'b1; 
					if (Result[7] == 1) 
					Sout = 1'b1; 
					end

		`AluSub:		begin 
					{Cout,Result}  = (A - BusWires) ;
					//Cout = Result[8];
					if (Result == 8'h00) 
					Zout = 1'b1; 
					if (Result[7] == 1) 
					Sout = 1'b1; 
					end

		`AluAnd: 		Result =   A & BusWires; 
		`AluNand:		Result =  ~(A & BusWires); 
		`AluOr:  		Result =   A | BusWires;
		`AluNor: 		Result =  ~(A | BusWires);
		`AluNot:		Result =	~(A);

		default: 		begin
						Zout	= 1'b0;
						Sout	= 1'b0;
						Cout = 1'b0;
						Result = 8'b0;
					end

		
	endcase
	
	end
	
endmodule





/* Led: The 7 segment display */

module Display(buscontents, clk, Done, led);

	input [3:0] buscontents;
	input clk, Done;

	wire [3:0] buscontents;
	wire clk, Done;

	output [6:0] led;

	reg[6:0]	led;

	always @ (posedge clk)
		if (Done == 1)
		begin
			case (buscontents)   // synopsis full_case parallel_case

				4'b0000: led = 7'b1110111;
				4'b0001: led = 7'b0010010;
				4'b0010: led = 7'b1011101;
				4'b0011: led = 7'b1011011;
				4'b0100: led = 7'b0111010;
				4'b0101: led = 7'b1101011;
				4'b0110: led = 7'b1101111;
				4'b0111: led = 7'b1010010;
				4'b1000: led = 7'b1111111;
				4'b1001: led = 7'b1111011;
				4'b1010: led = 7'b1111110;
				4'b1011: led = 7'b0101111;
				4'b1100: led = 7'b0001101;
				4'b1101: led = 7'b0011111;
				4'b1110: led = 7'b1101101;
				4'b1111: led = 7'b1101100;
   	   		endcase
		end

endmodule


//   Delay Lock Loops and Global clock buffers instantiation    
 
module dll(CLKIN, CLK1X, LOCKED2X);

input CLKIN;
output CLK1X, LOCKED2X;

wire CLK1X;

wire CLKIN_w, CLK1X_dll, LOCKED2X;


	IBUFG clkpad (.I(CLKIN), .O(CLKIN_w));

	CLKDLL dll2x (.CLKIN(CLKIN_w), .CLKFB(CLK1X), .RST(1'b0), 
	              .CLK0(CLK1X_dll), .CLK90(), .CLK180(), .CLK270(),
	              .CLK2X(), .CLKDV(), .LOCKED(LOCKED2X));

	BUFG   clk2xg (.I(CLK1X_dll),  .O(CLK1X));

	//OBUF   lckpad (.I(LOCKED2X), .O(LOCKED));

endmodule
