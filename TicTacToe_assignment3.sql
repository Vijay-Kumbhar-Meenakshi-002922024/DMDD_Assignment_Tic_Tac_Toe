set serveroutput on;
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
    dbms_output.put_line('     ' || m.J || ' ' || m.K || ' ' || m.L);
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
-- procedure to play the tic tac toe game
CREATE OR REPLACE PROCEDURE playgame(input1 IN VARCHAR2, colnum IN NUMBER, idvalue IN NUMBER) IS
value abcd.J%type;
col CHAR;
input2 CHAR;
BEGIN
  SELECT nubtoCol(colnum) INTO col FROM DUAL;
  EXECUTE IMMEDIATE ('SELECT ' || col || ' FROM abcd WHERE z=' || idvalue) INTO value;
  IF value='_' THEN
    EXECUTE IMMEDIATE ('UPDATE abcd SET ' || col || '=''' || input1 || ''' WHERE z=' || idvalue);
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
    -- test the daigonal column
    SELECT functwinnerintersectcol(tempx1, curvalue.Z, curvalue.Z) INTO tempx1 FROM dual;
    SELECT functwinnerintersectcol(tempx2, 4-curvalue.Z, curvalue.Z) INTO tempx2 FROM dual;
  END LOOP;
  IF NOT tempx1 = '_' THEN
    functwinner(tempx1);
  END IF;
  IF NOT tempx2 = '_' THEN
    functwinner(tempx2);
  END IF;
END;
/

EXECUTE clear_values;
EXECUTE playgame('X', 3, 1);
EXECUTE playgame('O', 2, 1);
EXECUTE playgame('X', 2, 2);
EXECUTE playgame('O', 1, 3);
