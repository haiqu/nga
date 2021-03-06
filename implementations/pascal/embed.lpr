// ********************************************************
//  Copyright (c) 2016 Rob Judd <judd@ob-wan.com>
//  Based on C version by Charles Childers et al
//  ISC License - see included file LICENSE
// ********************************************************

program embed;

{$mode objfpc}{$H+}

uses
  SysUtils, nga;


// ********************************************************
//  Main program
// ********************************************************
var
  i : Cell = 0;
  size : Cell;
begin
  ngaPrepare();

  if ParamCount > 0 then
    size := ngaLoadImage(ParamStr(1))
  else
    size := ngaLoadImage('ngaImage');

  if size = 0 then
    exit();

  writeln(format('ngaImageCells : Cell = %d;', [size]));
  write(format('ngaImage : array[0..%d] of Cell = (', [size - 1]));
  while size > i do
  begin
    if size > (i + 1) then
      write(format('%d,', [memory[i]]))
    else
      writeln(format('%d);', [memory[i]]));
    inc(i);
  end;
end.

