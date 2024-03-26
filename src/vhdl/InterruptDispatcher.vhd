-- ******************************************************************************
-- 
--                   /------o
--             eccelerators
--          o------/
-- 
--  This file is an Eccelerators GmbH sample project.
-- 
--  MIT License:
--  Copyright (c) 2023 Eccelerators GmbH
-- 
--  Permission is hereby granted, free of charge, to any person obtaining a copy
--  of this software and associated documentation files (the "Software"), to deal
--  in the Software without restriction, including without limitation the rights
--  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--  copies of the Software, and to permit persons to whom the Software is
--  furnished to do so, subject to the following conditions:
-- 
--  The above copyright notice and this permission notice shall be included in all
--  copies or substantial portions of the Software.
-- 
--  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--  SOFTWARE.
-- ******************************************************************************
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	
use work.basic.all;
    
entity InterruptDispatcher is
    generic (
        NUMBER_OF_OUTPUTS : positive := 2
    );
	port (
		Clk : in std_logic;
		Rst : in std_logic;
		InterruptInToDispatch : in std_logic;
		InterruptsEnableFromCpus : in std_logic_vector;
		InterruptsBusyFromCpus : in std_logic_vector;
		InterruptsOutToCpus : out std_logic_vector
	);
end entity;

architecture Behavioural of InterruptDispatcher is

    constant OUT_LENGTH : natural := InterruptsOutToCpus'length;
    constant OUT_LEFT : natural := OUT_LENGTH - 1;
    
    constant OUT_COUNT_LENGTH : natural := array_element_counter_length(InterruptsOutToCpus);
    constant OUT_COUNT_LEFT : natural := OUT_COUNT_LENGTH - 1;
    
    signal SelectedOut : unsigned(OUT_COUNT_LEFT downto 0);
    signal RotatingHighestPriority : unsigned(OUT_COUNT_LEFT downto 0);
    signal InterruptInHistory : std_logic_vector(1 downto 0);

begin
      
    prcDispatch : process (Clk, Rst) is      
    begin
    
        if Rst then
        
            InterruptsOutToCpus <= std_logic_vector(to_unsigned(0, OUT_LENGTH));
            SelectedOut <= (others => '0');     
            InterruptInHistory  <= (others => '0');
                              
        elsif rising_edge(Clk) then
        
            InterruptInHistory <=  InterruptInHistory(0) & InterruptInToDispatch;
            
            if InterruptInHistory = "01" then
                InterruptsOutToCpus(to_integer(SelectedOut)) <= '1';
            end if;
            
            if InterruptInHistory = "10" then
                InterruptsOutToCpus(to_integer(SelectedOut)) <= '0';
                if SelectedOut < to_unsigned(NUMBER_OF_OUTPUTS - 1, OUT_COUNT_LENGTH) then
                    SelectedOut <= SelectedOut + 1;
                else 
                    SelectedOut <= to_unsigned(0, OUT_COUNT_LENGTH);           
                end if;
            end if;

        end if;     
    end process;


	
end architecture;
