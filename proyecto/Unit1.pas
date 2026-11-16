unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, Forms, Controls, Graphics, Dialogs, Grids, Menus, StdCtrls,
  ComCtrls, ExtCtrls, TAGraph, TASeries, TATypes, TAFuncSeries, TAColorMap, uDatos;

type
  TFloatArray = array of real;

TResumen = record
  Minimo, Maximo, Media, Desv, Sesgo, Kurtosis : Real;
end;

type
  TVecino = record
  Indice: Integer;
  Distancia: Double;
end;
  TVecinoArray = array of TVecino;
  TIntArray = array of Integer;
  TDoubleArray = array of Double;

  TResultadoKNN = record
      Clase: Integer;
      Vecinos: TVecinoArray;
  end;

  TResultadoCV = record
    Pliegues: Integer;
    TamPliegue: TIntArray;
    AcTodos: TIntArray;
    AcRel: TIntArray;
    AcTotalTodos: Integer;
    AcTotalRel: Integer;
    PromedioTodos: Double;
    DesvTodos: Double;
    GlobalTodos: Double;
    PromedioRel: Double;
    DesvRel: Double;
    GlobalRel: Double;
  end;



  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button10: TButton;
    Button11: TButton;
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
    Edit4: TEdit;
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
    Label22: TLabel;
    Label23: TLabel;
    Label24: TLabel;
    Label25: TLabel;
    Label26: TLabel;
    Label27: TLabel;
    Label28: TLabel;
    lblInfoT: TLabel;
    lblInfoP: TLabel;
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
    ScrollBox1: TScrollBox;
    StringGrid1: TStringGrid;
    StringGrid2: TStringGrid;
    StringGrid3: TStringGrid;
    StringGrid4: TStringGrid;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    TabSheet4: TTabSheet;
    TabSheet5: TTabSheet;
    procedure Button10Click(Sender: TObject);
    procedure Button11Click(Sender: TObject);
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

    procedure MenuItem2Click(Sender: TObject);
    procedure MenuItem3Click(Sender: TObject);
    procedure MenuItem4Click(Sender: TObject);
    procedure MenuItem5Click(Sender: TObject);
    procedure RefrescarCombos;
    procedure ComboChange(Sender: TObject);
    procedure Chart1ColorMapSeries1Calculate(const AX, AY: Double; out AZ: Double);
    procedure FormDestroy(Sender: TObject);
  private
    FDibujar: Boolean;
    FPoints: TLineSeries;
    FTrend: TLineSeries;
    FHeatCols: array of TFloatArray;
    FHeatNCols, FHeatNRows: Integer;
    FHeatMin, FHeatMax: Real;

    FEntrenamiento: TConjuntoDatos;
    FPrueba: TConjuntoDatos;
    FK: Integer;

    FAtributosUsados: TIntArray;
    FAtributosRelevantes: TIntArray;

    FResultadosTodos: array of TResultadoKNN;
    FResultadosRelevantes: array of TResultadoKNN;

    FExactitudTodos: Double;
    FExactitudRelevantes: Double;
    FTieneExactitudTodos: Boolean;
    FTieneExactitudRelevantes: Boolean;

    procedure ActualizarInfo;
    procedure LimpiarClasificador;
    procedure LimpiarValidacionCruzada;
    procedure GuardarResultados(const Ruta: string);
    function ExactitudLOO(const Atributos: array of Integer; K: Integer): Double;
    function ValidacionCruzadaKFold(Pliegues, K: Integer;
      var Res: TResultadoCV): Boolean;
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

function AgruparAtributo(const T: TConjuntoDatos; Col, Bins: Integer;
  out NumGrupos: Integer): TIntArray;
var
  i, b, idx, nValores: Integer;
  MinV, MaxV, Rango, Valor: Double;
  Valores: TDoubleArray;
begin
  Result := nil;
  NumGrupos := 0;
  SetLength(Result, 0);
  if (T = nil) or (T.Filas = 0) or (Bins < 1) then
    Exit;

  // Atributo nominal: cada valor distinto es un grupo. No se interpreta el
  // codigo como numero ni se discretiza por rango.
  if T.Info[Col].Tipo = taNominal then
  begin
    SetLength(Valores, 0);
    SetLength(Result, T.Filas);
    nValores := 0;

    for i := 0 to T.Filas - 1 do
    begin
      Valor := T.Datos[i][Col];

      idx := -1;
      for b := 0 to nValores - 1 do
        if (Valores[b] = Valor) or
           (IsNan(Valores[b]) and IsNan(Valor)) then
        begin
          idx := b;
          Break;
        end;

      if idx < 0 then
      begin
        idx := nValores;
        SetLength(Valores, nValores + 1);
        Valores[nValores] := Valor;
        Inc(nValores);
      end;

      Result[i] := idx;
    end;

    NumGrupos := nValores;
    Exit;
  end;

  // Atributo numerico: bins de igual ancho.
  MinV := T.Datos[0][Col];
  MaxV := MinV;
  for i := 1 to T.Filas - 1 do
  begin
    if T.Datos[i][Col] < MinV then
      MinV := T.Datos[i][Col];

    if T.Datos[i][Col] > MaxV then
      MaxV := T.Datos[i][Col];
  end;

  Rango := MaxV - MinV;
  SetLength(Result, T.Filas);

  for i := 0 to T.Filas - 1 do
  begin
    if Rango <= 0 then
      b := 0
    else
      b := Trunc((T.Datos[i][Col] - MinV) / Rango * Bins);

    if b < 0 then b := 0;
    if b > Bins - 1 then b := Bins - 1;
    Result[i] := b;
  end;

  NumGrupos := Bins;
end;

function Entropia(const Conteo: array of Integer; N: Integer): Double;
var
  i: Integer;
  p: Double;
begin
  Result := 0;
  if N <= 0 then
    Exit;

  for i := 0 to High(Conteo) do
    if Conteo[i] > 0 then
    begin
      p := Conteo[i] / N;
      Result := Result - p * Log2(p);
    end;
end;

function GananciaInfo(const T: TConjuntoDatos; Col, Bins: Integer): Double;
var
  Disc: TIntArray;
  ConteoClase, ConteoClaseVal, ConteoVal: TIntArray;
  i, v, c, N, NumGrupos: Integer;
  H, HCond: Double;
begin
  Result := 0;
  if (T = nil) or (T.Filas = 0) or (T.ClasesEsperadas <= 0) then
    Exit;

  N := T.Filas;

  SetLength(ConteoClase, T.ClasesEsperadas);
  for i := 0 to N - 1 do
  begin
    c := T.Clases[i];
    if (c >= 0) and (c <= High(ConteoClase)) then
      Inc(ConteoClase[c]);
  end;
  H := Entropia(ConteoClase, N);

  Disc := AgruparAtributo(T, Col, Bins, NumGrupos);
  if (Length(Disc) <> N) or (NumGrupos <= 0) then
    Exit;

  SetLength(ConteoVal, NumGrupos);
  for i := 0 to N - 1 do
    Inc(ConteoVal[Disc[i]]);

  HCond := 0;
  SetLength(ConteoClaseVal, T.ClasesEsperadas);

  for v := 0 to NumGrupos - 1 do
  begin
    if ConteoVal[v] = 0 then
      Continue;

    for c := 0 to High(ConteoClaseVal) do
      ConteoClaseVal[c] := 0;

    for i := 0 to N - 1 do
      if Disc[i] = v then
      begin
        c := T.Clases[i];
        if (c >= 0) and (c <= High(ConteoClaseVal)) then
          Inc(ConteoClaseVal[c]);
      end;

    HCond := HCond + (ConteoVal[v] / N) *
      Entropia(ConteoClaseVal, ConteoVal[v]);
  end;

  Result := H - HCond;
  if Result < 0 then
    Result := 0;
end;



procedure TForm1.Button7Click(Sender: TObject);
const
  Bins = 10;
var
  IG: TDoubleArray;
  Orden: TIntArray;
  i, j, tmpI, NRel, CorteIdx: Integer;
  Salto, MayorSalto, Umbral: Double;
  Texto: string;
begin
  if (FEntrenamiento = nil) or (FEntrenamiento.Filas = 0) then
  begin
    ShowMessage('Primero carga el entrenamiento (T).');
    Exit;
  end;

  SetLength(IG, FEntrenamiento.Columnas);
  SetLength(Orden, FEntrenamiento.Columnas);

  for j := 0 to FEntrenamiento.Columnas - 1 do
  begin
    IG[j] := GananciaInfo(FEntrenamiento, j, Bins);
    Orden[j] := j;
  end;

  // ordena atributos de mayor a menor ganancia
  for i := 0 to High(Orden) - 1 do
    for j := 0 to High(Orden) - 1 - i do
      if IG[Orden[j]] < IG[Orden[j + 1]] then
      begin
        tmpI := Orden[j];
        Orden[j] := Orden[j + 1];
        Orden[j + 1] := tmpI;
      end;

  // busca la mayor diferencia entre dos atributos del top
  CorteIdx := High(Orden);
  MayorSalto := -1;
  for i := 0 to High(Orden) - 1 do
  begin
    Salto := IG[Orden[i]] - IG[Orden[i + 1]];
    if Salto > MayorSalto then
    begin
      MayorSalto := Salto;
      CorteIdx := i;
    end;
  end;
  Umbral := IG[Orden[CorteIdx]];

  SetLength(FAtributosRelevantes, 0);
  Memo1.Lines.Add('=== RANKING DE ATRIBUTOS (Ganancia de Información) ===');
  Memo1.Lines.Add(Format(
    'Agrupamiento: nominales por categoría exacta, numéricos en %d bins.',
    [Bins]));

  for i := 0 to High(Orden) do
  begin
    j := Orden[i];
    if i <= CorteIdx then
    begin
      SetLength(FAtributosRelevantes, Length(FAtributosRelevantes) + 1);
      FAtributosRelevantes[High(FAtributosRelevantes)] := j;
      Memo1.Lines.Add(Format('At.%d   IG = %.4f   (relevante)', [j + 1, IG[j]]));
    end
    else
      Memo1.Lines.Add(Format('At.%d   IG = %.4f   (descartado)', [j + 1, IG[j]]));
  end;

  // ordena el subconjunto por índice de columna
  for i := 0 to High(FAtributosRelevantes) - 1 do
    for j := 0 to High(FAtributosRelevantes) - 1 - i do
      if FAtributosRelevantes[j] > FAtributosRelevantes[j + 1] then
      begin
        tmpI := FAtributosRelevantes[j];
        FAtributosRelevantes[j] := FAtributosRelevantes[j + 1];
        FAtributosRelevantes[j + 1] := tmpI;
      end;

  NRel := Length(FAtributosRelevantes);
  Texto := '';
  for i := 0 to NRel - 1 do
  begin
    if i > 0 then
      Texto := Texto + ', ';
    Texto := Texto + IntToStr(FAtributosRelevantes[i] + 1);
  end;

  Label13.Caption := 'Atributos usados: ' + Texto;
  Memo1.Lines.Add(Format('Corte en IG >= %.4f -> %d de %d atributos: [%s]',
    [Umbral, NRel, FEntrenamiento.Columnas, Texto]));
end;

procedure ObtenerVecinos(const T, P: TConjuntoDatos; FilaP, K, ExcluirFila: Integer;
  const Atributos: array of Integer; var Vecinos: TVecinoArray);
var
  i, j: Integer;
  Dist: Double;
  Tmp: TVecino;
begin
  SetLength(Vecinos, 0);

  for i := 0 to T.Filas - 1 do
  begin
    if i = ExcluirFila then
      Continue;

    Dist := DistanciaEntre(T, i, P, FilaP, Atributos);

    if Length(Vecinos) < K then
    begin
      SetLength(Vecinos, Length(Vecinos) + 1);
      Vecinos[High(Vecinos)].Indice := i;
      Vecinos[High(Vecinos)].Distancia := Dist;
    end
    else if Dist < Vecinos[High(Vecinos)].Distancia then
    begin
      Vecinos[High(Vecinos)].Indice := i;
      Vecinos[High(Vecinos)].Distancia := Dist;
    end
    else
      Continue;

    // Orden ascendente: primero los vecinos mas cercanos.
    j := High(Vecinos);
    while (j > 0) and (Vecinos[j].Distancia < Vecinos[j - 1].Distancia) do
    begin
      Tmp := Vecinos[j];
      Vecinos[j] := Vecinos[j - 1];
      Vecinos[j - 1] := Tmp;
      Dec(j);
    end;
  end;
end;

{ Igual que ObtenerVecinos, pero solo considera las filas marcadas como
  entrenamiento (EsEntrenamiento[i] = True). Se usa en validación cruzada. }
procedure ObtenerVecinosSubconjunto(const T: TConjuntoDatos; FilaConsulta, K: Integer;
  const EsEntrenamiento: array of Boolean; const Atributos: array of Integer;
  var Vecinos: TVecinoArray);
var
  i, j: Integer;
  Dist: Double;
  Tmp: TVecino;
begin
  SetLength(Vecinos, 0);
  if (T = nil) or (K < 1) or (Length(EsEntrenamiento) < T.Filas) then
    Exit;

  for i := 0 to T.Filas - 1 do
  begin
    if not EsEntrenamiento[i] then
      Continue;

    Dist := DistanciaEntre(T, i, T, FilaConsulta, Atributos);

    if Length(Vecinos) < K then
    begin
      SetLength(Vecinos, Length(Vecinos) + 1);
      Vecinos[High(Vecinos)].Indice := i;
      Vecinos[High(Vecinos)].Distancia := Dist;
    end
    else if Dist < Vecinos[High(Vecinos)].Distancia then
    begin
      Vecinos[High(Vecinos)].Indice := i;
      Vecinos[High(Vecinos)].Distancia := Dist;
    end
    else
      Continue;

    // Orden ascendente: primero los vecinos mas cercanos.
    j := High(Vecinos);
    while (j > 0) and (Vecinos[j].Distancia < Vecinos[j - 1].Distancia) do
    begin
      Tmp := Vecinos[j];
      Vecinos[j] := Vecinos[j - 1];
      Vecinos[j - 1] := Tmp;
      Dec(j);
    end;
  end;
end;

function Predecir(const T: TConjuntoDatos;
  const Vecinos: array of TVecino; Ponderado: Boolean): Integer;
var
  i, c: Integer;
  Pesos: array of Double;
  Mejor: Double;
begin
  SetLength(Pesos, T.ClasesEsperadas);
  if Length(Pesos) = 0 then
  begin
    Result := 0;
    Exit;
  end;

  for i := 0 to High(Vecinos) do
  begin
    c := T.Clases[Vecinos[i].Indice];
    if (c < 0) or (c > High(Pesos)) then
      Continue;
    if Ponderado then
      // Peso decreciente con la distancia (1/(1+d)); valido aunque d > 1.
      Pesos[c] := Pesos[c] + 1.0 / (1.0 + Vecinos[i].Distancia)
    else
      Pesos[c] := Pesos[c] + 1.0;
  end;

  Result := 0;
  Mejor := Pesos[0];
  for c := 1 to High(Pesos) do
    if Pesos[c] > Mejor then
    begin
      Mejor := Pesos[c];
      Result := c;
    end;
end;

function TForm1.ExactitudLOO(const Atributos: array of Integer;
  K: Integer): Double;
var
  i, Aciertos: Integer;
  Vecinos: TVecinoArray;
  Pred: Integer;
  Ponderado: Boolean;
begin
  Result := 0;
  if (FEntrenamiento = nil) or (FEntrenamiento.Filas = 0) or
     (Length(Atributos) = 0) then
    Exit;

  if K > FEntrenamiento.Filas - 1 then
    K := FEntrenamiento.Filas - 1;
  if K < 1 then
    Exit;

  Ponderado := ComboBox3.ItemIndex = 1;
  Aciertos := 0;

  for i := 0 to FEntrenamiento.Filas - 1 do
  begin
    ObtenerVecinos(FEntrenamiento, FEntrenamiento, i, K, i,
      Atributos, Vecinos);
    Pred := Predecir(FEntrenamiento, Vecinos, Ponderado);
    if Pred = FEntrenamiento.Clases[i] then
      Inc(Aciertos);
  end;

  Result := Aciertos / FEntrenamiento.Filas;
end;

procedure TForm1.Button8Click(Sender: TObject);
var
  K, i, j, Pred, ClaseReal, Aciertos: Integer;
  Attrs: TIntArray;
  Vecinos: TVecinoArray;
  LineaInd, LineaSim, Coincide, Signo: string;
  AccLOO, Dif: Double;
begin
  if (FEntrenamiento = nil) or (FEntrenamiento.Filas = 0) then
  begin
    ShowMessage('Primero carga el entrenamiento (T).');
    Exit;
  end;

  if (FPrueba = nil) or (FPrueba.Filas = 0) then
  begin
    ShowMessage('Primero carga el conjunto de prueba (P).');
    Exit;
  end;

  if not TryStrToInt(Trim(Edit3.Text), K) then
  begin
    ShowMessage('k debe ser un número entero.');
    Edit3.SetFocus;
    Exit;
  end;

  if (K < 1) or (K > FEntrenamiento.Filas - 1) then
  begin
    ShowMessage(Format('k debe estar entre 1 y %d.',
      [FEntrenamiento.Filas - 1]));
    Edit3.SetFocus;
    Exit;
  end;

  FK := K;

  SetLength(Attrs, FEntrenamiento.Columnas);
  for j := 0 to High(Attrs) do
    Attrs[j] := j;
  FAtributosUsados := Copy(Attrs, 0, Length(Attrs));

  SetLength(FResultadosTodos, FPrueba.Filas);

  StringGrid3.RowCount := FPrueba.Filas + 1;
  StringGrid3.Cells[0, 0] := '#P';
  StringGrid3.Cells[1, 0] := 'Clase Real';
  StringGrid3.Cells[2, 0] := 'Clase Predicha';
  StringGrid3.Cells[3, 0] := 'Coinciden';
  StringGrid3.Cells[4, 0] := 'Vecinos / similitud';

  Aciertos := 0;

  for i := 0 to FPrueba.Filas - 1 do
  begin
    ObtenerVecinos(FEntrenamiento, FPrueba, i, K, -1, Attrs, Vecinos);
    Pred := Predecir(FEntrenamiento, Vecinos, ComboBox3.ItemIndex = 1);

    FResultadosTodos[i].Clase := Pred;
    FResultadosTodos[i].Vecinos := Copy(Vecinos, 0, Length(Vecinos));

    ClaseReal := FPrueba.Clases[i];
    if Pred = ClaseReal then
    begin
      Inc(Aciertos);
      Coincide := 'Sí';
    end
    else
      Coincide := 'No';

    LineaInd := '';
    LineaSim := '';
    for j := 0 to High(Vecinos) do
    begin
      if j > 0 then
      begin
        LineaInd := LineaInd + ',';
        LineaSim := LineaSim + ',';
      end;
      LineaInd := LineaInd + IntToStr(Vecinos[j].Indice + 1);
      LineaSim := LineaSim + FormatFloat('0.0000', Vecinos[j].Distancia);
    end;

    StringGrid3.Cells[0, i + 1] := IntToStr(i + 1);
    StringGrid3.Cells[1, i + 1] := IntToStr(ClaseReal);
    StringGrid3.Cells[2, i + 1] := IntToStr(Pred);
    StringGrid3.Cells[3, i + 1] := Coincide;
    StringGrid3.Cells[4, i + 1] := LineaInd + ' / ' + LineaSim;
  end;

  FExactitudTodos := Aciertos / FPrueba.Filas;
  FTieneExactitudTodos := True;
  AccLOO := ExactitudLOO(Attrs, K);

  Label18.Caption := Format(
    'Exactitud en P (todos): %.2f%% (%d/%d)   Error: %.2f%%   |   LOO en T: %.2f%%',
    [FExactitudTodos * 100, Aciertos, FPrueba.Filas,
     (1 - FExactitudTodos) * 100, AccLOO * 100]);

  if FTieneExactitudRelevantes then
  begin
    Dif := (FExactitudRelevantes - FExactitudTodos) * 100;
    if Dif >= 0 then Signo := '+' else Signo := '';
    Label20.Caption := Format('Diferencia en P (relevantes - todos): %s%.2f%%',
      [Signo, Dif]);
  end;

  Memo1.Lines.Add(Format(
    'Todos (%d atr., k=%d): Exactitud en P = %.2f%% (%d/%d), Error = %.2f%% | LOO en T = %.2f%%',
    [Length(Attrs), K, FExactitudTodos * 100, Aciertos, FPrueba.Filas,
     (1 - FExactitudTodos) * 100, AccLOO * 100]));
end;

procedure TForm1.Button9Click(Sender: TObject);
var
  K, i, j, Pred, ClaseReal, Aciertos: Integer;
  Vecinos: TVecinoArray;
  LineaInd, LineaSim, Coincide, Signo: string;
  AccLOO, Dif: Double;
begin
  if (FEntrenamiento = nil) or (FEntrenamiento.Filas = 0) then
  begin
    ShowMessage('Primero carga el entrenamiento (T).');
    Exit;
  end;

  if (FPrueba = nil) or (FPrueba.Filas = 0) then
  begin
    ShowMessage('Primero carga el conjunto de prueba (P).');
    Exit;
  end;

  if Length(FAtributosRelevantes) = 0 then
  begin
    ShowMessage('Primero presiona "Seleccionar Atributos Relevantes".');
    Exit;
  end;

  if not TryStrToInt(Trim(Edit3.Text), K) then
  begin
    ShowMessage('k debe ser un número entero.');
    Edit3.SetFocus;
    Exit;
  end;

  if (K < 1) or (K > FEntrenamiento.Filas - 1) then
  begin
    ShowMessage(Format('k debe estar entre 1 y %d.',
      [FEntrenamiento.Filas - 1]));
    Edit3.SetFocus;
    Exit;
  end;

  FK := K;
  FAtributosUsados := Copy(FAtributosRelevantes, 0, Length(FAtributosRelevantes));
  SetLength(FResultadosRelevantes, FPrueba.Filas);

  StringGrid3.RowCount := FPrueba.Filas + 1;
  StringGrid3.Cells[0, 0] := '#P';
  StringGrid3.Cells[1, 0] := 'Clase Real';
  StringGrid3.Cells[2, 0] := 'Clase predicha rel.';
  StringGrid3.Cells[3, 0] := 'Coinciden';
  StringGrid3.Cells[4, 0] := 'Vecinos / similitud';

  Aciertos := 0;

  for i := 0 to FPrueba.Filas - 1 do
  begin
    ObtenerVecinos(FEntrenamiento, FPrueba, i, K, -1,
      FAtributosRelevantes, Vecinos);
    Pred := Predecir(FEntrenamiento, Vecinos, ComboBox3.ItemIndex = 1);

    FResultadosRelevantes[i].Clase := Pred;
    FResultadosRelevantes[i].Vecinos := Copy(Vecinos, 0, Length(Vecinos));

    ClaseReal := FPrueba.Clases[i];
    if Pred = ClaseReal then
    begin
      Inc(Aciertos);
      Coincide := 'Sí';
    end
    else
      Coincide := 'No';

    LineaInd := '';
    LineaSim := '';
    for j := 0 to High(Vecinos) do
    begin
      if j > 0 then
      begin
        LineaInd := LineaInd + ',';
        LineaSim := LineaSim + ',';
      end;
      LineaInd := LineaInd + IntToStr(Vecinos[j].Indice + 1);
      LineaSim := LineaSim + FormatFloat('0.0000', Vecinos[j].Distancia);
    end;

    StringGrid3.Cells[0, i + 1] := IntToStr(i + 1);
    StringGrid3.Cells[1, i + 1] := IntToStr(ClaseReal);
    StringGrid3.Cells[2, i + 1] := IntToStr(Pred);
    StringGrid3.Cells[3, i + 1] := Coincide;
    StringGrid3.Cells[4, i + 1] := LineaInd + ' / ' + LineaSim;
  end;

  FExactitudRelevantes := Aciertos / FPrueba.Filas;
  FTieneExactitudRelevantes := True;
  AccLOO := ExactitudLOO(FAtributosRelevantes, K);

  Label19.Caption := Format(
    'Exactitud en P (relevantes): %.2f%% (%d/%d)   Error: %.2f%%   |   LOO en T: %.2f%%',
    [FExactitudRelevantes * 100, Aciertos, FPrueba.Filas,
     (1 - FExactitudRelevantes) * 100, AccLOO * 100]);

  if FTieneExactitudTodos then
  begin
    Dif := (FExactitudRelevantes - FExactitudTodos) * 100;
    if Dif >= 0 then Signo := '+' else Signo := '';
    Label20.Caption := Format('Diferencia en P (relevantes - todos): %s%.2f%%',
      [Signo, Dif]);
  end
  else
    Label20.Caption := 'Diferencia: (falta clasificar con todos)';

  Memo1.Lines.Add(Format(
    'Relevantes (%d atr., k=%d): Exactitud en P = %.2f%% (%d/%d), Error = %.2f%% | LOO en T = %.2f%%',
    [Length(FAtributosRelevantes), K, FExactitudRelevantes * 100,
     Aciertos, FPrueba.Filas, (1 - FExactitudRelevantes) * 100, AccLOO * 100]));
end;

procedure TForm1.Button10Click(Sender: TObject);
var
  K, i, j, PredT, PredR, ClaseReal, AcTodos, AcRel: Integer;
  Attrs: TIntArray;
  VecT, VecR: TVecinoArray;
  LineaInd, LineaSim, OkT, OkR, SignoP, SignoLOO: string;
  LOOTodos, LOORel, DifP, DifLOO: Double;
begin
  if (FEntrenamiento = nil) or (FEntrenamiento.Filas = 0) then
  begin
    ShowMessage('Primero carga el entrenamiento (T).');
    Exit;
  end;

  if (FPrueba = nil) or (FPrueba.Filas = 0) then
  begin
    ShowMessage('Primero carga el conjunto de prueba (P).');
    Exit;
  end;

  if Length(FAtributosRelevantes) = 0 then
    Button7Click(nil);

  if not TryStrToInt(Trim(Edit3.Text), K) then
  begin
    ShowMessage('k debe ser un número entero.');
    Edit3.SetFocus;
    Exit;
  end;

  if (K < 1) or (K > FEntrenamiento.Filas - 1) then
  begin
    ShowMessage(Format('k debe estar entre 1 y %d.',
      [FEntrenamiento.Filas - 1]));
    Edit3.SetFocus;
    Exit;
  end;

  FK := K;

  SetLength(Attrs, FEntrenamiento.Columnas);
  for j := 0 to High(Attrs) do
    Attrs[j] := j;

  SetLength(FResultadosTodos, FPrueba.Filas);
  SetLength(FResultadosRelevantes, FPrueba.Filas);

  StringGrid3.RowCount := FPrueba.Filas + 1;
  StringGrid3.Cells[0, 0] := '#P (Real)';
  StringGrid3.Cells[1, 0] := 'Clase Predicha';
  StringGrid3.Cells[2, 0] := 'Clase predicha rel.';
  StringGrid3.Cells[3, 0] := 'Coinciden (T/R vs Real)';
  StringGrid3.Cells[4, 0] := 'Vecinos rel. / similitud';

  AcTodos := 0;
  AcRel := 0;

  for i := 0 to FPrueba.Filas - 1 do
  begin
    ClaseReal := FPrueba.Clases[i];

    ObtenerVecinos(FEntrenamiento, FPrueba, i, K, -1, Attrs, VecT);
    PredT := Predecir(FEntrenamiento, VecT, ComboBox3.ItemIndex = 1);
    FResultadosTodos[i].Clase := PredT;
    FResultadosTodos[i].Vecinos := Copy(VecT, 0, Length(VecT));

    ObtenerVecinos(FEntrenamiento, FPrueba, i, K, -1,
      FAtributosRelevantes, VecR);
    PredR := Predecir(FEntrenamiento, VecR, ComboBox3.ItemIndex = 1);
    FResultadosRelevantes[i].Clase := PredR;
    FResultadosRelevantes[i].Vecinos := Copy(VecR, 0, Length(VecR));

    if PredT = ClaseReal then
    begin
      Inc(AcTodos);
      OkT := 'Sí';
    end
    else
      OkT := 'No';

    if PredR = ClaseReal then
    begin
      Inc(AcRel);
      OkR := 'Sí';
    end
    else
      OkR := 'No';

    LineaInd := '';
    LineaSim := '';
    for j := 0 to High(VecR) do
    begin
      if j > 0 then
      begin
        LineaInd := LineaInd + ',';
        LineaSim := LineaSim + ',';
      end;
      LineaInd := LineaInd + IntToStr(VecR[j].Indice + 1);
      LineaSim := LineaSim + FormatFloat('0.0000', VecR[j].Distancia);
    end;

    StringGrid3.Cells[0, i + 1] := Format('%d (c=%d)', [i + 1, ClaseReal]);
    StringGrid3.Cells[1, i + 1] := IntToStr(PredT);
    StringGrid3.Cells[2, i + 1] := IntToStr(PredR);
    StringGrid3.Cells[3, i + 1] := OkT + ' / ' + OkR;
    StringGrid3.Cells[4, i + 1] := LineaInd + ' / ' + LineaSim;
  end;

  FExactitudTodos := AcTodos / FPrueba.Filas;
  FExactitudRelevantes := AcRel / FPrueba.Filas;
  FTieneExactitudTodos := True;
  FTieneExactitudRelevantes := True;

  LOOTodos := ExactitudLOO(Attrs, K);
  LOORel := ExactitudLOO(FAtributosRelevantes, K);

  DifP := (FExactitudRelevantes - FExactitudTodos) * 100;
  DifLOO := (LOORel - LOOTodos) * 100;
  if DifP >= 0 then SignoP := '+' else SignoP := '';
  if DifLOO >= 0 then SignoLOO := '+' else SignoLOO := '';

  Label18.Caption := Format(
    'Exactitud en P (todos): %.2f%% (%d/%d)   Error: %.2f%%   |   LOO en T: %.2f%%',
    [FExactitudTodos * 100, AcTodos, FPrueba.Filas,
     (1 - FExactitudTodos) * 100, LOOTodos * 100]);

  Label19.Caption := Format(
    'Exactitud en P (relevantes): %.2f%% (%d/%d)   Error: %.2f%%   |   LOO en T: %.2f%%',
    [FExactitudRelevantes * 100, AcRel, FPrueba.Filas,
     (1 - FExactitudRelevantes) * 100, LOORel * 100]);

  Label20.Caption := Format(
    'Mejora con relevantes -> en P: %s%.2f%%   |   en T (LOO): %s%.2f%%',
    [SignoP, DifP, SignoLOO, DifLOO]);

  Memo1.Lines.Add(Format(
    '=== COMPARACIÓN (k=%d) === P: todos %.2f%% vs rel. %.2f%% (%s%.2f%%) | T(LOO): %.2f%% vs %.2f%% (%s%.2f%%)',
    [K, FExactitudTodos * 100, FExactitudRelevantes * 100, SignoP, DifP,
     LOOTodos * 100, LOORel * 100, SignoLOO, DifLOO]));
end;

function TForm1.ValidacionCruzadaKFold(Pliegues, K: Integer;
  var Res: TResultadoCV): Boolean;
var
  N, i, j, c, f, MaxClase, Offset, tmp, nTest, maxTest: Integer;
  FoldDe, TamPliegue, Cont, Orden, Attrs: TIntArray;
  PorClase: array of TIntArray;
  EsTrain: array of Boolean;
  Vecinos: TVecinoArray;
  Pred: Integer;
  Ponderado, HayRel, HayVacio: Boolean;
  SumT, SumSqT, SumR, SumSqR, AccT, AccR: Double;
begin
  Result := False;
  Res.Pliegues := 0;
  Res.TamPliegue := nil;
  Res.AcTodos := nil;
  Res.AcRel := nil;
  Res.AcTotalTodos := 0;
  Res.AcTotalRel := 0;
  Res.PromedioTodos := 0;
  Res.DesvTodos := 0;
  Res.GlobalTodos := 0;
  Res.PromedioRel := 0;
  Res.DesvRel := 0;
  Res.GlobalRel := 0;

  if (FEntrenamiento = nil) or (FEntrenamiento.Filas = 0) then
    Exit;

  N := FEntrenamiento.Filas;
  if (Pliegues < 2) or (Pliegues > N) then
    Exit;

  HayRel := Length(FAtributosRelevantes) > 0;
  Ponderado := ComboBox3.ItemIndex = 1;

  // Agrupa los índices de T por clase.
  MaxClase := -1;
  for i := 0 to N - 1 do
    if FEntrenamiento.Clases[i] > MaxClase then
      MaxClase := FEntrenamiento.Clases[i];

  SetLength(PorClase, MaxClase + 1);
  SetLength(Cont, MaxClase + 1);
  for i := 0 to N - 1 do
  begin
    c := FEntrenamiento.Clases[i];
    if (c >= 0) and (c <= MaxClase) then
      Inc(Cont[c]);
  end;

  for c := 0 to MaxClase do
    SetLength(PorClase[c], Cont[c]);
  for c := 0 to MaxClase do
    Cont[c] := 0;

  for i := 0 to N - 1 do
  begin
    c := FEntrenamiento.Clases[i];
    if (c >= 0) and (c <= MaxClase) then
    begin
      PorClase[c][Cont[c]] := i;
      Inc(Cont[c]);
    end;
  end;

  // Barajado reproducible dentro de cada clase.
  RandSeed := 20261116;
  for c := 0 to MaxClase do
    for i := High(PorClase[c]) downto 1 do
    begin
      j := Random(i + 1);
      tmp := PorClase[c][i];
      PorClase[c][i] := PorClase[c][j];
      PorClase[c][j] := tmp;
    end;

  // Reparte cada clase por turnos entre los pliegues (estratificado).
  SetLength(FoldDe, N);
  for i := 0 to N - 1 do
    FoldDe[i] := 0;

  Offset := 0;
  for c := 0 to MaxClase do
  begin
    for i := 0 to High(PorClase[c]) do
      FoldDe[PorClase[c][i]] := (Offset + i) mod Pliegues;
    Offset := (Offset + Length(PorClase[c])) mod Pliegues;
  end;

  SetLength(TamPliegue, Pliegues);
  for f := 0 to Pliegues - 1 do
    TamPliegue[f] := 0;
  for i := 0 to N - 1 do
    Inc(TamPliegue[FoldDe[i]]);

  // Si alguna distribución dejara un pliegue vacío, reparte al azar.
  HayVacio := False;
  for f := 0 to Pliegues - 1 do
    if TamPliegue[f] = 0 then
      HayVacio := True;

  if HayVacio then
  begin
    SetLength(Orden, N);
    for i := 0 to N - 1 do
      Orden[i] := i;
    for i := N - 1 downto 1 do
    begin
      j := Random(i + 1);
      tmp := Orden[i];
      Orden[i] := Orden[j];
      Orden[j] := tmp;
    end;

    for f := 0 to Pliegues - 1 do
      TamPliegue[f] := 0;
    for i := 0 to N - 1 do
    begin
      FoldDe[Orden[i]] := i mod Pliegues;
      Inc(TamPliegue[i mod Pliegues]);
    end;
  end;

  maxTest := 0;
  for f := 0 to Pliegues - 1 do
    if TamPliegue[f] > maxTest then
      maxTest := TamPliegue[f];

  // k no puede superar el tamaño del entrenamiento más pequeño.
  if K > N - maxTest then
    K := N - maxTest;
  if K < 1 then
    Exit;

  SetLength(Res.TamPliegue, Pliegues);
  SetLength(Res.AcTodos, Pliegues);
  SetLength(Res.AcRel, Pliegues);
  for f := 0 to Pliegues - 1 do
  begin
    Res.TamPliegue[f] := TamPliegue[f];
    Res.AcTodos[f] := 0;
    Res.AcRel[f] := 0;
  end;
  Res.Pliegues := Pliegues;

  SetLength(Attrs, FEntrenamiento.Columnas);
  for i := 0 to High(Attrs) do
    Attrs[i] := i;

  SetLength(EsTrain, N);

  SumT := 0;
  SumSqT := 0;
  SumR := 0;
  SumSqR := 0;

  for f := 0 to Pliegues - 1 do
  begin
    nTest := TamPliegue[f];

    for i := 0 to N - 1 do
      EsTrain[i] := FoldDe[i] <> f;

    for i := 0 to N - 1 do
    begin
      if FoldDe[i] <> f then
        Continue;

      ObtenerVecinosSubconjunto(FEntrenamiento, i, K, EsTrain, Attrs, Vecinos);
      Pred := Predecir(FEntrenamiento, Vecinos, Ponderado);
      if Pred = FEntrenamiento.Clases[i] then
        Inc(Res.AcTodos[f]);

      if HayRel then
      begin
        ObtenerVecinosSubconjunto(FEntrenamiento, i, K, EsTrain,
          FAtributosRelevantes, Vecinos);
        Pred := Predecir(FEntrenamiento, Vecinos, Ponderado);
        if Pred = FEntrenamiento.Clases[i] then
          Inc(Res.AcRel[f]);
      end;
    end;

    Inc(Res.AcTotalTodos, Res.AcTodos[f]);
    Inc(Res.AcTotalRel, Res.AcRel[f]);

    AccT := Res.AcTodos[f] / nTest;
    SumT := SumT + AccT;
    SumSqT := SumSqT + Sqr(AccT);

    if HayRel then
    begin
      AccR := Res.AcRel[f] / nTest;
      SumR := SumR + AccR;
      SumSqR := SumSqR + Sqr(AccR);
    end;
  end;

  Res.PromedioTodos := SumT / Pliegues;
  Res.DesvTodos := SumSqT / Pliegues - Sqr(Res.PromedioTodos);
  if Res.DesvTodos < 0 then
    Res.DesvTodos := 0;
  Res.DesvTodos := Sqrt(Res.DesvTodos);
  Res.GlobalTodos := Res.AcTotalTodos / N;

  if HayRel then
  begin
    Res.PromedioRel := SumR / Pliegues;
    Res.DesvRel := SumSqR / Pliegues - Sqr(Res.PromedioRel);
    if Res.DesvRel < 0 then
      Res.DesvRel := 0;
    Res.DesvRel := Sqrt(Res.DesvRel);
    Res.GlobalRel := Res.AcTotalRel / N;
  end;

  Result := True;
end;

procedure TForm1.Button11Click(Sender: TObject);
var
  Pliegues, K, f, NTest, MaxK, AcT, AcR: Integer;
  Res: TResultadoCV;
  AccT, AccR: Double;
  HayRel: Boolean;
  Voto, Signo: string;
begin
  if (FEntrenamiento = nil) or (FEntrenamiento.Filas = 0) then
  begin
    ShowMessage('Primero carga el entrenamiento (T).');
    Exit;
  end;

  if not TryStrToInt(Trim(Edit4.Text), Pliegues) then
  begin
    ShowMessage('El número de pliegues debe ser un número entero.');
    Edit4.SetFocus;
    Exit;
  end;

  if (Pliegues < 2) or (Pliegues > FEntrenamiento.Filas) then
  begin
    ShowMessage(Format('El número de pliegues debe estar entre 2 y %d.',
      [FEntrenamiento.Filas]));
    Edit4.SetFocus;
    Exit;
  end;

  if not TryStrToInt(Trim(Edit3.Text), K) then
  begin
    ShowMessage('k debe ser un número entero.');
    Edit3.SetFocus;
    Exit;
  end;

  MaxK := FEntrenamiento.Filas -
    ((FEntrenamiento.Filas + Pliegues - 1) div Pliegues);
  if (K < 1) or (K > MaxK) then
  begin
    ShowMessage(Format('k debe estar entre 1 y %d para %d pliegues.',
      [MaxK, Pliegues]));
    Edit3.SetFocus;
    Exit;
  end;

  if Length(FAtributosRelevantes) = 0 then
    Button7Click(nil);
  HayRel := Length(FAtributosRelevantes) > 0;

  LimpiarValidacionCruzada;

  if not ValidacionCruzadaKFold(Pliegues, K, Res) then
  begin
    ShowMessage('No se pudo ejecutar la validación cruzada.');
    Exit;
  end;

  StringGrid4.RowCount := Pliegues + 1;

  for f := 0 to Pliegues - 1 do
  begin
    NTest := Res.TamPliegue[f];
    AcT := Res.AcTodos[f];
    AccT := AcT / NTest;

    StringGrid4.Cells[0, f + 1] := IntToStr(f + 1);
    StringGrid4.Cells[1, f + 1] := IntToStr(FEntrenamiento.Filas - NTest);
    StringGrid4.Cells[2, f + 1] := IntToStr(NTest);

    if HayRel then
    begin
      AcR := Res.AcRel[f];
      AccR := AcR / NTest;

      StringGrid4.Cells[3, f + 1] := Format('%d/%d|%d/%d',
        [AcT, NTest, AcR, NTest]);
      StringGrid4.Cells[4, f + 1] := Format('%.2f|%.2f',
        [AccT * 100, AccR * 100]);
      StringGrid4.Cells[5, f + 1] := Format('%.2f|%.2f',
        [(1 - AccT) * 100, (1 - AccR) * 100]);
    end
    else
    begin
      StringGrid4.Cells[3, f + 1] := Format('%d/%d', [AcT, NTest]);
      StringGrid4.Cells[4, f + 1] := Format('%.2f', [AccT * 100]);
      StringGrid4.Cells[5, f + 1] := Format('%.2f', [(1 - AccT) * 100]);
    end;
  end;

  Label26.Caption := 'Promedio exactitud (todos): ' +
    FormatFloat('0.00', Res.PromedioTodos * 100) + ' %';
  Label27.Caption := 'Desviacion estándar (todos): ' +
    FormatFloat('0.00', Res.DesvTodos * 100) + ' %';

  if HayRel then
  begin
    Label23.Caption := 'Promedio exactitud (relevantes): ' +
      FormatFloat('0.00', Res.PromedioRel * 100) + ' %';
    Label28.Caption := 'Desviación estándar (relevantes): ' +
      FormatFloat('0.00', Res.DesvRel * 100) + ' %';
  end;

  Voto := 'voto por mayoría simple';
  if ComboBox3.ItemIndex = 1 then
    Voto := 'voto ponderado por similitud';

  Memo1.Lines.Add('');
  Memo1.Lines.Add(Format('=== VALIDACIÓN CRUZADA %d-FOLD (kNN k=%d, %s) ===',
    [Pliegues, K, Voto]));
  if HayRel then
    Memo1.Lines.Add('Formato de la tabla: todos | relevantes.');

  for f := 0 to Pliegues - 1 do
  begin
    NTest := Res.TamPliegue[f];
    AccT := Res.AcTodos[f] / NTest;

    if HayRel then
    begin
      AccR := Res.AcRel[f] / NTest;
      Memo1.Lines.Add(Format(
        'Pliegue %2d: test=%d, train=%d | todos %d/%d = %.2f%% | relev. %d/%d = %.2f%%',
        [f + 1, NTest, FEntrenamiento.Filas - NTest,
         Res.AcTodos[f], NTest, AccT * 100,
         Res.AcRel[f], NTest, AccR * 100]));
    end
    else
      Memo1.Lines.Add(Format(
        'Pliegue %2d: test=%d, train=%d | todos %d/%d = %.2f%%',
        [f + 1, NTest, FEntrenamiento.Filas - NTest,
         Res.AcTodos[f], NTest, AccT * 100]));
  end;

  if HayRel then
  begin
    Signo := '';
    if Res.PromedioRel >= Res.PromedioTodos then
      Signo := '+';

    Memo1.Lines.Add(Format(
      'Promedio todos: %.2f%% (DE %.2f%%, global %d/%d = %.2f%%) | ' +
      'Promedio relevantes: %.2f%% (DE %.2f%%, global %d/%d = %.2f%%) | Dif. %s%.2f%%',
      [Res.PromedioTodos * 100, Res.DesvTodos * 100,
       Res.AcTotalTodos, FEntrenamiento.Filas, Res.GlobalTodos * 100,
       Res.PromedioRel * 100, Res.DesvRel * 100,
       Res.AcTotalRel, FEntrenamiento.Filas, Res.GlobalRel * 100,
       Signo, (Res.PromedioRel - Res.PromedioTodos) * 100]));
  end
  else
    Memo1.Lines.Add(Format(
      'Promedio todos: %.2f%% (DE %.2f%%, global %d/%d = %.2f%%)',
      [Res.PromedioTodos * 100, Res.DesvTodos * 100,
       Res.AcTotalTodos, FEntrenamiento.Filas, Res.GlobalTodos * 100]));
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

procedure TForm1.LimpiarClasificador;
begin
  SetLength(FResultadosTodos, 0);
  SetLength(FResultadosRelevantes, 0);
  FExactitudTodos := 0;
  FExactitudRelevantes := 0;
  FTieneExactitudTodos := False;
  FTieneExactitudRelevantes := False;

  StringGrid3.RowCount := 1;
  Label18.Caption := 'Exactitud en P (todos): —';
  Label19.Caption := 'Exactitud en P (relevantes): —';
  Label20.Caption := 'Diferencia: —';

  LimpiarValidacionCruzada;
end;

procedure TForm1.LimpiarValidacionCruzada;
begin
  StringGrid4.RowCount := 1;
end;

procedure TForm1.GuardarResultados(const Ruta: string);
var
  Salida: TStringList;
  Usar: array of TResultadoKNN;
  i, j: Integer;
  LineaInd, LineaSim: string;
  Fmt: TFormatSettings;
begin
  if Length(FResultadosRelevantes) > 0 then
    Usar := FResultadosRelevantes
  else if Length(FResultadosTodos) > 0 then
    Usar := FResultadosTodos
  else
  begin
    ShowMessage('Primero ejecuta una clasificación sobre P.');
    Exit;
  end;

  // El archivo de salida siempre usa punto decimal, sin importar la locale.
  Fmt := DefaultFormatSettings;
  Fmt.DecimalSeparator := '.';
  Fmt.ThousandSeparator := #0;

  Salida := TStringList.Create;
  try
    for i := 0 to High(Usar) do
    begin
      LineaInd := '';
      LineaSim := '';
      for j := 0 to High(Usar[i].Vecinos) do
      begin
        if j > 0 then
        begin
          LineaInd := LineaInd + ',';
          LineaSim := LineaSim + ',';
        end;
        LineaInd := LineaInd + IntToStr(Usar[i].Vecinos[j].Indice + 1);
        LineaSim := LineaSim + FloatToStrF(Usar[i].Vecinos[j].Distancia,
          ffFixed, 15, 4, Fmt);
      end;
      Salida.Add(LineaInd);
      Salida.Add(LineaSim);
    end;
    Salida.SaveToFile(Ruta);
    Memo1.Lines.Add('Resultados guardados en: ' + Ruta);
  finally
    Salida.Free;
  end;
end;

procedure TForm1.ActualizarInfo;
begin
  if (FEntrenamiento <> nil) and (FEntrenamiento.Filas > 0) then
    lblInfoT.Caption := Format('T: %s | %d filas | %d atributos | %d clases',
      [ExtractFileName(FEntrenamiento.NombreArchivo),
       FEntrenamiento.Filas, FEntrenamiento.Columnas,
       FEntrenamiento.ClasesEsperadas])
  else
    lblInfoT.Caption := 'T: sin cargar';

  if (FPrueba <> nil) and (FPrueba.Filas > 0) then
    lblInfoP.Caption := Format('P: %s | %d filas | %d atributos | %d clases',
      [ExtractFileName(FPrueba.NombreArchivo),
       FPrueba.Filas, FPrueba.Columnas,
       FPrueba.ClasesEsperadas])
  else
    lblInfoP.Caption := 'P: sin cargar';
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  FEntrenamiento := TConjuntoDatos.Create;
  FPrueba := TConjuntoDatos.Create;

  PageControl1.Align := alClient;

  // Barra inferior de la pestaña 1
  Panel1.Parent := TabSheet1;
  Panel1.Align := alBottom;
  Panel1.Height := 48;
  Panel1.Caption := '';
  Panel1.BevelOuter := bvNone;

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

  Button1.Parent := Panel1;
  Button1.Left := 430; Button1.Top := 12; Button1.Width := 144;

  // Barra inferior de la pestaña 2
  Panel2.Parent := TabSheet2;
  Panel2.Align := alBottom;
  Panel2.Height := 48;
  Panel2.Caption := '';
  Panel2.BevelOuter := bvNone;

  Button3.Parent := Panel2;

  // Panel de información de la pestaña 1
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
  FPoints.ShowLines := False;
  FPoints.ShowPoints := True;
  FPoints.Pointer.Style := psCircle;
  FPoints.Pointer.Brush.Color := clBlue;
  FPoints.Pointer.Pen.Color := clBlue;
  Chart2.AddSeries(FPoints);

  FTrend := TLineSeries.Create(Self);
  FTrend.Title := 'Tendencia';
  FTrend.ShowLines := True;
  FTrend.ShowPoints := False;
  FTrend.LinePen.Color := clRed;
  FTrend.LinePen.Width := 2;
  Chart2.AddSeries(FTrend);

  // Gráfica de color
  FDibujar := False;
  ComboBox1.OnChange := @ComboChange;
  ComboBox2.OnChange := @ComboChange;
  Chart1ColorMapSeries1.OnCalculate := @Chart1ColorMapSeries1Calculate;

  // Parámetros del clasificador
  Edit3.Text := '3';
  ComboBox3.Items.Clear;
  ComboBox3.Items.Add('Mayoría simple');
  ComboBox3.Items.Add('Ponderado por similitud');
  ComboBox3.ItemIndex := 0;
  Edit4.Text := '10';

  // Menú Guardar Resultados
  MenuItem5.OnClick := @MenuItem5Click;

  Memo1.Lines.Clear;
  LimpiarClasificador;
  ActualizarInfo;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FPrueba);
  FreeAndNil(FEntrenamiento);
end;

procedure TForm1.MenuItem2Click(Sender: TObject);
var
  Msg: string;
begin
  if not OpenDialog1.Execute then
    Exit;

  if not FEntrenamiento.Cargar(OpenDialog1.FileName, True, 0, Msg) then
  begin
    ShowMessage(Msg);
    Exit;
  end;

  FEntrenamiento.CalcularRangos;
  FEntrenamiento.CalcularTablasNominales;
  SetLength(FAtributosRelevantes, 0);
  Label13.Caption := 'Atributos usados: (sin seleccionar)';
  LimpiarClasificador;

  // El esquema de P dependía de la T anterior: hay que volver a cargar P.
  FreeAndNil(FPrueba);
  FPrueba := TConjuntoDatos.Create;

  StringGrid1.LoadFromCSVFile(OpenDialog1.FileName);
  Label3.Caption := IntToStr(FEntrenamiento.Filas);
  Label4.Caption := IntToStr(FEntrenamiento.Columnas);
  RefrescarCombos;
  ActualizarInfo;
end;

procedure TForm1.MenuItem3Click(Sender: TObject);
begin
  if SaveDialog1.Execute then
    StringGrid1.SaveToCSVFile(SaveDialog1.FileName);
end;

procedure TForm1.MenuItem4Click(Sender: TObject);
var
  Msg: string;
begin
  if (FEntrenamiento = nil) or (FEntrenamiento.Filas = 0) then
  begin
    ShowMessage('Primero carga el entrenamiento (T).');
    Exit;
  end;

  if not OpenDialog2.Execute then
    Exit;

  // P sí incluye su clase real en la última columna (ArchConClase = True)
  if not FPrueba.Cargar(OpenDialog2.FileName, True, 0, Msg) then
  begin
    ShowMessage(Msg);
    Exit;
  end;

  try
    FPrueba.AplicarEsquema(FEntrenamiento);
  except
    on E: Exception do
    begin
      ShowMessage(E.Message);
      Exit;
    end;
  end;

  LimpiarClasificador;
  ActualizarInfo;
end;

procedure TForm1.MenuItem5Click(Sender: TObject);
begin
  if SaveDialog2.Execute then
    GuardarResultados(SaveDialog2.FileName);
end;

end.
