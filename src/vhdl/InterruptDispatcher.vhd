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
	
library eccelerators;
    use eccelerators.basic.all;
    
entity BusJoinWishbone is
	port (
		Clk : in std_logic;
		Rst : in std_logic;
		Cyc : in  std_logic_vector;
		Adr : in array_of_std_logic_vector;
		Sel : in array_of_std_logic_vector;
		We : in std_logic_vector;
		Stb : in std_logic_vector;
        DatIn : in array_of_std_logic_vector;
		DatOut : out array_of_std_logic_vector;
		Ack : out std_logic_vector;	
        JoinCyc : out std_logic;
		JoinAdr : out std_logic_vector;
		JoinSel : out std_logic_vector;
		JoinWe : out std_logic;
		JoinStb : out std_logic;
		JoinDatOut : out std_logic_vector;
		JoinDatIn: in std_logic_vector;
		JoinAck : in std_logic
	);
end entity;

architecture Behavioural of BusJoinWishbone is

    constant BUSSES_LENGTH : natural := Cyc'length;
    constant BUSSES_LEFT : natural := BUSSES_LENGTH - 1;
    
    constant BUSSES_COUNT_LENGTH : natural := array_element_counter_length(Cyc);
    constant BUSSES_COUNT_LEFT : natural := BUSSES_COUNT_LENGTH - 1;
    
    type T_State is (Idle, Cycle);
      
    function resolveCycleRequests (
        CycleRequests : std_logic_vector(BUSSES_LEFT downto 0);
        MissCountTable : array_of_unsigned(BUSSES_LEFT downto 0)
    ) return integer is
        variable GreatestMissCount: integer := 0;
        variable SelectedRequest: integer := -1; 
    begin
        for i in 0 to BUSSES_LEFT loop
            if CycleRequests(i) then
                if MissCountTable(i) > GreatestMissCount then
                    GreatestMissCount := to_integer(MissCountTable(i));
                end if;
            end if;
        end loop;
        for i in 0 to BUSSES_LEFT loop
            if CycleRequests(i) then
                if MissCountTable(i) = GreatestMissCount then
                    SelectedRequest := i;
                end if;
            end if;
        end loop;
        return SelectedRequest;
    end function;
    
    signal MissCountTable : array_of_unsigned(BUSSES_LEFT downto 0) (BUSSES_COUNT_LEFT downto 0);
    signal SelectedBus : unsigned(BUSSES_COUNT_LEFT downto 0); 
    signal State : T_State;
    signal StateNumbered : unsigned(0 downto 0);

begin

    -- For GHDL and HW debug
    prcNumberStates : process(State) is
    begin
        case State is
            when Idle =>
                StateNumbered <= to_unsigned(0, StateNumbered'length);
            when Cycle =>
                StateNumbered <= to_unsigned(1, StateNumbered'length);
        end case;
    end process;

    genDataOut : for i in 0 to BUSSES_COUNT_LEFT generate
        DatOut(i) <= JoinDatIn;
    end generate;
     
     
    prcAck : process(JoinAck, SelectedBus) is
    begin
        Ack <= std_logic_vector(to_unsigned(0, Ack'length));
        for i in 0 to BUSSES_COUNT_LEFT loop
            if i = to_integer(SelectedBus) then
                Ack(i) <= JoinAck;
            end if;
        end loop;
    end process;
         
    prcJoin : process ( Clk, Rst) is
        variable ri : integer := 0;
    begin
        if Rst then
        
            SelectedBus <= (others => '0');
            JoinCyc <= '0';                   
            JoinAdr <= std_logic_vector(to_unsigned(0, JoinAdr'length));
            JoinSel <= std_logic_vector(to_unsigned(0, JoinSel'length));
            JoinWe <= '0';
            JoinStb <= '0';
            JoinDatOut <= std_logic_vector(to_unsigned(0, JoinDatOut'length));
            MissCountTable <= (others => (others => '0'));
            
        elsif rising_edge(Clk) then
            
            case State is
            
                when Idle =>
                    ri := resolveCycleRequests(Cyc, MissCountTable);
                    if ri >= 0 then       
                        SelectedBus <= to_unsigned(ri, BUSSES_COUNT_LENGTH);
                        JoinCyc <= '1';                   
                        JoinAdr <= Adr(ri);
                        JoinSel <= Sel(ri);
                        JoinWe <= We(ri);
                        JoinStb <= Stb(ri);
                        JoinDatOut <= DatIn(ri);
                        MissCountTable(ri) <= (others => '0');      
                        for i in 0 to BUSSES_LEFT loop
                            if Cyc(i) = '1' and (i /= ri) then
                                MissCountTable(i) <= MissCountTable(i) + 1;
                            end if;
                        end loop;
                        State <= Cycle;
                    end if;

                when Cycle =>
                    if JoinAck then
                        JoinCyc <= '0';
                        JoinAdr <= std_logic_vector(to_unsigned(0, JoinAdr'length));
                        JoinSel <= std_logic_vector(to_unsigned(0, JoinSel'length));
                        JoinWe <= '0';
                        JoinStb <= '0';
                        JoinDatOut <= std_logic_vector(to_unsigned(0, JoinDatOut'length));
                        State <= Idle;
                    end if;
                
            end case;  
 
        end if;     
    end process;


	
end architecture;
