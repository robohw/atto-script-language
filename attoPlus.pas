program AttoPlus; // 24.11.08
{ Keywords......: if, jmp, prn, ret
  Math Operators: +  -  *  /  %
  Log  Operators: <  >  #  =
 
 compile it with freepascal: fpc attoPlus.pas 
 type: attoPlus.exe < FIBONACCI > FIBONACCI.OUT [press ENTER] analise the content of FIBONACCI.OUT}
{type: attoPlus.exe < COLLATZ > COLLATZ.OUT [press ENTER] and analise the content of COLLATZ.OUT}

 {in the ATTO scripts You must insert a SPACE between two language elements. 
  B = B + 12 Its OK, 
  B=B+12    Its Not OK!
  B= B+12   Its Not OK!}
  
uses
  SysUtils, StrUtils;
 
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
  LineNum : Byte = 0;
  Stack   : Byte = 0;                  // PSEUDO stack for RET-urn
  Trace   : Boolean = False;
  counter : longint = 0;
  i       : integer; 
  M       : byte = 1; 
    
procedure PrintState;
begin
  Writeln;  Writeln('----------- (', Counter, ' lines done) - Code:');
  for i := 1 to High(Code) do Writeln(i, ' ', Code[i]);
  Writeln;  Writeln('----------- Variables (A..R + S..Z (chars)):');
  for i := 0 to 25 do Writeln(Chr(i + 65), ' ', Vars[Chr(i + 65)]);
  writeln; 
  Writeln(M);
end;

procedure Error(const Msg: string);
begin
  Writeln('ERROR [in line ',linenum-1,'] ', Msg); 
  if trace then PrintState; Halt(1);
end;
  
procedure SetLabelAddr(const Name: string; Addr: Byte);
begin
  for i := 0 to High(Labels) do
    if Labels[i].Name = Name then Error('Label ' + Name + ' already exists.');
  Labels[High(Labels)].Name := Name;
  Labels[High(Labels)].Addr := Addr;
  SetLength(Labels, Length(Labels) + 1);
end;

function GetLabelAddr(const Name: string): Byte;
begin
  GetLabelAddr:= 0;  
  for i := 0 to High(Labels)-1 do 
    if Labels[i].Name = Name then Exit(Labels[i].Addr); 
  Error('Label "'+name+'" does not exist');       
end;

function GetValue(const Index: Byte): Integer;
begin
  case Tokens[Index][1] of
    'A'..'Q': GetValue := Vars[Tokens[Index][1]];
    'R'     : GetValue := Random(Vars['R']);
    'S'..'Z': GetValue := Byte(Vars[Tokens[Index][1]]);
    '@'     : GetValue := M; 
  else
    GetValue := StrToInt(Tokens[Index]);
  end;
end;

procedure Sugar(const n: byte);
begin
 if tokens[n][1] in ['U'..'Z'] then Error(' Var is Char type') else
 case Tokens[n+1][1] of 
  '+': Vars[Tokens[n][1]] := GetValue(n) + M;
  '-': Vars[Tokens[n][1]] := GetValue(n) - M;
  '*': Vars[Tokens[n][1]] := GetValue(n) * GetValue(n);
 end;      
end;

procedure SetValue(const n: byte);
begin
  if (Tokens[n][1] in ['A'..'Z','@']) = false then Error('invalid var ID: '+Tokens[n]);
  if (Tokens[n+1][1] in ['+','-','*']) then Sugar(n) // syntactic sugar: B + equals B = B + 1
  else  
  case Length(Tokens)-1 of
    2, 6: if Tokens[n][1]= '@' then M:= byte(GetValue(Length(Tokens)-1)) else
            Vars[Tokens[n][1]] := GetValue(Length(Tokens)-1);
    4, 8: begin
          if Tokens[n][1]= '@' then Error('"@" cant do math. Assign NUM (1..255)  or VAR value');
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

function Condition: Boolean;
begin
  case Tokens[2][1] of
    '<': Condition := GetValue(1) < GetValue(3);
    '>': Condition := GetValue(1) > GetValue(3);
    '#': Condition := GetValue(1) <> GetValue(3);
    '=': Condition := GetValue(1) = GetValue(3);
  else Error('Unknown operator');
  end;
end;

procedure Printer(const n: Byte);
begin
  for i := n to High(Tokens) do if Tokens[i][1] in ['A'..'R'] then 
    Write(Vars[Tokens[i][1]]) else 
    if (Tokens[i][1]='@') then Write(M) else 
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
      'IF': if Condition then
                case Tokens[4] of
                 'JMP': begin Stack := linenum; LineNum := GetLabelAddr(Tokens[5]); end;
                 'PRN': Printer(5);
                else SetValue(4);
                end; // case
      'JMP': begin Stack := linenum; LineNum := GetLabelAddr(Tokens[1]); end;
      'RET': begin if (Stack=0) then Error('No way to RETurn'); LineNum := Stack; end;
      'PRN': Printer(1);
       else if (tokens[0][1] <> '.') then SetValue(0);       
    end; // case
    
   if Counter > 999999 then Error('endless loop detected (maybe)') else Inc(Counter);       
  end; // while
end;

procedure LoadProgram;
var
  Line: string;
begin
  Randomize;
  Vars['R'] := 99;   // R as random 
  Vars['S'] := 32;   // PreSET:  SPACE
  Vars['T'] := 13;   // PreSET:  Line Feed
  SetLength(Code,1);   
  SetLength(Labels,1);
  
  while not Eof(Input) do
  begin
    ReadLn(Line);
    Line := UpperCase(Trim(Copy(Line, 1, Pos(';', Line + ';') - 1))); // Comment filter    
    if (Length(Line) > 0) then
    begin
      if (line = 'TRC') then trace := true      
      else
        begin
          if (Line[1] = '.') then SetLabelAddr(Line, LineNum+1); 
          Inc(LineNum);
          SetLength(Code, LineNum+1);
          Code[LineNum] := Line;
        end;
    end;
  end;
end;

begin         // MAIN
  LoadProgram;
  ExecuteMe;
  if Trace then PrintState;
end.
