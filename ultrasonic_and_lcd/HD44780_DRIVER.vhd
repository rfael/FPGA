library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.std_logic_unsigned.all; 

ENTITY HD44780_DRIVER is
	PORT(
		INPUT:		in STD_LOGIC_VECTOR (7 downto 0);
		TRIGGER:	in STD_LOGIC;
		COMMAND:	in STD_LOGIC;
		CLOCK_50:	in STD_LOGIC;
		RESET:		in STD_LOGIC;
		RS:			out STD_LOGIC;
		E:			out STD_LOGIC;
		D:			out STD_LOGIC_VECTOR (7 downto 0);
		BUSY:		out STD_LOGIC:='1'
	);
END ENTITY;

ARCHITECTURE MAIN of HD44780_DRIVER is

TYPE LCD_STATE_T is (LCD_RESET, LCD_SEND, LCD_DELAY, E_DOWN, FUNCTION_SET, 
	DISPLAY_OFF, MODE_SET, DISPLAY_CLEAR, LCD_IDLE, WRITE_CHAR, WRITE_COMMAND);
	
SIGNAL CURRENT_STATE:	LCD_STATE_T;
SIGNAL NEXT_STATE:		LCD_STATE_T;
SIGNAL CLK_200Hz:		STD_LOGIC;
SIGNAL CLK_PRSCL:		INTEGER range 0 to 125000;
SIGNAL D_BYTE:			STD_LOGIC_VECTOR(7 downto 0);
SIGNAL DELAY_CNT:		INTEGER range 0 to 50:=0;
SIGNAL INIT_CNT:		INTEGER range 0 to 4:=0;
	
BEGIN

PROCESS(CLOCK_50)
BEGIN
	IF rising_edge(CLOCK_50) THEN
		CLK_PRSCL <= CLK_PRSCL + 1;
		IF CLK_PRSCL = 125000 THEN
			CLK_PRSCL <= 0;
			CLK_200Hz <= not CLK_200Hz;
		END IF;
	END IF;
END PROCESS;

PROCESS(CLK_200Hz, RESET)
BEGIN
	IF RESET = '1' THEN
		CURRENT_STATE <= LCD_RESET;
		D_BYTE <= "00000000"; 
		NEXT_STATE <= LCD_RESET;
		E <= '1';
		RS <= '0';
		BUSY <= '1';
		INIT_CNT <= 0;
		DELAY_CNT <= 0;
		
	ELSIF rising_edge(CLK_200Hz) THEN
		CASE(CURRENT_STATE) is
			when LCD_RESET =>
				RS <= '0';
				E <= '0';
				BUSY <= '1';
				D_BYTE <= "01010101";
				INIT_CNT <= INIT_CNT + 1;
				CURRENT_STATE <= LCD_SEND;
				NEXT_STATE <= LCD_DELAY;
				
			when LCD_SEND =>
				E <= '1';
				D <= D_BYTE;
				BUSY <= '1';
				CURRENT_STATE <= E_DOWN;
				
			when E_DOWN =>
				E <= '0';
				BUSY <= '1';
				CURRENT_STATE <= NEXT_STATE;
				
			when LCD_DELAY =>
				IF DELAY_CNT < 50 THEN
					CURRENT_STATE <= LCD_DELAY;
					DELAY_CNT <= DELAY_CNT + 1;
				ELSE
					DELAY_CNT <= 0;
					IF INIT_CNT < 4 THEN
						CURRENT_STATE <= LCD_RESET;
					ELSE
						CURRENT_STATE <= FUNCTION_SET;
						INIT_CNT <= 0;
					END IF;
				END IF;
				
			when FUNCTION_SET =>
				E <= '0'; 
				RS <= '0';
				BUSY <= '1';
				D_BYTE <= "00111000";-- 0 0 1 DL N F * * - DL data lenght, N no of lines, F 5x10 or 5x8 font 
				CURRENT_STATE <= LCD_SEND;
				NEXT_STATE <= DISPLAY_OFF;
				
			when DISPLAY_OFF =>
				E <= '0'; 
				RS <= '0';
				BUSY <= '1';
				D_BYTE <= "00001100";--0 0 0 0 1 D C B - D display on/off, C - cursor on/off, B - blink on/off  
				CURRENT_STATE <= LCD_SEND;
				NEXT_STATE <= DISPLAY_CLEAR;
				
			when DISPLAY_CLEAR =>
				E <= '0'; 
				RS <= '0';
				BUSY <= '1';
				D_BYTE <= "00000001";-- Display clear   
				CURRENT_STATE <= LCD_SEND;
				NEXT_STATE <= MODE_SET;
				
			when MODE_SET =>
				E <= '0'; 
				RS <= '0';
				BUSY <= '1';
				D_BYTE <= "00000110";-- 000001 I/D S - I/D inc/dec, S - Shift display on/off  
				CURRENT_STATE <= LCD_SEND;
				NEXT_STATE <= LCD_IDLE;
				
			when LCD_IDLE =>
				BUSY <= '0';
				IF(TRIGGER = '1')THEN
					IF COMMAND = '0' THEN
						CURRENT_STATE <= WRITE_CHAR;
					ELSE
						CURRENT_STATE <= WRITE_COMMAND;
					END IF;
				ELSE
					CURRENT_STATE <= LCD_IDLE;
				END IF;
				
			when WRITE_CHAR =>
				E <= '1'; 
				RS <= '1';
				BUSY <= '1';
				D_BYTE <= INPUT;
				CURRENT_STATE <= LCD_SEND;
				NEXT_STATE <= LCD_IDLE;
				
			when WRITE_COMMAND =>
				E <= '1'; 
				RS <= '0';
				BUSY <= '1';
				D_BYTE <= INPUT;
				CURRENT_STATE <= LCD_SEND;
				NEXT_STATE <= LCD_IDLE;
			
			when OTHERS =>
				CURRENT_STATE <= NEXT_STATE;
				
		END CASE;
	END IF;
END PROCESS;

END MAIN;