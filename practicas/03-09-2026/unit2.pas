unit Unit2;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TForm2 }

  TForm2 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Edit2Change(Sender: TObject);
  private

  public

  end;

var
  Form2: TForm2;
  arr: array [0..5] of real;

implementation


{$R *.lfm}

{ TForm2 }

procedure TForm2.Button1Click(Sender: TObject);
var
  S1, S2: Integer;
begin
  if TryStrToInt(Edit1.Text, S1) and
     TryStrToInt(Edit2.Text, S2) then
    Edit3.Text := IntToStr(S1 + S2)
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

procedure TForm2.Edit2Change(Sender: TObject);
begin

end;

end.

