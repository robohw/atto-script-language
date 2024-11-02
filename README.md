### A working Interpreter (with tracer) in eight functions/procedures and the main!  ###

1 procedure Error(const Msg: string);   
2 procedure SetLabelAddr(const Name: string; Addr: Byte);   
3 function GetLabelAddr(const Name: string): Byte;   
4 function GetValue(const Index: Byte): Integer;   
5 procedure SetValue(n: byte);   
6 procedure ExecuteMe;   
7 procedure LoadProgram;   
8 procedure PrintState;   
9 main  
  
    
Keywords: if, jmp, prn, ret, + TRC (means TRACE)  
Math  Operators: + - * / %  
Logic Operators: < > # =  
  
  
compile it with freepascal: 
### fpc atto.pas ###   
  
type: 
### atto.exe < FIBONACCI > FIBONACCI.OUT ###    
  
analise the content of FIBONACCI.OUT  

-------------------------------------------
![](atto_logo.gif)





