library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY UART_CONTROL IS
PORT(
CLOCK_IN:	IN STD_LOGIC;
TXD:		OUT STD_LOGIC;
RXD:		IN STD_LOGIC;
TRIGGER:	IN STD_LOGIC;
DATA_OUT:	OUT STD_LOGIC_VECTOR(7 downto 0);
DATA_IN:	IN STD_LOGIC_VECTOR(7 downto 0)
);
END UART_CONTROL;

ARCHITECTURE MAIN OF UART_CONTROL IS

SIGNAL TX_DATA:	STD_LOGIC_VECTOR(7 downto 0);
SIGNAL TX_START:STD_LOGIC:='0';
SIGNAL TX_BUSY:	STD_LOGIC;
SIGNAL RX_DATA:	STD_LOGIC_VECTOR(7 downto 0);
SIGNAL RX_BUSY:	STD_LOGIC;

COMPONENT TX
PORT(
CLK:	IN STD_LOGIC;
START:	IN STD_LOGIC;
BUSY:	OUT STD_LOGIC;
DATA:	IN STD_LOGIC_VECTOR(7 downto 0);
TX_LINE:OUT STD_LOGIC
);
END COMPONENT TX;

COMPONENT RX
PORT(
CLK:	IN STD_LOGIC;
RX_LINE:IN STD_LOGIC;
DATA:	OUT STD_LOGIC_VECTOR(7 downto 0);
BUSY:	OUT STD_LOGIC
);
END COMPONENT RX;

BEGIN

C1: TX PORT MAP(CLOCK_IN,TX_START,TX_BUSY,TX_DATA,TXD);
C2: RX PORT MAP(CLOCK_IN,RXD,RX_DATA,RX_BUSY);

PROCESS(CLOCK_IN)
BEGIN
	IF rising_edge(CLOCK_IN)THEN
		IF (TRIGGER='0' AND TX_BUSY='0')THEN
			TX_DATA<=DATA_IN;
			TX_START<='1';
		ELSE
			TX_START<='0';
		END IF;
	END IF;
END PROCESS;

PROCESS(RX_BUSY)
BEGIN
IF	falling_edge(RX_BUSY) THEN
	DATA_OUT<=RX_DATA;
END IF;
END PROCESS;
END MAIN;