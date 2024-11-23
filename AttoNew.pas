 program Atto; // 2024.11.23
 { Keywords: if, jmp, prn, ret
   Math  Ops: +  -  *  /  %
   Logic Ops: <  >  #  =
  
  compile it with freepascal: fpc attoNew.pas 
  type: attoNew.exe <FIBONACCI > FIBONACCI.OUT
  analise the content of file: FIBONACCI.OUT } 
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
   Vars    : array['B'..'Z'] of LongInt;
   i       : integer;
   LineNum : word = 0;
   Stack   : word = 0;                  // PSEUDO stack for RET-urn
   Trace   : Boolean = False;
   
 procedure PrintState;
 begin
   Writeln; Writeln('----------- Code:');
   for i := 1 to High(Code) do Writeln(i, ' ', Code[i]);
   Writeln; Writeln('----------- Variables (B..Z):');
   for i := 1 to 25 do Writeln(Chr(i + 65), ' ', Vars[Chr(i + 65)]);
 end;
    
 procedure Error(const Msg: string);
 begin
   Writeln('ERROR: ', Msg);
   Writeln(linenum-1,' ',code[lineNum-1]); 
   PrintState;
   Halt(1);
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
     if Labels[i].Name = Name then Exit(Labels[i].Addr) else Error(name+' not exist.');
 end;
 
 function GetValue(const Index: Byte): Integer;
 begin
   case Tokens[Index][1] of
     'B'..'Q': GetValue := Vars[Tokens[Index][1]];
     'R'     : GetValue := Random(Vars['R']+1);
     'S'..'Z': GetValue := Byte(Vars[Tokens[Index][1]]);
   else
     GetValue := StrToInt(Tokens[Index]); // if NUMBER
   end; // case
 end;
 
 procedure SetValue(n: byte);
 begin 
   if (Tokens[n+1][1] in ['+','-','!']) then
   begin
   if Tokens[n+1][1] = '+' then Vars[Tokens[n][1]]:= GetValue(n) + 1; // INCREMENT
   if Tokens[n+1][1] = '-' then Vars[Tokens[n][1]]:= GetValue(n) - 1; // DECREMENT  
   if Tokens[n+1][1] = '!' then Vars[Tokens[n][1]]:= Not Vars[Tokens[n][1]]; // Ones' compl.  
   end  
   else  
   case Length(Tokens)-1 of
     2, 6: Vars[Tokens[n][1]] := GetValue(Length(Tokens)-1);
     4, 8: begin
            case Tokens[Length(Tokens)-2][1] of
              '+':Vars[Tokens[n][1]]:=GetValue(Length(Tokens)-3)+ GetValue(Length(Tokens)-1);   
              '-':Vars[Tokens[n][1]]:=GetValue(Length(Tokens)-3)- GetValue(Length(Tokens)-1);
              '*':Vars[Tokens[n][1]]:=GetValue(Length(Tokens)-3)* GetValue(Length(Tokens)-1);
              '/':Vars[Tokens[n][1]]:=GetValue(Length(Tokens)-3)DIV GetValue(Length(Tokens)-1);
              '%':Vars[Tokens[n][1]]:=GetValue(Length(Tokens)-3)MOD GetValue(Length(Tokens)-1);
            end;
          end;
   else Error('in expression');
   end;
 end;
 
 procedure Printer(n: byte); 
 begin
   if not(Tokens[n][1]in['B'..'Z']) or (length(tokens[n])>1)then Error('invalid ID: '+Tokens[n]);
  for i := n to High(tokens) do
   if (Tokens[i][1] in ['B'..'R']) then Write(Vars[Tokens[i][1]]) else 
     Write(Chr(Vars[Tokens[i][1]]));
 end;
 
 function Condition: Boolean;
 begin
     case Tokens[2][1] of
         '<': Condition := GetValue(1) < GetValue(3);
         '>': Condition := GetValue(1) > GetValue(3);
         '!': Condition := GetValue(1) <> GetValue(3); // not EQU
         '=': Condition := GetValue(1) = GetValue(3);
     else Error('unknown LOGIC operator'); // Nem ismert operátor
     end;
 end;
 
 procedure ExecuteMe;
 begin
   LineNum:= 1;      
   while LineNum < length(Code) do
   begin
     Tokens:= SplitString(Code[LineNum],' ');    
     Inc(LineNum);      
     if Tokens[0][1] = '.' then continue;                  
     case Tokens[0] of
       'IF': if Condition then
                 case Tokens[4] of
                  'JMP': begin Stack := linenum; LineNum := GetLabelAddr(Tokens[5]); end;
                  'RET': begin if (stack = 0) then Error('No way to RETURN'); LineNum:=Stack; end;
                  'PRN': Printer(5);
                 else if (tokens[4][1]in['B'..'Z'])and(length(tokens[0])=1)then SetValue(4) else
                   Error('>4');
                 end; // case
       'JMP': begin Stack := linenum; LineNum := GetLabelAddr(Tokens[1]); end;
       'RET': begin if (stack = 0) then Error('No way to RETURN'); LineNum:=Stack; end;
       'PRN': Printer(1);
     else if (tokens[0][1]in['B'..'Z'])and(length(tokens[0])=1)then SetValue(0) else Error('>0');
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
  
 begin  // main 
   LoadProgram;
   ExecuteMe;
   if Trace then PrintState;
 end.
