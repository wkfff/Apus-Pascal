unit database;
interface
 uses MyServis;
 var
  // Credentials and options
  DB_HOST:string='127.0.0.1';
  DB_DATABASE:string='';
  DB_LOGIN:string='';
  DB_PASSWORD:string='';
  DB_CHARSET:string='utf8';

 const
  // Error codes
  dbeNoError         = 0;
  dbeNotConnected    = 1;
  dbePingFailed      = 2;
  dbeServerError     = 3;
  dbeQueryFailed     = 4;


 type
  // Basic abstract class
  TDatabase=class
   connected:boolean;
   rowCount,colCount:integer;
   lastError:string;
   lastErrorCode:integer;
   constructor Create;
   procedure Connect; virtual; abstract;
   // Выполняет запрос, возвращает массив строк размером (число строк)*(число столбцов)
   // В случае ошибки возвращает массив из одной строки: ERROR: <текст ошибки>
   // Если запрос не подразумевает возврат данных и выполняется успешно - возвращает
   //   пустой массив (0 строк)
   function Query(DBquery:string):StringArr; virtual; abstract;
   destructor Destroy; virtual;
  private
    crSect:TMyCriticalSection;
    name:string;
  end;

  // MySQL interface
  TMySQLDatabase=class(TDatabase)
   constructor Create;
   procedure Connect; override;
   function Query(DBquery:string):StringArr; override;
   destructor Destroy; override;
  private
   ms:pointer;
   reserve:array[0..255] of integer; // резерв для структуры ms
  end;

  // Escape special characters (so string can be used in query)
  procedure SQLString(var st:string);
  function SQLSafe(st:string):string;

implementation
 uses SysUtils,mysql;
 var
  counter:integer=0; // MySQL library usage counter

procedure SQLString(var st:string);
 var
  i:integer;
 begin
  st:=StringReplace(st,'\','\\',[rfReplaceAll]);
  st:=StringReplace(st,'"','\"',[rfReplaceAll]);
  st:=StringReplace(st,'@','\@',[rfReplaceAll]);
  st:=StringReplace(st,#13,'\r',[rfReplaceAll]);
  st:=StringReplace(st,#10,'\n',[rfReplaceAll]);
  st:=StringReplace(st,#9,'\t',[rfReplaceAll]);
  st:=StringReplace(st,#0,'\0',[rfReplaceAll]);
  i:=1;
  while i<length(st) do
   if st[i]<' ' then delete(st,i,1) else inc(i);
 end;


function SQLSafe(st:string):string;
 begin
  SQLString(st);
  result:=st;
 end;

{ TDatabase }

constructor TDatabase.Create;
 begin
  InitCritSect(crSect,name,100);
  rowCount:=0; colCount:=0;
 end;

destructor TDatabase.Destroy;
 begin
  DeleteCritSect(crSect);
 end;

{ TMySQLDatabase }

procedure TMySQLDatabase.Connect;
 var
  bool:longbool;
  i:integer;
 begin
  try
  sleep(100);
  ms:=mysql_init(nil);
  bool:=true;
  mysql_options(ms,MYSQL_OPT_RECONNECT,@bool);
  mysql_options(ms,MYSQL_SET_CHARSET_NAME,PChar(DB_CHARSET));
  i:=1;
  while (mysql_real_connect(ms,PChar(DB_HOST),PChar(DB_LOGIN),PChar(DB_PASSWORD),
           PChar(DB_DATABASE),0,'',0{CLIENT_COMPRESS})<>ms) and
        (i<4) do begin                                           
   ForceLogMessage(name+': Error connecting to MySQL server ('+mysql_error(ms)+'), retry in 3 sec');
   sleep(3000); inc(i);
  end;
  if i=4 then raise EError.Create(name+': Failed to connect to MySQL server');
  bool:=true;
  mysql_options(ms,MYSQL_OPT_RECONNECT,@bool);
  connected:=true;
  ForceLogMessage(name+': MySQL connection established');
  except
   on e:exception do ForceLogMessage(name+': error during MySQL Connect: '+e.message);
  end;
 end;

constructor TMySQLDatabase.Create;
begin
 inherited;
 if counter=0 then begin
  libmysql_load(nil);
 end;
 inc(counter);
 name:='DB-'+inttostr(counter);
end;

destructor TMySQLDatabase.Destroy;
begin
 inherited;
 dec(counter);
 if counter>0 then exit;
 libmysql_free;
end;

function TMySQLDatabase.Query(DBquery: string): StringArr;
var
 r,flds,rows,i,j:integer;
 st:string;
 res:PMYSQL_RES;
 myrow:PMYSQL_ROW;
begin
  if not connected then begin
   SetLength(result,1);
   lastError:='ERROR: Not connected';
   lastErrorCode:=dbeNotConnected;
   result[0]:=lastError;
   exit;
  end;
  EnterCriticalSection(crSect);
  try
   if DBquery='' then begin
    // Пустой запрос для поддержания связи с БД
    SetLength(result,0);
    r:=mysql_ping(ms);
    if r<>0 then begin
     st:=mysql_error(ms);
     lastError:=st;
     lastErrorCode:=dbePingFailed;
     LogMessage('ERROR! Failed to ping MySQL: '+st);
    end;
    exit;
   end;
   // непустой запрос
   r:=mysql_real_query(ms,@DBquery[1],length(DBquery));
   if r<>0 then begin
    st:=mysql_error(ms);
    lastError:=st;
    lastErrorCode:=dbeServerError;
    LogMessage('SQL_ERROR: '+st);
    setLength(result,1);
    result[0]:='ERROR: '+st;
    exit;
   end;
   res:=mysql_use_result(ms);
   if res=nil then begin
    st:=mysql_error(ms);
    if st<>'' then begin
     lastError:=st;
     lastErrorCode:=dbeQueryFailed;
     LogMessage('SQL_ERROR: '+st);
     setLength(result,1);
     result[0]:='ERROR: '+st;
    end else
     setLength(result,0);        
    exit;
   end;
   flds:=mysql_num_fields(res); // кол-во полей в результате
   colCount:=flds;
   rowCount:=0;
   try
    j:=0;
    setLength(result,flds); // allocate for 1 row
    while true do begin
     // выборка строки и извлечение данных в массив row
     myrow:=mysql_fetch_row(res);
     if myrow<>nil then begin
      inc(rowCount);
      for i:=0 to flds-1 do begin
       if j>=length(result) then
        setLength(result,j*2+flds*16); // re-allocate
       result[j]:=myrow[i];
       inc(j);
      end;
     end else break;
    end;
    if j<>length(result) then setLength(result,j);
   finally
    mysql_free_result(res);
   end;
  finally
   LeaveCriticalSection(crSect);
  end;
end;

end.
