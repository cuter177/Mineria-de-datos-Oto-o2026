unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids, Menus, StdCtrls,
  ComCtrls, ExtCtrls, TAGraph, TASeries, TATypes, TAFuncSeries, TAColorMap, uDatos;

type
  TFloatArray = array of real;

TResumen = record
  Minimo, Maximo, Media, Desv, Sesgo, Kurtosis : Real;
end;

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button10: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    Button8: TButton;
    Button9: TButton;
    Chart1: TChart;
    Chart1ColorMapSeries1: TColorMapSeries;
    Chart2: TChart;
    ComboBox1: TComboBox;
    ComboBox2: TComboBox;
    ComboBox3: TComboBox;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Label2: TLabel;
    Label20: TLabel;
    Label21: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    ListBox1: TListBox;
    MainMenu1: TMainMenu;
    Memo1: TMemo;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    OpenDialog1: TOpenDialog;
    OpenDialog2: TOpenDialog;
    PageControl1: TPageControl;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    SaveDialog1: TSaveDialog;
    SaveDialog2: TSaveDialog;
    StringGrid1: TStringGrid;
    StringGrid2: TStringGrid;
    StringGrid3: TStringGrid;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    TabSheet4: TTabSheet;
    TabSheet5: TTabSheet;
    procedure Button10Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Label5Click(Sender: TObject);

    procedure MenuItem2Click(Sender: TObject);
    procedure MenuItem3Click(Sender: TObject);
    procedure MenuItem4Click(Sender: TObject);
    procedure RefrescarCombos;
    procedure ComboChange(Sender: TObject);
    procedure Chart1ColorMapSeries1Calculate(const AX, AY: Double; out AZ: Double);
  private
    FDibujar: Boolean;
    FPoints: TLineSeries;
    FTrend: TLineSeries;
    FHeatCols: array of TFloatArray;
    FHeatNCols, FHeatNRows: Integer;
    FHeatMin, FHeatMax: Real;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}


{  Funciones y procedimientos auxiliares                             }


{ Lee la columna Col como números. Se salta la fila 0 (encabezado). }
function LeerColumna(Grid: TStringGrid; Col: Integer): TFloatArray;
var
  i, n: Integer;
begin
  Result := nil;
  n := Grid.RowCount - 1;
  SetLength(Result, n);
  for i := 0 to n - 1 do
    Result[i] := StrToFloatDef(Grid.Cells[Col, i + 1], 0.0);
end;

{ Cuantil q (0..1) del vector a, por ordenamiento ascendente. }
function Cuantil(const a: TFloatArray; q: Double): Double;
var
  s: TFloatArray;
  i, j: Integer;
  tmp: Double;
begin
  s := Copy(a, 0, Length(a));
  for i := 0 to High(s) - 1 do
    for j := i + 1 to High(s) do
      if s[j] < s[i] then
      begin
        tmp := s[i];
        s[i] := s[j];
        s[j] := tmp;
      end;
  Result := s[Trunc(q * (Length(s) - 1))];
end;

{ Normaliza una sola columna al intervalo indicado por el usuario. }
procedure MinMaxColumna(Grid: TStringGrid; Col: Integer; Min, Max: Double);
var
  d: TFloatArray;
  i: Integer;
  mn, mx: Double;
begin
  d := LeerColumna(Grid, Col);
  if Length(d) = 0 then Exit;

  mn := d[0];
  mx := d[0];
  for i := 1 to High(d) do
  begin
    if d[i] < mn then mn := d[i];
    if d[i] > mx then mx := d[i];
  end;

  if mx = mn then Exit;   // columna constante: no se puede normalizar

  for i := 0 to High(d) do
    Grid.Cells[Col, i + 1] := FormatFloat('0.0000',
      Min + ((d[i] - mn) / (mx - mn)) * (Max - Min));
end;

//Normaliza una sola columna con Robust Scaling:  (x - mediana) / IQR.
procedure RobustColumna(Grid: TStringGrid; Col: Integer);
var
  d: TFloatArray;
  i: Integer;
  mediana, q1, q3, iqr: Double;
begin
  d := LeerColumna(Grid, Col);
  if Length(d) = 0 then Exit;

  mediana := Cuantil(d, 0.5);
  q1 := Cuantil(d, 0.25);
  q3 := Cuantil(d, 0.75);
  iqr := q3 - q1;

  if iqr = 0 then Exit;   // columna constante: no se puede normalizar

  for i := 0 to High(d) do
    Grid.Cells[Col, i + 1] := FormatFloat('0.0000', (d[i] - mediana) / iqr);
end;

function CalcularResumen(const a: TFloatArray): TResumen;
var
  i, n: integer;
  suma, m2, m3, m4 , v: Real;
begin
  Result.Minimo := 0;
  Result.desv := 0;
  Result.Maximo := 0;
  result.Media := 0;
  Result.kurtosis := 0;
  Result.Sesgo := 0;

  n := Length(a); //tam del arreglo
  if n = 0 then
     EXIT;

  Result.Minimo := a[0];
  Result.Maximo := a[0];
  suma := 0;

  for i:=0 to n-1 do
  begin
    if a[i] < Result.minimo then
       result.minimo := a[i];
    if a[i] > Result.maximo then
       result.maximo := a[i];
    suma := suma + a[i];
  end;

  result.media := suma / n;

  //segunda vuelta al arreglo
  m2 := 0;
  m3 := 0;
  m4 := 0;

  for i:=0 to n-1 do
  begin
    v := a[i] - result.media;
    m2 := m2 + v * v;
    m3 := m3 + v * v * v;
    m4 := m4 + v * v * v * v;
  end;

  m2 := m2 / n;
  Result.desv := sqrt(m2);
  if result.desv > 0 then
  begin
    m3 := m3 / n;
    result.sesgo := m3 / (Result.desv * Result.desv * Result.desv);

    m4 := m4 / n;
    result.kurtosis := m4 / (Result.desv * Result.desv * Result.desv * Result.desv) - 3;
  end;

end;

{Rango promedio de cada elemento}
function Rango(const a: TFloatArray): TFloatArray;
var
  indice: array of Integer;
  i, j, k, aux: integer;
  rang : Real;

begin

  Result := nil;
  if length(a) = 0 then
     Exit;
  SetLength(Result, length(a));
  indice := nil;
  SetLength(indice, length(a));

  for i:= 0 to length(indice) - 1 do
      indice[i] := i;

  //sort de tipo burbuja
  for i := 0 to length(indice) - 2 do
      for j := i+1 to length(indice) - 1 do
          if a[indice[j]] < a[indice[i]] then
          begin
            aux := indice[i];
            indice[i] := indice[j];
            indice[j] := aux;
          end;
  i := 0;
  while i <= high(indice) do
  begin
    j := i;
    while(j < high(indice)) and (a[indice[j+1]] = a[indice[i]]) do
            inc(j);

    rang := ((i + j) / 2.0) + 1.0;

    for k := i to j do
        Result[indice[k]] := rang;
    i := j + 1;
  end;


end;

{coorelacion de spearman entre dos vectores}
function Spearman(const x, y: TFloatArray):Double;
var
  rx, ry : TFloatArray;
  mx, my, cov, sx, sy : Real;
  i, n : integer;
begin
  result := 0;
  n := length(x);

  if (n = 0) or (n <>  length(y)) then
     Exit;

  rx := Rango(x);
  ry := Rango(y);

  mx := 0;
  my := 0;

  for i := 0 to n-1 do
  begin
    mx := mx + rx[i];
    my := my + ry[i];
  end;

  mx := mx / n;
  my := my / n;

  cov := 0;
  sx := 0;
  sy := 0;

  for i:=0 to n-1 do
  begin
    cov := cov + (rx[i] - mx) * (ry[i] - my);
    sx := sx + Sqr(rx[i] - mx);
    sy := sy + Sqr(ry[i] - my);
  end;

  if(sx = 0) or (sy = 0) then
        Exit;
  Result := cov / sqrt(sx * sy);

end;

procedure TForm1.RefrescarCombos;
var
i, num_atributos : Integer;
begin
  ComboBox1.Items.Clear;
  ComboBox2.Items.Clear;

  num_atributos := StringGrid1.ColCount - 1;
  for i := 0 to num_atributos - 1 do
  begin
    ComboBox1.Items.Add(Format('At. %d', [i]));
    ComboBox2.Items.Add(Format('At. %d', [i]));
  end;

  if num_atributos > 0 then
  begin
    ComboBox1.ItemIndex := 0;
    if num_atributos > 1 then
      ComboBox2.ItemIndex := 1
    else
      ComboBox2.ItemIndex := 0;
  end;

end;



procedure TForm1.Button1Click(Sender: TObject);
var
  col: Integer;
begin
  for col := 0 to StringGrid1.ColCount - 2 do   // todas menos la última
    RobustColumna(StringGrid1, col);
end;

procedure TForm1.Button10Click(Sender: TObject);
begin

end;

procedure TForm1.Button2Click(Sender: TObject);
var
  col: Integer;
  Min, Max: Double;
begin
  if not TryStrToFloat(Edit1.Text,Min) then
  begin
    ShowMessage('El valor de Min no es un número válido.');
    Edit1.SetFocus;
    Exit;
  end;

  if not TryStrToFloat(Edit2.Text, Max) then
  begin
    ShowMessage('El valor de Max no es un número válido.');
    Edit2.SetFocus;
    Exit;
  end;

  if Max <= Min then
  begin
    ShowMessage('Max debe ser mayor que Min.');
    Edit2.SetFocus;
    Exit;
  end;

  for col := 0 to StringGrid1.ColCount - 2 do   // todas menos la última
    MinMaxColumna(StringGrid1, col, Min, Max);
end;

procedure TForm1.Button3Click(Sender: TObject);
var
  j, numCol: integer;
  res: TResumen;
begin
  numCol := StringGrid1.Colcount - 1;
  StringGrid2.RowCount:= numCol + 1;

  for j:= 0 to numCOL - 1 do
  begin
    res := CalcularResumen(LeerColumna(StringGrid1, j));
    StringGrid2.Cells[0, j + 1] := Format('Atributo %d', [j]);
    StringGrid2.Cells[1, j + 1] := FormatFloat('0.0000', res.Minimo);
    StringGrid2.Cells[2, j + 1] := FormatFloat('0.0000', res.Maximo);
    StringGrid2.Cells[3, j + 1] := FormatFloat('0.0000', res.Media);
    StringGrid2.Cells[4, j + 1] := FormatFloat('0.0000', res.Desv);
    StringGrid2.Cells[5, j + 1] := FormatFloat('0.0000', res.Sesgo);
    StringGrid2.Cells[6, j + 1] := FormatFloat('0.0000', res.Kurtosis);
  end;

end;

procedure TForm1.Button4Click(Sender: TObject);
var
  i, j, num_atributos : Integer;
  cols : array of TFloatArray;
  r : Real;
begin
  ListBox1.Clear;

  num_atributos := StringGrid1.ColCount - 1;
  if num_atributos <= 0 then
     Exit;

  cols := nil;
  SetLength(cols, num_atributos);

  for i := 0 to num_atributos - 1 do
      cols[i] := LeerColumna(StringGrid1, i);
  for i := 0 to num_atributos - 2 do
      for j := i + 1 to num_atributos - 1 do
      begin
        r := Spearman(cols[i], cols[j]);
        if Abs(r) >= 0.50 then
           ListBox1.Items.Add(Format('At. %d vs At. %d (r = %.4f)', [i, j, r]));
      end;

  if ListBox1.Items.Count = 0 then
     ListBox1.Items.Add('No hay pares con |r| >= 0.50');
end;

procedure TForm1.Button5Click(Sender: TObject);
var
  i, n, ix, iy: Integer;
  x, y: TFloatArray;
  xmin, xmax, mX, mY, sxy, sxx, b0, b1: Real;  //incio, fin, pendiente, media de la recta
begin
  if (ComboBox1.ItemIndex < 0) or (ComboBox2.ItemIndex < 0) then
  begin
    RefrescarCombos;
    if (ComboBox1.ItemIndex < 0) or (ComboBox2.ItemIndex < 0) then
       Exit;
  end;

  ix := ComboBox1.ItemIndex;
  iy := ComboBox2.ItemIndex;
  x := LeerColumna(StringGrid1, ix);
  y := LeerColumna(StringGrid1, iy);
  n := Length(x);


  if (n = 0) or (Length(y) <> n) then
     Exit;

  // puntos de la dispersión
  FPoints.Clear;
  xmin := x[0];
  xmax := x[0];


  for i := 0 to n - 1 do
  begin
    FPoints.AddXY(x[i], y[i]);

    if x[i] < xmin then
       xmin := x[i];

    if x[i] > xmax then
       xmax := x[i];
  end;

  // línea central
  mX := 0;
  mY := 0;

  for i := 0 to n - 1 do
  begin
    mX := mX + x[i];

    mY := mY + y[i];
  end;

  mX := mX / n;
  mY := mY / n;

  sxy := 0;
  sxx := 0;

  for i := 0 to n - 1 do
  begin
    sxy := sxy + (x[i] - mX) * (y[i] - mY);

    sxx := sxx + (x[i] - mX) * (x[i] - mX);
  end;

  FTrend.Clear;
  if sxx > 0 then
  begin
    b1 := sxy / sxx;  // pendiente
    b0 := mY - b1 * mX;      // y = 0 de la recta
    FTrend.AddXY(xmin, b0 + b1 * xmin);
    FTrend.AddXY(xmax, b0 + b1 * xmax);
  end;

  Chart2.Title.Text.Text := Format('Atributo %d (Y) vs %d (X)   Spearman r = %.4f',
    [iy, ix, Spearman(x, y)]);
end;

procedure TForm1.Button6Click(Sender: TObject);
var
  i, j : Integer;

begin
  FHeatNCols := StringGrid1.ColCount - 1;
  FHeatNRows := StringGrid1.RowCount - 1;

  if (FHeatNCols <= 0) or (FHeatNRows <= 0) then
     Exit;

  SetLength(FHeatCols, FHeatNCols);

  FHeatmin := 1e300;
  FHeatmax := -1e300;

  for j:=0 to FHeatNCols - 1 do
  begin
    FHeatCols[j] := LeerColumna(StringGrid1, j);

    for i := 0 to High(FHeatCols[j]) do
    begin
      if FHeatCols[j][i] < FHeatMin then
         FHeatMin := FHeatCols[j][i];

      if FHeatCols[j][i] > FHeatMax then
         FHeatMax := FHeatCols[j][i];
    end;
  end;

  with Chart1ColorMapSeries1 do
  begin
    Extent.UseXMin := true;
    Extent.XMin := 0;

    Extent.UseXMax := true;
    Extent.XMax := FHeatNCols - 1;

    Extent.UseYMin := true;
    Extent.YMin := 0;

    Extent.UseYMax := true;
    Extent.YMax := FHeatNRows - 1;

    StepX := 1;
    StepY := 1;

    Interpolate := False;
    BuiltInPalette := cmpRainbow;
    BuiltInPaletteMin := FHeatMin;
    BUiltInPaletteMax := FHeatMax;
  end;
  Chart1.Invalidate;
end;

procedure TForm1.Button7Click(Sender: TObject);
begin

end;

procedure TForm1.Button8Click(Sender: TObject);
begin

end;

procedure TForm1.Button9Click(Sender: TObject);
begin

end;

procedure TForm1.Chart1ColorMapSeries1Calculate(const AX, AY: Double; out AZ: Double);
var
  col, row : Integer;
begin
  col := Trunc(AX);
  row := Trunc(AY);

  if (col >= 0) and (col < FHeatNCols) and (row >= 0) and (row < FHeatNRows) then
     AZ := FHeatCols[col][row]
  else
     AZ := FHeatMin;
end;

procedure TForm1.ComboChange(Sender: TObject);
begin
  FPoints.Clear;
  FTrend.Clear;
  Chart2.Title.Text.Text := '';
end;



procedure TForm1.FormCreate(Sender: TObject);
begin
  PageControl1.Align := alClient;

  // 2) Barra inferior con botones, DENTRO de la pestaña
  Panel1.Parent := TabSheet1;
  Panel1.Align := alBottom;
  Panel1.Height := 48;
  Panel1.Caption := '';
  Panel1.BevelOuter := bvNone;

  // Todos los controles de normalización deben compartir este panel.
  // Si Button2 queda en TabSheet1, se dibuja encima de la barra inferior.
  Button2.Parent := Panel1;
  Label8.Parent := Panel1;
  Edit1.Parent := Panel1;
  Label9.Parent := Panel1;
  Edit2.Parent := Panel1;

  Label8.Left := 8;   Label8.Top := 14;
  Edit1.Left := 42;   Edit1.Top := 10;  Edit1.Width := 80;  Edit1.Height := 28;
  Label9.Left := 132; Label9.Top := 14;
  Edit2.Left := 166;  Edit2.Top := 10;  Edit2.Width := 80;  Edit2.Height := 28;
  Button2.Left := 270; Button2.Top := 12; Button2.Width := 147;

  Panel2.Parent := TabSheet2;
  Panel2.Align := alBottom;
  Panel2.Height := 48;
  Panel2.Caption := '';
  Panel2.BevelOuter:= bvNone;;

  Button1.Parent := Panel1;
  Button1.Left := 430; Button1.Top := 12; Button1.Width := 144;

  Button3.Parent := Panel2;
  // 3) GroupBox a un costado
  GroupBox1.Parent := TabSheet1;
  GroupBox1.Align := alRight;
  GroupBox1.Width := 209;
  GroupBox1.Caption := 'Información';
  Label1.Left := 12; Label1.Top := 16;
  Label3.Left := 80; Label3.Top := 16;
  Label2.Left := 12; Label2.Top := 48;
  Label4.Left := 92; Label4.Top := 48;


  StringGrid1.Parent := TabSheet1;
  StringGrid1.Align := alClient;

  StringGrid2.Parent := TabSheet2;
  StringGrid2.Align := alClient;


  // Gráfica de dispersión
  Chart2.Align := alClient;

  FPoints := TLineSeries.Create(Self);
  FPoints.Title := 'Datos';
  FPoints.ShowLines := False;           // solo puntos (dispersión)
  FPoints.ShowPoints := True;
  FPoints.Pointer.Style := psCircle;
  FPoints.Pointer.Brush.Color := clBlue;
  FPoints.Pointer.Pen.Color := clBlue;
  Chart2.AddSeries(FPoints);

  FTrend := TLineSeries.Create(Self);
  FTrend.Title := 'Tendencia';
  FTrend.ShowLines := True;             // línea central
  FTrend.ShowPoints := False;
  FTrend.LinePen.Color := clRed;
  FTrend.LinePen.Width := 2;
  Chart2.AddSeries(FTrend);

  //grafica de color
  FDibujar := False;
  ComboBox1.OnChange := @ComboChange;
  ComboBox2.OnChange := @ComboChange;
  Chart1ColorMapSeries1.OnCalculate := @Chart1ColorMapSeries1Calculate;
end;

procedure TForm1.Label5Click(Sender: TObject);
begin

end;




procedure TForm1.MenuItem2Click(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    StringGrid1.LoadFromCSVFile(OpenDialog1.FileName);
    Label3.Caption := IntToStr(StringGrid1.RowCount);
    Label4.Caption := IntToStr(StringGrid1.ColCount);
    RefrescarCombos;
  end;
end;

procedure TForm1.MenuItem3Click(Sender: TObject);
begin
  if SaveDialog1.Execute then
    StringGrid1.SaveToCSVFile(SaveDialog1.FileName);
end;

procedure TForm1.MenuItem4Click(Sender: TObject);
begin
  if OpenDialog2.Execute then
  begin
    StringGrid1.LoadFromCSVFile(OpenDialog2.FileName);
    Label3.Caption := IntToStr(StringGrid1.RowCount);
    Label4.Caption := IntToStr(StringGrid1.ColCount);
    RefrescarCombos;
  end;

end;





end.
