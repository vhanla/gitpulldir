program gitpulldir;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  SysUtils, Classes, Windows;

const
  // ANSI color codes
  ANSI_RESET = #27'[0m';
  ANSI_BOLD = #27'[1m';
  ANSI_RED = #27'[31m';
  ANSI_GREEN = #27'[32m';
  ANSI_YELLOW = #27'[33m';
  ANSI_BLUE = #27'[34m';
  ANSI_MAGENTA = #27'[35m';
  ANSI_CYAN = #27'[36m';
  ANSI_WHITE = #27'[37m';
  ANSI_BRIGHT_GREEN = #27'[92m';
  ANSI_BRIGHT_YELLOW = #27'[93m';
  ANSI_BRIGHT_MAGENTA = #27'[95m';
  ANSI_BRIGHT_CYAN = #27'[96m';

function ExecAndCapture(const CommandLine: string; var Output: string): Integer;
var
  SecurityAttr: TSecurityAttributes;
  ReadPipe, WritePipe: THandle;
  StartInfo: TStartupInfo;
  ProcInfo: TProcessInformation;
  Buffer: array[0..255] of AnsiChar;
  BytesRead: DWORD;
  AppRunning: DWORD;
begin
  SecurityAttr.nLength := SizeOf(TSecurityAttributes);
  SecurityAttr.bInheritHandle := True;
  SecurityAttr.lpSecurityDescriptor := nil;

  if CreatePipe(ReadPipe, WritePipe, @SecurityAttr, 0) then
  begin
    FillChar(StartInfo, SizeOf(TStartupInfo), 0);
    StartInfo.cb := SizeOf(TStartupInfo);
    StartInfo.hStdOutput := WritePipe;
    StartInfo.hStdError := WritePipe;
    StartInfo.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
    StartInfo.wShowWindow := SW_HIDE;

    if CreateProcess(nil, PChar(CommandLine), nil, nil, True, 0, nil, nil, StartInfo, ProcInfo) then
    begin
      CloseHandle(WritePipe);
      repeat
        AppRunning := WaitForSingleObject(ProcInfo.hProcess, 100);
        repeat
          BytesRead := 0;
          ReadFile(ReadPipe, Buffer, 255, BytesRead, nil);
          Buffer[BytesRead] := #0;
          OemToAnsi(Buffer, Buffer);
          Output := Output + string(buffer);
          write(buffer);
        until (BytesRead < 255);
      until (AppRunning <> WAIT_TIMEOUT);
      GetExitCodeProcess(ProcInfo.hProcess, DWORD(Result));
      CloseHandle(ProcInfo.hProcess);
      CloseHandle(ProcInfo.hThread);
    end;
    CloseHandle(ReadPipe);    
  end;

end;

procedure ExecAndWait(const CommandLine: string);
var
  StartInfo: TStartupInfo;
  ProcInfo: TProcessInformation;
begin
  FillChar(StartInfo, SizeOf(TStartupInfo), 0);
  FillChar(ProcInfo, SizeOf(TProcessInformation), 0);
  StartInfo.cb := SizeOf(TStartupInfo);

  if CreateProcess(nil, PChar(CommandLine), nil, nil, False, 0, nil, nil, StartInfo, ProcInfo) then
  begin
    WaitForSingleObject(ProcInfo.hProcess, INFINITE);
    CloseHandle(ProcInfo.hProcess);
    CloseHandle(ProcInfo.hThread);
  end
  else
    Write(ANSI_RED, 'Failed to execute: ', CommandLine, ANSI_RESET, sLineBreak);
end;

var
  sr: Sysutils.TSearchRec;
  res: Integer;
  opt: String;
  basedir: String;
  directories: TStringList;
  failedDirs: TStringList;
  i: Integer;
  allAtOnce: Boolean;
  exitCode: Integer;
  output: string;
begin
  allAtOnce:= False;
  failedDirs := TStringList.Create;
  directories := TStringList.Create;
  try
    try
      Write(ANSI_BRIGHT_CYAN, '=== Git Pull Directories ===', ANSI_RESET, sLineBreak);

      basedir := GetCurrentDir;

      res := FindFirst(basedir + '\*.*', faAnyFile, sr);
      if res = 0 then
      try
        while res = 0 do
        begin
          if (sr.Attr and faDirectory = faDirectory)
          and (sr.Name <> '.') and (sr.Name <> '..')
          then
          begin
            if (DirectoryExists(basedir + '\' + sr.Name + '\.git')) then
            begin
              directories.Add(basedir + '\' + sr.Name);
            end;
          end;
          res := FindNext(sr);
        end;
      finally
        Sysutils.FindClose(sr);
      end;

      for I := 0 to directories.Count - 1 do
      begin
        Writeln;
        if allAtOnce then
        begin
          Write(ANSI_BRIGHT_YELLOW, '['+IntToStr(I+1)+'/'+IntToStr(directories.Count)+']'+ directories[I] + ' [...]', ANSI_RESET, sLineBreak);
          opt := 'y';
        end
        else
        begin
          Write(ANSI_BRIGHT_YELLOW, '['+IntToStr(I+1)+'/'+IntToStr(directories.Count)+']'+ directories[I] + '? [y/n/a/q]', ANSI_RESET, sLineBreak);
          Readln(opt);
        end;
        if (opt = 'y') or (opt = 'a') then
        begin
          if opt = 'a' then allAtOnce := True;

          SetCurrentDirectory(PChar(directories[i]));
          Write(ANSI_BRIGHT_GREEN, 'Pulling updates...', ANSI_RESET, sLineBreak);
          output := '';
          exitCode := ExecAndCapture('git pull', output);
          if exitCode <> 0 then
          begin
            failedDirs.Add(directories[i]);
            Write(ANSI_RED, 'Failed to pull updates...', ANSI_RESET, sLineBreak);
          end;

//          ExecAndWait('git pull');
          SetCurrentDirectory(PChar(basedir));
        end
        else if opt = 'q' then // quit batch process
        begin
          Write(ANSI_YELLOW, 'Git Pull Dir Cancelled!', ANSI_RESET, sLineBreak);
          Break;
        end;
             
      end;

      if failedDirs.Count > 0 then
      begin
        Write(ANSI_RED, 'The following directories failed to pull update:', ANSI_RESET, sLineBreak);
        for opt in failedDirs do
          Writeln(opt);

      end;
      

    except
      on E: Exception do
        Write(ANSI_RED, E.ClassName, ': ', E.Message, ANSI_RESET, sLineBreak);
    end;
  finally
      directories.Free;
      failedDirs.Free;
  end;


end.
