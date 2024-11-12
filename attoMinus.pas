program attoMinus; // 24.11.12
{ Keywords: IF, JMP, PRN, RET, Math Oprtrs: + - * / % (mod), Log Oprtrs: < > =   
 Separator = ' '. In the ATTO scripts You must insert a SPACE between two language elements. 
  
  Variables (english ABC letters):  A B C D E F G H I J K L M N O P Q _R_ S T U V W X Y Z
 
  A..Q = 32 bit signed integers, R as RANDOM num generator (R/W), S..Z = 8 bit ASCII codes.
  
 compile it with freepascal: fpc attoMinus.pas 
 type: attoMinus.exe < FIBONACCI > FIBONACCI.OUT [press ENTER] analise the content of FIBONACCI.OUT
 type: attoMinus.exe < COLLATZ > COLLATZ.OUT [press ENTER] and analise the content of COLLATZ.OUT

  B = B + 12 Its OK, 
  B=B+12    Its Not OK!  
  B= B+12   Its Not OK!}
 
type
  TLabel = record
    Name: string;
    Addr: Byte;
  end;

var
  Code    : array of string;
  Tokens  : array of string; //TStringArray;
  Labels  : array of TLabel;
  Vars    : array['A'..'Z'] of LongInt;
  LineNum : Byte = 0;
  Stack   : Byte = 0;                  // PSEUDO stack for RET-urn
  Trace   : Boolean = False;
  counter : longint = 0;
  i       : byte; 
  
// ------------------------- funcs
function UpCase(str: string): string;
begin
  UpCase := str;
  for i := 1 to Length(str) do
  begin
    if str[i] in ['a'..'z'] then UpCase[i] := Chr(Ord(str[i]) - 32);
  end;
end;

function Trim(str: string): string;
var
  u, j: Integer;
begin  
  u := 1; 
  while (u <= Length(str)) and (str[u] <= ' ') do Inc(u);
  j := Length(str);    
  while (j >= u) and (str[j] <= ' ') do  Dec(j);
  Trim := Copy(str, u, j - u + 1);   
end;

function StrToInt(str: string): LongInt;
var
  i, digit, sign: LongInt;
begin
  StrToInt := 0; sign := 1;  i := 1;
  if str[i] = '-' then
  begin
    sign := -1;
    Inc(i);
  end;

  while (i <= Length(str)) and (str[i] in ['0'..'9']) do
  begin
    digit := Ord(str[i]) - Ord('0');
    StrToInt := StrToInt * 10 + digit;
    Inc(i);
  end;
  StrToInt := StrToInt * sign;
end;

// -------------------------  
procedure PrintState;
begin
  writeln(' '); Writeln('----------- (', Counter, ' lines done) - Code:');
  for i := 1 to High(Code) do Writeln(i, ' ', Code[i]);
  Writeln;  Writeln('----------- Variables (A..R (nums) + S..Z (chars)):');
  for i := 0 to 25 do Writeln(Chr(i + 65), ' ', Vars[Chr(i + 65)]);
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
    'R'     : GetValue := Random(Vars['R']+1);
    'S'..'Z': GetValue := Byte(Vars[Tokens[Index][1]]);
  else
    GetValue := StrToInt(Tokens[Index]);
  end;
end;

procedure SetValue(const n: byte);
begin
  if not (Tokens[n][1] in ['A'..'Z']) then Error('invalid var ID: '+Tokens[n]);

   case Tokens[n+1][1] of   // syntactic sugar: B + equals B = B + 1
  '+': Inc(Vars[Tokens[n][1]]);
  '-': Dec(Vars[Tokens[n][1]]);
   end;       
 
  if length(Tokens) > 2 then   
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
   else Error('in expression (2)');
   end;
end;

function Condition: Boolean;
begin
  case Tokens[2][1] of
    '<': Condition := GetValue(1) < GetValue(3);
    '>': Condition := GetValue(1) > GetValue(3);
    '=': Condition := GetValue(1) = GetValue(3);
  else Error('Unknown operator');
  end;
end;

procedure Printer(const n: Byte);
begin
  for i := n to High(Tokens) do if Tokens[i][1] in ['A'..'R'] then 
    Write(Vars[Tokens[i][1]]) else Write(Chr(Vars[Tokens[i][1]]));
end;
  
procedure Split(inStr: string);
var index: longint;
begin
  Index := 0;
  SetLength(Tokens, 1);
  Tokens[0] := '';   
  for i := 1 to Length(inStr) do  
    begin    
     if inStr[i] <> ' ' then
       begin
         if (i=1) or (inStr[i-1]=' ') then begin inc(index); SetLength(Tokens, Index); end;
         Tokens[Index-1] := Tokens[Index-1] + inStr[i];
       end;
    end;
end;
  
procedure ExecuteMe;
begin
  LineNum:= 1;      
  while LineNum < length(Code) do
  begin
    Split(code[LineNum]);        
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
  Vars['R'] := 99;   // R random Set (B = R      ; B equ 0..99) 
  Vars['S'] := 32;   // PreSet: (ASCII) SPACE
  Vars['T'] := 13;   // PreSet: (ASCII) Line Feed
  SetLength(Code,1);   
  SetLength(Labels,1);
  
  while not Eof(Input) do
  begin
    ReadLn(Line);
    Line := UpCase(Trim(Copy(Line, 1, Pos(';', Line + ';') - 1))); // Comment filter    
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
