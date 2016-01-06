// Wrapper unit for platform-dependent functions
//
// Copyright (C) 2011 Apus Software (www.apus-software.com)
// Author: Ivan Polyacov (ivan@apus-software.com, cooler@tut.by)
{$S-}
unit CrossPlatform;
interface
{$IFDEF MSWINDOWS}
 uses windows;
{$ENDIF}
{$IFDEF IOS}
 {$modeswitch ObjectiveC1}
 uses types,iPhoneAll;
{$ENDIF}

{$IFDEF MSWINDOWS}
 type
  TRect=windows.TRect;
  TPoint=windows.TPoint;
  HCursor=windows.HCURSOR;
  HWND=windows.HWND;
  TThreadID=cardinal;
 const
  VK_SPACE=windows.VK_SPACE;
  VK_RETURN=windows.VK_RETURN;
  VK_ESCAPE=windows.VK_ESCAPE;
  VK_BACK=windows.VK_BACK;
  VK_INSERT=windows.VK_INSERT;
  VK_DELETE=windows.VK_DELETE;
  VK_UP=windows.VK_UP;
  VK_DOWN=windows.VK_DOWN;
  VK_F1=windows.VK_F1;
  VK_F2=windows.VK_F2;
  VK_F3=windows.VK_F3;
  VK_F4=windows.VK_F4;
  VK_F5=windows.VK_F5;
  VK_F6=windows.VK_F6;
  VK_F7=windows.VK_F7;
  VK_F8=windows.VK_F8;
  VK_F9=windows.VK_F9;
  VK_F10=windows.VK_F10;
  VK_TAB=windows.VK_TAB;
  VK_LEFT=windows.VK_LEFT;
  VK_RIGHT=windows.VK_RIGHT;
  VK_HOME=windows.VK_HOME;
  VK_END=windows.VK_END;
{$ENDIF}
{$IFDEF IOS}
 const
  VK_SPACE=32;
  VK_RETURN=13;
  VK_ESCAPE=27;
  VK_BACK=129;
  VK_DELETE=130;
  VK_UP=131;
  VK_DOWN=132;
  VK_F1=140;
  VK_F2=141;
  VK_F3=142;
  VK_F4=143;
  VK_F5=144;
  VK_F6=145;
  VK_F7=146;
  VK_F8=147;
  VK_F9=148;
  VK_F10=149;
 type
  TThreadID=system.TThreadID;
  HCURSOR=cardinal;
  HWND=pointer;
  TRect=types.TRect;
  TPoint=types.TPoint;

{  TThread=class
   terminated,running,finished:boolean;
   returnValue:integer;
   handle:cardinal;
   constructor Create(suspended:boolean);
   destructor Destroy; virtual;
   procedure Execute; virtual;
   procedure Terminate; virtual;
   procedure Resume; virtual;
   property ThreadID:cardinal read handle;
  private
   id:pointer;
  end;  }
{$ENDIF}

 function GetTickCount:cardinal;
 procedure QueryPerformanceCounter(out value:int64);
 procedure QueryPerformanceFrequency(out value:int64);

 function GetCurrentThreadID:TThreadId;
 procedure Sleep(time:integer);
 procedure TerminateThread(threadHandle:TThreadID;exitCode:cardinal);

 {$IFDEF IOS}
 function NSStrUTF8(st:string):NSString;
 {$ENDIF}
 procedure OpenURL(url:string);
 function LaunchProcess(fname:string;params:string=''):boolean;

 {$IFDEF MSWINDOWS}
 function LoadCursorFromFile(fname:PChar):HCursor;
 function LoadCursor(instance:cardinal;name:PChar):HCursor;
 function GetCursor:HCursor;
 procedure SetCursor(cursor:HCursor);

 function GetWindowRect(window:HWND;out rect:TRect):boolean;
 function MoveWindow(window:HWND;x,y,w,h:integer;repaint:boolean):boolean;
 {$ENDIF}

implementation
 uses SysUtils
  {$IFDEF IOS},pthreads,cfstring{$ENDIF}
  {$IFDEF MSWINDOWS},ShellAPI{$ENDIF};
 {$IFDEF IOS}
 // IOS threads
{ constructor TThread.Create(suspended:boolean);
  begin
   running:=false;
   id:=nil;
   terminated:=false;
   finished:=false;
   handle:=0;
   if not suspended then Resume;
  end;

 function trProc(p:pointer):pointer; cdecl;
  var
   thread:TThread;
   old:integer;
  begin
   if p=nil then exit;
   pthread_setcanceltype(PTHREAD_CANCEL_ASYNCHRONOUS,@old);
   thread:=p;
   thread.Execute;
   result:=@thread.returnValue;
   thread.finished:=true;
   thread.running:=false;
  end;

 procedure TThread.Resume;
  var
   attr:TThreadAttr;
   thread_id:TThreadID;
   rval:integer;
  begin
   if running then exit;
   pthread_attr_init(@attr);
   pthread_attr_setdetachstate(@attr,PTHREAD_CREATE_DETACHED);
   pthread_attr_setstacksize(@attr,65536);
   rval:=pthread_create(@thread_id,@attr,@trProc,self);
   if rval<>0 then raise Exception.Create('Failed to create PThread: '+inttostr(rval));
   running:=true;
   id:=thread_id;
   handle:=cardinal(id);
   pthread_attr_destroy(@attr);
  end;

 destructor TThread.Destroy;
  begin
   if running then begin
    pthread_cancel(id);
   end;
  end;

 procedure TThread.Execute;
  begin
  end;

 procedure TThread.Terminate;
  begin
   terminated:=true;
  end;    }

 procedure OpenURL(url:string);
  var
   u:NSURL;
  begin
   u:=NSURL.UrlWithString(NSSTR(PChar(url)));
   UIApplication.sharedApplication.OpenURL(u);
  end;

 function NSStrUTF8(st:string):NSString;
  begin
   if st<>'' then
    Result := NSString(CFStringCreateWithBytes(nil,@st[1],length(st),kCFStringEncodingUTF8,false))
   else
    result:=NSString(CFSTR(''));
  end;

 {$ENDIF}

// WINDOWS SET ===========================
{$IFDEF MSWINDOWS}
 procedure OpenURL(url:string);
  begin
   ShellExecute(0,'open',PChar(url),'','',SW_SHOW);
  end;

 function LaunchProcess(fname,params:string):boolean;
 {$IFDEF MSWINDOWS}
  var
   startupInfo:TStartupInfo;
   processInfo:TProcessInformation;
  begin
   fillchar(startupinfo,sizeof(startupinfo),0);
   startupInfo.cb:=sizeof(startupinfo);
   result:=CreateProcess(nil,PChar(fname+' '+params),nil,nil,false,0,nil,nil,startupInfo,processInfo);
  end;
 {$ELSE}
  begin
  end;
 {$ENDIF}

 function GetCurrentThreadID:cardinal;
  begin
   result:=windows.GetCurrentThreadId;
  end;

 procedure Sleep;
  begin
   windows.Sleep(time);
  end;

 procedure TerminateThread;
  begin
   windows.TerminateThread(threadHandle,exitCode);
  end;

 function LoadCursorFromFile(fname:PChar):HCursor;
  begin
   result:=windows.LoadCursorFromFile(fname);
  end;

 function LoadCursor(instance:cardinal;name:PChar):HCursor;
  begin
   result:=windows.LoadCursor(instance,name);
  end;
 function GetCursor:HCursor;
  begin
   result:=windows.GetCursor;
  end;
 procedure SetCursor(cursor:HCursor);
  begin
   windows.SetCursor(cursor);
  end;
 function GetTickCount:cardinal;
  begin
   result:=windows.getTickCount;
  end;
 procedure QueryPerformanceCounter;
  begin
   windows.QueryPerformanceCounter(value);
  end;
 procedure QueryPerformanceFrequency;
  begin
   windows.QueryPerformanceFrequency(value);
  end;
 function GetWindowRect(window:HWND;out rect:TRect):boolean;
  begin
   result:=windows.GetWindowRect(window,rect);
  end;
 function MoveWindow(window:HWND;x,y,w,h:integer;repaint:boolean):boolean;
  begin
   result:=windows.MoveWindow(window,x,y,w,h,repaint);
  end;
{$ENDIF}

// iOS SET ===========================================================
{$IFDEF IOS}
var
  startTime:NSDate;
  lastInterval:NSTimeInterval=0;
  startTime2:double;

 procedure Sleep(time:integer);
  begin
   NSThread.sleepForTimeInterval(time/1000);
   //Sleep(time);
  end;

 function GetCurrentThreadID;
  begin
   result:=system.getCurrentThreadID;
  end;

 procedure TerminateThread(threadHandle:system.TThreadID;exitCode:cardinal);
  begin
   CloseThread(threadHandle);
  end;

 function GetTickCount:cardinal;
  var
   interval:NSTimeInterval;
  begin
   if startTime=nil then begin
     startTime:=NSDate.date;
     startTime.retain;
   end;
   interval:=-startTime.timeIntervalSinceNow;
   if interval<lastInterval then interval:=lastInterval
    else lastInterval:=interval;
   result:=round(interval*1000)+100000; // bias
  end;

 procedure QueryPerformanceCounter;
  var
    time:double;
  begin
   time:=CACurrentMediaTime;
   if startTime2=0 then startTime2:=time;
   value:=round((time-startTime2)*1000000);
  end;

 procedure QueryPerformanceFrequency;
  begin
   value:=1000000;
  end;
{$ENDIF}

end.
