unit uDatos;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math;

type
  TTipoAtributo = (taNumerico, taNominal);

  TInfoAtributo = record
    Tipo: TTipoAtributo;
    Min: Double;
    Max: Double;
    Cardinalidad: Integer;
    // Para atributos nominales: valores distintos observados en T y, para
    // cada uno, la distribucion P(c|valor) sobre las clases. Priori es la
    // distribucion global P(c) y se usa como respaldo si aparece un valor
    // nominal no visto en entrenamiento.
    Valores: array of Double;
    ProbCond: array of array of Double;
    Priori: array of Double;
  end;

  TConjuntoDatos = class
  private
    FDecimal: TFormatSettings;
    procedure Limpiar;

  public
    Filas: Integer;
    Columnas: Integer;
    ClasesEsperadas: Integer;
    NombreArchivo: string;
    TieneClase: Boolean;   //atributo para distinguir si es de entrenamiento o de prueba
    Datos: array of array of Double;
    Clases: array of Integer;
    Info: array of TInfoAtributo;

    constructor Create;
    destructor Destroy; override;

    function Cargar(const Ruta: string; ArchConClase: Boolean; NumAtributos: Integer; out Mensaje: string): Boolean;
    procedure CalcularRangos;
    procedure CalcularTablasNominales;
    procedure AplicarEsquema(const Fuente: TConjuntoDatos);
  end;

function DistanciaAtributo(const Info: TInfoAtributo;
  ValorA, ValorB: Double): Double;

function DistanciaEntre(const A: TConjuntoDatos; FilaA: Integer;
  const B: TConjuntoDatos; FilaB: Integer;
  const AtributosUsados: array of Integer): Double;

implementation

constructor TConjuntoDatos.Create;
begin
  inherited Create;
  FDecimal := DefaultFormatSettings;
  FDecimal.DecimalSeparator := '.';
  FDecimal.ThousandSeparator := #0;
  Limpiar;
end;

destructor TConjuntoDatos.Destroy;
begin
  Limpiar;
  inherited Destroy;
end;

procedure TConjuntoDatos.Limpiar;
begin
  Filas := 0;
  Columnas := 0;
  ClasesEsperadas := 0;
  NombreArchivo := '';
  TieneClase := False;
  Datos := nil;
  Clases := nil;
  Info := nil;
end;

function TConjuntoDatos.Cargar(const Ruta: string; ArchConClase: Boolean;
  NumAtributos: Integer; out Mensaje: string): Boolean;
var
  Lineas, Partes: TStringList;
  i, j, Primera, NF, N, Fila: Integer;
  Linea: string;
  Valor: Double;
  Clase: Integer;
begin
  Result := False;
  Mensaje := '';
  Limpiar;
  NombreArchivo := Ruta;
  TieneClase := ArchConClase;

  Lineas := TStringList.Create;
  Partes := TStringList.Create;
  try
    try
      Lineas.LoadFromFile(Ruta);
    except
      on E: Exception do
      begin
        Mensaje := 'No se pudo leer el archivo: ' + E.Message;
        Exit;
      end;
    end;

    if Lineas.Count = 0 then
    begin
      Mensaje := 'El archivo está vacío.';
      Exit;
    end;

    if (Length(Lineas[0]) >= 3) and
       (Lineas[0][1] = #$EF) and
       (Lineas[0][2] = #$BB) and
       (Lineas[0][3] = #$BF) then
      Lineas[0] := Copy(Lineas[0], 4, Length(Lineas[0]) - 3);

    Primera := -1;
    for i := 0 to Lineas.Count - 1 do
      if Trim(Lineas[i]) <> '' then
      begin
        Primera := i;
        Break;
      end;

    if Primera < 0 then
    begin
      Mensaje := 'No hay líneas con datos.';
      Exit;
    end;

    Partes.Delimiter := ',';
    Partes.StrictDelimiter := True;
    Partes.DelimitedText := Lineas[Primera];

    NF := Partes.Count;
    if NF < 2 then
    begin
      Mensaje := 'La fila de metadatos debe tener al menos 2 columnas.';
      Exit;
    end;

    // Número de atributos que se van a usar
    if ArchConClase then
      Columnas := NF - 1
    else if NumAtributos > 0 then
      Columnas := NumAtributos
    else
      Columnas := NF;

    if (Columnas <= 0) or (Columnas > NF) then
    begin
      Mensaje := Format(
        'Número de atributos inválido: %d (el archivo tiene %d columnas).',
        [Columnas, NF]);
      Limpiar;
      Exit;
    end;

    ClasesEsperadas := StrToIntDef(Trim(Partes[NF - 1]), 0);

    SetLength(Info, Columnas);
    for j := 0 to Columnas - 1 do
    begin
      Info[j].Cardinalidad := StrToIntDef(Trim(Partes[j]), 0);
      if Info[j].Cardinalidad = 0 then
        Info[j].Tipo := taNumerico
      else
        Info[j].Tipo := taNominal;
      Info[j].Min := 0;
      Info[j].Max := 0;
    end;

    N := 0;
    for i := Primera + 1 to Lineas.Count - 1 do
      if Trim(Lineas[i]) <> '' then
        Inc(N);

    SetLength(Datos, N);

    if ArchConClase then
      SetLength(Clases, N)
    else
      Clases := nil;

    for i := 0 to N - 1 do
      SetLength(Datos[i], Columnas);

    Fila := 0;
    for i := Primera + 1 to Lineas.Count - 1 do
    begin
      Linea := Trim(Lineas[i]);
      if Linea = '' then
        Continue;

      Partes.DelimitedText := Linea;

      if Partes.Count <> NF then
      begin
        Mensaje := Format(
          'La fila %d tiene %d columnas; se esperaban %d.',
          [i + 1, Partes.Count, NF]);
        Limpiar;
        Exit;
      end;

      for j := 0 to Columnas - 1 do
      begin
        if not TryStrToFloat(Trim(Partes[j]), Valor, FDecimal) then
        begin
          Mensaje := Format(
            'Valor inválido en la fila %d, columna %d: "%s".',
            [i + 1, j + 1, Trim(Partes[j])]);
          Limpiar;
          Exit;
        end;
        Datos[Fila][j] := Valor;
      end;

      if ArchConClase then
      begin
        if not TryStrToInt(Trim(Partes[Columnas]), Clase) then
        begin
          Mensaje := Format(
            'Clase inválida en la fila %d: "%s".',
            [i + 1, Trim(Partes[Columnas])]);
          Limpiar;
          Exit;
        end;
        Clases[Fila] := Clase;
      end;

      Inc(Fila);
    end;

    Filas := N;
    Result := True;
  finally
    Partes.Free;
    Lineas.Free;
  end;
end;

procedure TConjuntoDatos.CalcularRangos;
var
  i, j: Integer;
begin
  if Filas = 0 then
    Exit;

  for j := 0 to Columnas - 1 do
    if Info[j].Tipo = taNumerico then
    begin
      Info[j].Min := Datos[0][j];
      Info[j].Max := Datos[0][j];

      for i := 1 to Filas - 1 do
      begin
        if Datos[i][j] < Info[j].Min then
          Info[j].Min := Datos[i][j];
        if Datos[i][j] > Info[j].Max then
          Info[j].Max := Datos[i][j];
      end;
    end;
end;

procedure TConjuntoDatos.CalcularTablasNominales;
var
  i, j, c, v, n, nValores, MaxClase: Integer;
  Valor: Double;
  Encontrado: Boolean;
  ConteoClase, ConteoValor: array of Integer;
  ConteoValorClase: array of array of Integer;
begin
  if (Filas = 0) or not TieneClase then
    Exit;

  MaxClase := -1;
  for i := 0 to Filas - 1 do
    if Clases[i] > MaxClase then
      MaxClase := Clases[i];

  if MaxClase < 0 then
    Exit;

  SetLength(ConteoClase, MaxClase + 1);
  for c := 0 to MaxClase do
    ConteoClase[c] := 0;
  for i := 0 to Filas - 1 do
    if (Clases[i] >= 0) and (Clases[i] <= MaxClase) then
      Inc(ConteoClase[Clases[i]]);

  for j := 0 to Columnas - 1 do
  begin
    if Info[j].Tipo <> taNominal then
      Continue;

    SetLength(Info[j].Priori, MaxClase + 1);
    for c := 0 to MaxClase do
      if Filas > 0 then
        Info[j].Priori[c] := ConteoClase[c] / Filas
      else
        Info[j].Priori[c] := 0.0;

    // Valores nominales distintos observados en T.
    nValores := 0;
    SetLength(Info[j].Valores, 0);
    for i := 0 to Filas - 1 do
    begin
      if IsNan(Datos[i][j]) then
        Continue;

      Valor := Datos[i][j];
      Encontrado := False;
      for v := 0 to nValores - 1 do
        if Info[j].Valores[v] = Valor then
        begin
          Encontrado := True;
          Break;
        end;

      if not Encontrado then
      begin
        SetLength(Info[j].Valores, nValores + 1);
        Info[j].Valores[nValores] := Valor;
        Inc(nValores);
      end;
    end;

    // Conteo por valor y por clase, luego P(c|valor).
    SetLength(Info[j].ProbCond, nValores);
    SetLength(ConteoValor, nValores);
    SetLength(ConteoValorClase, nValores);
    for v := 0 to nValores - 1 do
    begin
      ConteoValor[v] := 0;
      SetLength(Info[j].ProbCond[v], MaxClase + 1);
      SetLength(ConteoValorClase[v], MaxClase + 1);
      for c := 0 to MaxClase do
        ConteoValorClase[v][c] := 0;
    end;

    for i := 0 to Filas - 1 do
    begin
      if IsNan(Datos[i][j]) then
        Continue;
      Valor := Datos[i][j];
      for v := 0 to nValores - 1 do
        if Info[j].Valores[v] = Valor then
        begin
          Inc(ConteoValor[v]);
          if (Clases[i] >= 0) and (Clases[i] <= MaxClase) then
            Inc(ConteoValorClase[v][Clases[i]]);
          Break;
        end;
    end;

    for v := 0 to nValores - 1 do
    begin
      n := ConteoValor[v];
      for c := 0 to MaxClase do
        if n > 0 then
          Info[j].ProbCond[v][c] := ConteoValorClase[v][c] / n
        else
          Info[j].ProbCond[v][c] := Info[j].Priori[c];
    end;
  end;
end;

procedure TConjuntoDatos.AplicarEsquema(const Fuente: TConjuntoDatos);
var
  j: Integer;
begin
  if Fuente.Columnas <> Columnas then
    raise Exception.CreateFmt(
      'El número de columnas no coincide: T tiene %d y P tiene %d.',
      [Fuente.Columnas, Columnas]);

  SetLength(Info, Columnas);
  for j := 0 to Columnas - 1 do
    Info[j] := Fuente.Info[j];
end;

procedure ContarClases(const T: TConjuntoDatos; var Conteo: array of Integer);
var
  i, c: Integer;
begin
  for c := 0 to High(Conteo) do
    Conteo[c] := 0;

  if (T = nil) or not T.TieneClase then
    Exit;

  for i := 0 to T.Filas - 1 do
  begin
    c := T.Clases[i];
    if (c >= 0) and (c <= High(Conteo)) then
      Inc(Conteo[c]);
  end;
end;

function BuscarValorNominal(const Info: TInfoAtributo; Valor: Double): Integer;
var
  v: Integer;
begin
  for v := 0 to High(Info.Valores) do
    if Info.Valores[v] = Valor then
      Exit(v);
  Result := -1;
end;

function DistanciaAtributo(const Info: TInfoAtributo;
  ValorA, ValorB: Double): Double;
var
  c, idxA, idxB: Integer;
  ProbA, ProbB: Double;
begin
  // Si falta cualquiera de los dos valores, la distancia es 1.
  if IsNan(ValorA) or IsNan(ValorB) then
    Exit(1.0);

  if Info.Tipo = taNumerico then
  begin
    // |a-b| / (|a|+|b|), con el caso especial a=b=0.
    if (ValorA = 0.0) and (ValorB = 0.0) then
      Exit(0.0);
    Exit(Abs(ValorA - ValorB) / (Abs(ValorA) + Abs(ValorB)));
  end;

  // Distancia nominal: suma sobre clases de |P(c|a)-P(c|b)|.
  // Si no se construyeron las tablas (sin clases de entrenamiento), se usa
  // igualdad como respaldo.
  if Length(Info.Priori) = 0 then
  begin
    if ValorA = ValorB then
      Exit(0.0)
    else
      Exit(1.0);
  end;

  idxA := BuscarValorNominal(Info, ValorA);
  idxB := BuscarValorNominal(Info, ValorB);

  Result := 0.0;
  for c := 0 to High(Info.Priori) do
  begin
    if (idxA >= 0) and (idxA <= High(Info.ProbCond)) then
      ProbA := Info.ProbCond[idxA][c]
    else
      ProbA := Info.Priori[c];

    if (idxB >= 0) and (idxB <= High(Info.ProbCond)) then
      ProbB := Info.ProbCond[idxB][c]
    else
      ProbB := Info.Priori[c];

    Result := Result + Abs(ProbA - ProbB);
  end;
end;

function DistanciaEntre(const A: TConjuntoDatos; FilaA: Integer;
  const B: TConjuntoDatos; FilaB: Integer;
  const AtributosUsados: array of Integer): Double;
var
  k: Integer;
begin
  if Length(AtributosUsados) = 0 then
  begin
    Result := 0.0;
    Exit;
  end;

  Result := 0.0;

  for k := 0 to High(AtributosUsados) do
    Result := Result + DistanciaAtributo(
      A.Info[AtributosUsados[k]],
      A.Datos[FilaA][AtributosUsados[k]],
      B.Datos[FilaB][AtributosUsados[k]]);

  Result := Result / Length(AtributosUsados);
end;

end.
