program Atto; // 2024.08.04
{ Keywords: if, jmp, prn, ret
  Math Ops: +  -  *  /  %
  LogicOps: <  >  #  =
 
 compile it with freepascal: fpc atto.pas 
 type: atto.exe <FIBONACCI > FIBONACCI.OUT
 analise the content of FIBONACCI.OUT  }

uses SysUtils, StrUtils;
 
type
  TLabel = record
    Name: string;
    Addr: Byte;
  end;

var
  Code    : array of string;
  Tokens  : TStringArray;
  Labels  : array of TLabel;
  Vars    : array['A'..'Z'] of LongInt;
  i       : integer;
  LineNum : word = 0;
  Stack   : word = 0;                  // PSEUDO stack for RET-urn
  Trace   : Boolean = False;

procedure Error(const Msg: string);
begin
  Writeln('ERROR: ', Msg);
  Writeln(linenum-1,' ',code[lineNum-1]); Halt(1);
end;

procedure SetLabelAddr(const Name: string; Addr: Byte);
begin
  for i := 1 to High(Labels) do
    if Labels[i].Name = Name then Error('Label ' + Name + ' already exists.');
  SetLength(Labels, Length(Labels) + 1);
  Labels[High(Labels)].Name := Name;
  Labels[High(Labels)].Addr := Addr;
end;

function GetLabelAddr(const Name: string): Byte;
begin
  GetLabelAddr := 0;
  for i := 1 to High(Labels) do
    if Labels[i].Name = Name then Exit(Labels[i].Addr);
end;

function GetValue(const Index: Byte): Integer;
begin
  case Tokens[Index][1] of
    'A'..'Q': GetValue := Vars[Tokens[Index][1]];
    'R'     : GetValue := Random(Vars['R']+1);
    'S'..'Z': GetValue := Byte(Vars[Tokens[Index][1]]);
  else        GetValue := StrToInt(Tokens[Index]);
  end; // case
end;

procedure SetValue(n: byte);
begin
  if not (Tokens[n][1] in ['A'..'Z']) or (length(tokens[n]) > 1) then Error('invalid var ID: '+Tokens[n]);

  if (Tokens[n+1][1] in ['+','-']) then
  begin
  if Tokens[n+1][1] = '+' then Vars[Tokens[n][1]] := GetValue(n) + 1;
  if Tokens[n+1][1] = '-' then Vars[Tokens[n][1]] := GetValue(n) - 1;  
  end  
  else  
  case Length(Tokens)-1 of
    2, 6: Vars[Tokens[n][1]] := GetValue(Length(Tokens)-1);
    4, 8: begin
           case Tokens[Length(Tokens)-2][1] of
             '+': Vars[Tokens[n][1]] := GetValue(Length(Tokens)-3) + GetValue(Length(Tokens)-1);   
             '-': Vars[Tokens[n][1]] := GetValue(Length(Tokens)-3) - GetValue(Length(Tokens)-1);
             '*': Vars[Tokens[n][1]] := GetValue(Length(Tokens)-3) * GetValue(Length(Tokens)-1);
             '/': Vars[Tokens[n][1]] := GetValue(Length(Tokens)-3) DIV GetValue(Length(Tokens)-1);
             '%': Vars[Tokens[n][1]] := GetValue(Length(Tokens)-3) MOD GetValue(Length(Tokens)-1);
           end;
         end;
  else Error('in expression');
  end;
end;

procedure Printer(n: byte); 
begin
  if not (Tokens[n][1] in ['A'..'Z']) or (length(tokens[n]) > 1) then Error('invalid var ID: '+Tokens[n]);
 for i := n to High(tokens) do
  if (Tokens[i][1] in ['A'..'R']) then Write(Vars[Tokens[i][1]]) else 
    Write(Chr(Vars[Tokens[i][1]]));
end;

procedure ExecuteMe;
begin
  LineNum:= 1;      
  while LineNum < length(Code) do
  begin
    Tokens:= SplitString(Code[LineNum],' ');    
    Inc(LineNum);                  
    case Tokens[0] of
      'IF': begin
             if (Tokens[2][1] = '<') and (GetValue(1) < GetValue(3)) or
                (Tokens[2][1] = '>') and (GetValue(1) > GetValue(3)) or
                (Tokens[2][1] = '#') and (GetValue(1) <>GetValue(3)) or
                (Tokens[2][1] = '=') and (GetValue(1) = GetValue(3)) then
                case Tokens[4] of
                 'JMP': begin Stack := linenum; LineNum := GetLabelAddr(Tokens[5]); end;
                 'PRN': Printer(5);
                else SetValue(4);
                end; // case
             end;  // 'IF'
      'JMP': begin Stack := linenum; LineNum := GetLabelAddr(Tokens[1]); end;
      'RET': begin
               if (stack = 0) then Error('No way to RETURN');
               LineNum := Stack;
             end;
      'PRN': Printer(1);
    else SetValue(0);
    end; // case
  end; // while
end;

procedure LoadProgram;
var
  Line: string;
begin
  Randomize;
  Vars['R'] := 99;
  SetLength(Code,1);   
  SetLength(Labels,1);

  while not Eof(Input) do
  begin
    ReadLn(Line);
    Line := UpperCase(Trim(Copy(Line, 1, Pos(';', Line + ';') - 1))); // Comment filter
    if (Length(Line) > 0) and (line[1] <> ';') then
    begin
      if (line = 'TRC') then trace := true
      else
      if (Line[1] = '.') then begin SetLabelAddr(Line, LineNum+1); end
      else
        begin
          Inc(LineNum);
          SetLength(Code, LineNum+1);
          Code[LineNum] := Line;
        end;
    end;
  end;
end;

procedure PrintState;
begin
  Writeln;  Writeln('----------- Code:');
  for i := 1 to High(Code) do Writeln(i, ' ', Code[i]);
  if Length(Labels) > 1 then
  begin
    Writeln; Writeln('----------- Label(s):');
    for i := 1 to High(Labels) do Writeln(Labels[i].Name, #9, Labels[i].Addr);
  end;
  Writeln; Writeln('----------- Variables (A..Z):');
  for i := 0 to 25 do Writeln(Chr(i + 65), ' ', Vars[Chr(i + 65)]);
end;

begin  // main 
  LoadProgram;
  ExecuteMe;
  if Trace then PrintState;
end.
