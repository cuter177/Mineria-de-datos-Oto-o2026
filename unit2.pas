unit Unit2;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ValEdit,
  ExtCtrls, Grids, ComCtrls;


type

  { TForm2 }



  TForm2 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    StringGrid1: TStringGrid;
    StringGrid2: TStringGrid;
    TrackBar1: TTrackBar;
    TrackBar2: TTrackBar;
    procedure Button1Click(Sender: TObject);
    procedure suma(s1:real;s2:real);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
    procedure TrackBar2Change(Sender: TObject);
  private

  public

  end;

var
  Form2: TForm2;
  arr: array [0..5] of real;
  mat: array [0..4, 0..4] of real;
  col, row : integer;

  md : array of array of real; //sin dimensiones


implementation


{$R *.lfm}

{ TForm2 }

procedure tform2.suma(s1:real;s2:real);
var
  resul:real;
begin
  resul := s1 + s2;
  Edit3.Text := floatToStr(S1 + S2)
end;

procedure TForm2.Button1Click(Sender: TObject);
var
  S1, S2: real;
begin
  if TryStrTofloat(Edit1.Text, S1) and
     TryStrTofloat(Edit2.Text, S2) then
      suma(s1,s2)

  else
    ShowMessage('Enter valid integers.');
end;

procedure TForm2.Button2Click(Sender: TObject);
var
  i: integer;
begin
   edit4.text:='';
   for i:=0 to 4 do
   begin
     arr[i]:=random(100);
     edit4.text:= edit4.text + floattostr(arr[i])+',';
   end;
end;

procedure TForm2.Button3Click(Sender: TObject);
var
  i,j: integer;
begin
   for i:= 0 to 4 do begin
     for j:= 0 to 4 do begin
       Mat[i,j] := random(100)*1.5;

       stringgrid1.cells[i,j]:=floattostr(mat[i,j]);
     end;
   end;
end;

procedure TForm2.Button4Click(Sender: TObject);
var
  i,j: integer;
begin
  setlength(md,col,row); //asignar dimenciones a md
  randomize();

  for i:= 0 to col-1 do begin
     for j:= 0 to row-1 do begin
       //asignar valor a md

       md[i,j] := random(100)*1.5;
       //visualizar en stringGrid
       stringgrid2.cells[i,j]:=floattostr(md[i,j]);
     end;
   end;

end;



procedure TForm2.TrackBar1Change(Sender: TObject);
begin
  col:= trackbar1.position;
  label6.caption:=inttostr(col);

  stringgrid2.colcount:=col;
  stringgrid2.width:=col*stringgrid2.defaultcolwidth + 5;
end;

procedure TForm2.TrackBar2Change(Sender: TObject);
begin
  row:= trackbar2.position;
  label7.caption:=inttostr(row);

  stringgrid2.rowcount:=row;
  stringgrid2.height:=row*stringgrid2.defaultrowheight + 5;
end;

procedure TForm2.FormCreate(Sender: TObject);
begin
  row := 1;
  col := 1;

  trackbar1.position:= col;
  trackbar2.position:= row;
  label6.caption:=inttostr(col);
  label7.caption:=inttostr(row);
end;



end.

