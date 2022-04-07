set serveroutput on;
whenever sqlerror exit sql.sqlcode rollback;
-- create a table abcd if it's not present with three rows and three column

DECLARE
  t_exist NUMBER;
BEGIN
  SELECT count(*) INTO t_exist FROM user_tables 
    WHERE TABLE_NAME = 'ABCD';
  IF t_exist = 0 THEN
    EXECUTE IMMEDIATE 'CREATE TABLE abcd(
      Z NUMBER,
      J CHAR,
      K CHAR,
      L CHAR
    )';
 END IF;
END;
/

--DECLARE
--  t_playerturnexist NUMBER;
--BEGIN
--  SELECT count(*) INTO t_playerturnexist FROM user_tables 
--    WHERE TABLE_NAME = 'ttt_PlayerTurn';
--  IF t_playerturnexist = 0 THEN
--    EXECUTE IMMEDIATE 'CREATE TABLE ttt_PlayerTurn(
--     turn VARCHAR(1) NOT NULL
--    )';
-- END IF;
--END;
--/
--
--INSERT INTO ttt_PlayerTurn (turn) VALUES ('X');

-- Function which converts number to column name
CREATE OR REPLACE FUNCTION nubtoCol(num1 IN NUMBER)
RETURN CHAR
IS
BEGIN
  IF num1=1 THEN
    RETURN 'J';
  ELSIF num1=2 THEN
    RETURN 'K';
  ELSIF num1=3 THEN
    RETURN 'L';
  ELSE 
    RETURN '_';
  END IF;
END;
/
-- procedure to display the tic tac toe board
CREATE OR REPLACE PROCEDURE displayboardgame IS
BEGIN
  dbms_output.enable(10000);
  dbms_output.put_line(' ');
  FOR m in (SELECT * FROM abcd ORDER BY Z) LOOP
    dbms_output.put_line(' ' || m.J || ' ' || m.K || ' ' || m.L);
  END LOOP; 
  dbms_output.put_line(' ');
END;
/
-- procedure to reset the values of the tic tac toe board game
CREATE OR REPLACE PROCEDURE clear_values IS
num1 NUMBER;
BEGIN
  DELETE FROM abcd;
  FOR num1 in 1..3 LOOP
    INSERT INTO abcd VALUES (num1,'_','_','_');
  END LOOP; 
  dbms_output.enable(10000);
  displayboardgame();
  dbms_output.put_line('The game is ready to play to take part in : EXECUTE playgame(''X'', j, z);'); 
END;
/
Create procedure playermoves(turn IN VARCHAR2) as
novalidmove exception;
PRAGMA exception_init(novalidmove,-20002);
begin
if turn not in ('X','O') then
raise_application_error(-20000,'The player is not valid one');
END IF;
END;
/

/*create procedure nodata as
begin
exception
when no_data_found then
then dbms_output.put_line('no data found');
end;
end;*/


Create procedure playermovecolrow(columnvalue in INT) as
cloumnerror exception;
PRAGMA exception_INIT(cloumnerror, -20001);
begin
if columnvalue not in (1,2,3) then
raise_application_error(-20000,'The player is not valid one');
end if;
--if rowerror not in (1,2,3) then
--raise rowerror;
--end if;
end;
/
--
--CREATE OR REPLACE PROCEDURE PLAYERTURN (TURN IN INT,colnum IN INT) AS
--col CHAR;
--BEGIN
--SELECT nubtoCol(colnum) INTO col FROM DUAL;
--IF p_move = (SELECT turn FROM ttt_PlayerTurn)
--        THEN (SELECT 
--                CONCAT('This turn belongs to player ', (SELECT turn FROM ttt_PlayerTurn), '!')
--        );
--        ELSE
--            UPDATE ABCD
--            SET p_column = p_move
--            WHERE ID = p_row;
--            UPDATE ttt_PlayerTurn
--            SET turn = 
--                CASE
--                WHEN turn = 'X' THEN 'O'
--                WHEN turn = 'O' THEN 'X'
--                END;
--    END IF;
--*/
-- procedure to play the tic tac toe game
CREATE OR REPLACE PROCEDURE playgame(input1 in VARCHAR2, colnum IN INT, idvalue IN INT) as
value abcd.K%type;
col CHAR;
input2 CHAR;
sql_stmt varchar2(200);
BEGIN
SELECT nubtoCol(colnum) INTO col FROM DUAL;
begin
playermovecolrow(colnum);
--sql_stmt := '('SELECT ' || COL || ' FROM ABCD WHERE z =' || IDVALUE)';
sql_stmt:=('SELECT '|| COL ||' FROM abcd WHERE z=' || idvalue);
 EXECUTE IMMEDIATE sql_stmt INTO VALUE;
--EXECUTE IMMEDIATE ('SELECT ' || COL || ' FROM ABCD WHERE z =' || IDVALUE) INTO VALUE;
--EXECUTE IMMEDIATE ('SELECT ' || col || ' FROM abcd WHERE z =' || idvalue) INTO value;
exception      
when no_data_found then
raise_application_error(-20000,'No data found as it has out of range out',false);
end;
        
IF value='_' THEN
    EXECUTE IMMEDIATE ('UPDATE abcd SET ' || col || '=''' || input1 || ''' WHERE z=' || idvalue);
   playermoves(input1);
    IF input1='X' THEN
      input2:='O';
    ELSE
      input2:='X';
    END IF;
    displayboardgame();
    dbms_output.put_line('Around ' || input2 || ' to play game : EXECUTE playgame(''' || input2 || ''', j, z);');
  ELSE
    dbms_output.enable(10000);
    dbms_output.put_line('You are unable to play this tile because it has already been played.');
  END IF;
END;
/
-- procedure to win the game
CREATE OR REPLACE PROCEDURE functwinner(input1 IN VARCHAR2) IS
BEGIN
  dbms_output.enable(10000);
  displayboardgame();
  dbms_output.put_line('The player ' || input1 || ' won the game'); 
  dbms_output.put_line('---------------------------------------');
  dbms_output.put_line('Please start a new tic tac toe game');
  clear_values();
END;
/
-- function to query the column values
CREATE OR REPLACE FUNCTION functWinnercol(num2 IN VARCHAR2, input1 IN VARCHAR2)
RETURN VARCHAR2
IS
BEGIN
  RETURN ('SELECT COUNT(*) FROM abcd WHERE ' || num2 || ' = '''|| input1 ||''' AND ' || num2 || ' != ''_''');
END;
/
-- function to query the intersection columns
CREATE OR REPLACE FUNCTION functWinnerIntersect(num3 IN VARCHAR2, idvalue1 IN NUMBER) 
RETURN VARCHAR2
IS
BEGIN
  RETURN ('SELECT '|| num3 ||' FROM abcd WHERE z=' || idvalue1);
END;
/
-- function to find the winner column
CREATE OR REPLACE FUNCTION functwincolm(num4 IN VARCHAR2) 
RETURN CHAR
IS
  numwin NUMBER;
  num5 VARCHAR2(56);
BEGIN
  SELECT functWinnercol(num4, 'X') into num5 FROM DUAL;
  EXECUTE IMMEDIATE num5 INTO numwin;
  IF numwin=3 THEN
    RETURN 'X';
  ELSIF numwin=0 THEN
    SELECT functWinnercol(num4, 'O') into num5 FROM DUAL;
    EXECUTE IMMEDIATE num5 INTO numwin;
    IF numwin=3 THEN
      RETURN 'O';
    END IF;
  END IF;
  RETURN '_';
END;
/
-- function to find the winner diagonal column
CREATE OR REPLACE FUNCTION functwinnerintersectcol(tempx IN CHAR, numcol IN NUMBER, idvalue2 IN NUMBER) 
RETURN CHAR
IS
  tempvar CHAR;
  tempxvar CHAR;
  var1 VARCHAR2(56);
BEGIN
  SELECT functWinnerIntersect(nubtoCol(numcol), idvalue2) INTO var1 FROM DUAL;
  IF tempx IS NULL THEN
    EXECUTE IMMEDIATE (var1) INTO tempxvar;
  ELSIF NOT tempx = '_' THEN
    EXECUTE IMMEDIATE (var1) INTO tempvar;
    IF NOT tempx = tempvar THEN
      tempxvar := '_';
    END IF;
  ELSE
    tempxvar := '_';
  END IF;
  RETURN tempxvar;
END;
/
-- function to trigger if we win
CREATE OR REPLACE TRIGGER trigwinner
AFTER UPDATE ON abcd
DECLARE
  CURSOR cur IS 
    SELECT * FROM abcd ORDER BY Z; 
  curvalue abcd%rowtype;
  tempvar CHAR;
  tempx1 CHAR;
  tempx2 CHAR;
  flag int;
  gnum1 number;
BEGIN
  FOR curvalue IN cur LOOP
    IF curvalue.J = curvalue.K AND curvalue.K = curvalue.L AND NOT curvalue.J='_' THEN
      functwinner(curvalue.J);
      EXIT;
    END IF;
    -- test the column
    SELECT functwincolm(nubtoCol(curvalue.Z)) INTO tempvar FROM DUAL;
    IF NOT tempvar = '_' THEN
      functwinner(tempvar);
      EXIT;
    END IF;
    -- test the diagonal column
    SELECT functwinnerintersectcol(tempx1, curvalue.Z, curvalue.Z) INTO tempx1 FROM dual;
    SELECT functwinnerintersectcol(tempx2, 4-curvalue.Z, curvalue.Z) INTO tempx2 FROM dual;
  END LOOP;
  IF NOT tempx1 = '_' THEN
    functwinner(tempx1);
    flag:=1;
  END IF;
  IF NOT tempx2 = '_' THEN
    functwinner(tempx2);
       flag:=1;
  END IF;
/*if gnum1 <> 95 then
    dbms_output.put_line('draw');
  end if;*/
  END;
/


select * from user_tables;

drop table abcd;
DROP PROCEDURE playgame;
drop procedure playermoves;
drop procedure playermovecolrow;
DROP TABLE ttt_PlayerTurn;

select 'drop '||object_type||' '|| object_name || ';' 
from user_objects 
where object_type in ('VIEW','PACKAGE','SEQUENCE', 'PROCEDURE', 'FUNCTION', 'INDEX','TRIGGER');

select * from user_errors;



EXECUTE clear_values;
--EXECUTE playgame('X', 2, 1);
--EXECUTE playgame('O', 1, 3);
--EXECUTE playgame('X', 2, 4);

