unit TimerQueue;

interface

uses
  Windows, SysUtils, Generics.Collections, System.SyncObjs;

type
  TCallback = procedure of object;
  TRefCallback = reference to procedure;

  TTimerInfo = record
    Proc: TCallback;
    RefProc: TRefCallback;
    Timer, Queue: THandle;
  end;
  PTimerInfo = ^TTimerInfo;

  TScheduler = class
  private
    FQueue: THandle;
    FTimers: TDictionary<THandle, PTimerInfo>;
    FLock: TCriticalSection;
  public
    constructor Create;
    destructor Destroy; override;

    function AddSchedule(Milliseconds: Cardinal; Proc: TCallback): THandle; overload;
    function AddSchedule(Milliseconds: Cardinal; Proc: TRefCallback): THandle; overload;
    function AddRepeatedJob(Interval: Cardinal; Proc: TCallback): THandle;

    procedure CancelSchedule(Handle: THandle);
    procedure RemoveRepeatedJob(Handle: THandle);

    procedure TimerDone(Handle: THandle);
  end;

var
  Sched: TScheduler;    // singleton

implementation

{ TScheduler }

constructor TScheduler.Create;
begin
  FQueue := CreateTimerQueue;
  FTimers := TDictionary<THandle, PTimerInfo>.Create;
  FLock := TCriticalSection.Create;
end;

destructor TScheduler.Destroy;
begin
  DeleteTimerQueueEx(FQueue, INVALID_HANDLE_VALUE);
  FTimers.Free;
  FLock.Free;

  inherited;
end;

procedure OnSchedule(Context: PTimerInfo; Fired: Boolean); stdcall;
var
  E: Cardinal;
begin
  try
    if @Context^.Proc <> nil then
      Context^.Proc()
    else
      Context^.RefProc();

    if not DeleteTimerQueueTimer(Context^.Queue, Context^.Timer, 0) then
    begin
      E := GetLastError;
      if E <> ERROR_IO_PENDING then
        WriteLn(Format('Deleting a timer failed with %d', [E]));
    end;
  finally
    Sched.TimerDone(Context^.Timer);
  end;
end;

procedure OnRepeat(Context: PTimerInfo; Fired: Boolean); stdcall;
begin
  Context^.Proc();
end;

function TScheduler.AddSchedule(Milliseconds: Cardinal; Proc: TCallback): THandle;
var
  Timer: THandle;
  Info: PTimerInfo;
begin
  New(Info);
  Info^.Proc := Proc;
  Info^.RefProc := nil;
  Info^.Queue := FQueue;

  if not CreateTimerQueueTimer(Timer, FQueue, @OnSchedule, Info, Milliseconds, 0, WT_EXECUTEONLYONCE) then
    raise Exception.Create('Creating a timer (schedule) failed!');

  Info^.Timer := Timer;

  FLock.Acquire;
  try
    Result := Timer;
    FTimers.Add(Result, Info);
  finally
    FLock.Release;
  end;
end;

function TScheduler.AddSchedule(Milliseconds: Cardinal; Proc: TRefCallback): THandle;
var
  Timer: THandle;
  Info: PTimerInfo;
begin
  New(Info);
  Info^.Proc := nil;
  Info^.RefProc := Proc;
  Info^.Queue := FQueue;

  if not CreateTimerQueueTimer(Timer, FQueue, @OnSchedule, Info, Milliseconds, 0, WT_EXECUTEONLYONCE) then
    raise Exception.Create('Creating a timer (schedule) failed!');

  Info^.Timer := Timer;

  FLock.Acquire;
  try
    Result := Timer;
    FTimers.Add(Result, Info);
  finally
    FLock.Release;
  end;
end;

procedure TScheduler.CancelSchedule(Handle: THandle);
begin
  try
    if not DeleteTimerQueueTimer(FQueue, Handle, 0) then
    begin
      if GetLastError <> ERROR_IO_PENDING then
        raise Exception.Create('Cancelling a timer failed!');
    end;
  finally
    TimerDone(Handle);
  end;
end;

function TScheduler.AddRepeatedJob(Interval: Cardinal; Proc: TCallback): THandle;
var
  Info: PTimerInfo;
begin
  New(Info);
  Info^.Proc := Proc;

  if not CreateTimerQueueTimer(Result, FQueue, @OnRepeat, Info, Interval, Interval, WT_EXECUTEDEFAULT) then
    raise Exception.Create('Creating a timer (repeat) failed!');

  FLock.Acquire;
  try
    FTimers.AddOrSetValue(Result, Info);
  finally
    FLock.Release;
  end;
end;

procedure TScheduler.RemoveRepeatedJob(Handle: THandle);
begin
  if not DeleteTimerQueueTimer(FQueue, Handle, 0) then
    raise Exception.Create('Deleting a timer (repeat) failed!');

  TimerDone(Handle);
end;

procedure TScheduler.TimerDone(Handle: THandle);
begin
  FLock.Acquire;
  try
    if not FTimers.ContainsKey(Handle) then
    begin
      WriteLn('Could not dispose timer info');
      Exit;
    end;

    Dispose(FTimers[Handle]); // Also free the record we allocated

    FTimers.Remove(Handle);
  finally
    FLock.Release;
  end;
end;

// Singleton handling
initialization
  Sched := TScheduler.Create;

finalization
  Sched.Free;

end.
