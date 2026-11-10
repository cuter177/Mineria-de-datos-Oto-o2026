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
    procedure AplicarEsquema(const Fuente: TConjuntoDatos);
  end;

function SimilitudAtributo(const Info: TInfoAtributo;
  ValorA, ValorB: Double): Double;

function SimilitudEntre(const A: TConjuntoDatos; FilaA: Integer;
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

function SimilitudAtributo(const Info: TInfoAtributo;
  ValorA, ValorB: Double): Double;
var
  Rango: Double;
begin
  if Info.Tipo = taNominal then
  begin
    if ValorA = ValorB then
      Result := 1.0
    else
      Result := 0.0;
    Exit;
  end;

  Rango := Info.Max - Info.Min;

  if Rango <= 0 then
  begin
    if ValorA = ValorB then
      Result := 1.0
    else
      Result := 0.0;
    Exit;
  end;

  Result := 1.0 - Abs(ValorA - ValorB) / Rango;

  if Result < 0.0 then
    Result := 0.0;
end;

function SimilitudEntre(const A: TConjuntoDatos; FilaA: Integer;
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
    Result := Result + SimilitudAtributo(
      A.Info[AtributosUsados[k]],
      A.Datos[FilaA][AtributosUsados[k]],
      B.Datos[FilaB][AtributosUsados[k]]);

  Result := Result / Length(AtributosUsados);
end;

end.
