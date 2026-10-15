unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, TAGraph,
  TASeries, TAtypes;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Chart1: TChart;
    Chart1LineSeries1: TLineSeries;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    CheckBox3: TCheckBox;
    ComboBox1: TComboBox;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;
  cont: integer;

implementation
 uses unit2;

{$R *.lfm}

{ TForm1 }


procedure TForm1.Button1Click(Sender: TObject);
var
  x: Real;
  y: Real;
begin
  Chart1LineSeries1.Clear;

  Chart1LineSeries1.LinePen.Color := clRed;
  Chart1LineSeries1.LinePen.Width := 3;

  x := -6.28;

  while x <= 6.28 do
  begin
    y := x
       - x*x*x / (1*2*3)
       + x*x*x*x*x / (5*4*3*2)
       - x*x*x*x*x*x*x / (7*6*5*4*3*2)
       + x*x*x*x*x*x*x*x*x / (9*8*7*6*5*4*3*2)
       - x*x*x*x*x*x*x*x*x*x*x / (11*10*9*8*7*6*5*4*3*2)
       + x*x*x*x*x*x*x*x*x*x*x*x*x / (13*12*11*10*9*8*7*6*5*4*3*2);

    Chart1LineSeries1.AddXY(x, y);

    x := x + 0.01;
  end;
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  x : integer;
  y : integer;
  xi: integer;
begin
  //graficar dispersion de valores aleatorios

  Chart1LineSeries1.Clear;
  //propiedades
  Chart1LineSeries1.pointer.brush.color:=clred;
  Chart1LineSeries1.pointer.Style:=pscircle;
  Chart1LineSeries1.pointer.visible:=true;
  Chart1LineSeries1.showlines:=false;
  for xi:=0 to 40 do
  begin
     X:=random(10)*100;
     y:=random(70)*50;
     Chart1LineSeries1.addxy(x,y);
  end;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  Form2.showmodal;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  if checkbox1.checked then
  begin
    showMessage('se eligio checkbox 1');
  end;
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
  comboBox1.items.add('Opcion ' + inttoStr(cont));
  cont := cont + 1;
end;

end.

