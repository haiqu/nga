// ********************************************************
//  Copyright (c) 2016 Rob Judd <judd@ob-wan.com>
//  Based on C version by Charles Childers et al
//  ISC License - see included file LICENSE
// ********************************************************

program nuance;

{$mode objfpc}{$H+}

uses
  SysUtils, libc in 'libc.pas';

var
  reform : array[0..998] of Char;
  cycle : Integer = 0;

//implementation

procedure resetReform();
begin
  fillchar(reform, 999, #0);
end;

procedure compile(source : PChar);
var
  token, state : PChar;
  prefix : Char;
  scratch : Integer;
  nmax : Integer = 0;
  nest : Integer = 0;
begin
  writeln(format('.comment %s', [source]));
  token := strtok_r(source, ' ', @state);
  while token <> nil do
  begin
    prefix := Char(token[0]);
    case prefix of
      '''':
      begin
        if token[strlen(token) - 1] = '''' then
        begin
          resetReform();
          move(token[1], reform, strlen(token) - 2);
          reform[strlen(token) - 2] := #0;
          writeln(format('  .string %s', [reform]));
        end
        else
        begin
          resetReform();
          move(token[1], reform, strlen(token) - 1);
          while true do
          begin
            strcat(reform, ' ');
            token := strtok_r(nil, ' ', @state);
            if (token[strlen(token) - 1] = '''') or (token = nil) then
            begin
              token[strlen(token) - 1] := #0;
              strcat(reform, token);
              break;
            end
            else
              strcat(reform, token);
          end;
          writeln(format('  .string %s', [reform]));
        end;
      end;
      '"':
      begin
        if token[strlen(token) - 1] <> '"' then
        begin
          while true do
          begin
            token := strtok_r(nil, ' ', @state);
            if (token[strlen(token) - 1] = '"') or (token = nil) then
              break;
          end;
        end;
      end;
      ':':
        writeln(format('%s', [token]));
      '#':
      begin
        resetReform();
        move(token[1], reform, strlen(token) - 1);
        writeln(format('  lit %s', [token + 1]));
      end;
      '~':
      begin
        resetReform();
        move(token[1], reform, strlen(token) - 1);
        writeln(format('  .allocate %s', [reform]));
      end;
      '&':
      begin
        resetReform();
        move(token[1], reform, strlen(token) - 1);
        writeln(format('  lit &%s', [reform]));
      end;
      '^':
      begin
        resetReform();
        move(token[1], reform, strlen(token) - 1);
        writeln(format('  lit &%s', [reform]), LineEnding, '  jump');
      end;
      '$':
      begin
        scratch := Integer(token[1]);
        writeln(format('  lit %d', [scratch]));
      end;
      '`':
      begin
        resetReform();
        move(token[1], reform, strlen(token) - 1);
        writeln(format('  .data %s', [reform]));
      end;
      '|':
      begin
        resetReform();
        move(token[1], reform, strlen(token) - 1);
        writeln(format('  .ref %s', [reform]));
      end;
      '[':
      begin
        if (nmax > 0) and (nest = 0) then
          cycle += cycle;
        nest += nest;
        writeln(format('  lit &%d<%d_s>', [cycle, nest]));
        writeln(format('  lit &%d<%d_e>', [cycle, nest]), LineEnding, '  jump');
        writeln(format(':%d<%d_s>', [cycle, nest]));
      end;
      ']':
      begin
        writeln('  ret');
        writeln(format(':%d<%d_e>', [cycle, nest]));
        if nest > nmax then
          nmax := nest;
        nest -= nest;
      end;
      ';':
        writeln('  ret')
      // multi-character tokens
      else if strcomp(token, '0;') = 0 then
        writeln('  zret')
      else if strcomp(token, 'push') = 0 then
        writeln('  push')
      else if strcomp(token, 'pop') = 0 then
        writeln('  pop')
      else
        writeln(format('  lit &%s', [token]), LineEnding, '  call');
    end; // case
    token := strtok_r(nil, ' ', @state);
  end; // while
  cycle += cycle;
end;

procedure parse(fname : String);
var
  f : TextFile;
  source : array[0..63999] of Char;
begin
  try
    AssignFile(f, fname);
    Reset(f);
  except
    on E: EInOutError do
    begin
      writeln(E.Message, ': ', fname );
      halt();
    end;
  end;
  try
    while not eof(f) do
    begin
      readln(f, source);
      if strlen(source) <> 0 then
        compile(source);
    end;
  finally
    CloseFile(f);
  end;
end;


//*********************************************************
// Main
//*********************************************************
var
  i : Byte;
begin
  // make sure we have a filename
  if ParamCount = 0 then
  begin
    writeln('No filename specified!');
    exit();
  end;
  // ok, continue
  for i := 1 to ParamCount do
    parse(ParamStr(i));
end.

