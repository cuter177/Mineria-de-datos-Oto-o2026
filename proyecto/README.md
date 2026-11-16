# Proyecto de Minería de Datos — Clasificador kNN y validación cruzada

Este repositorio contiene el proyecto de la materia de Minería de Datos. La idea fue hacer una aplicación de escritorio en Lazarus/Free Pascal que cubra las tres fases del enunciado: preprocesamiento de datos, clasificación con k-vecinos más cercanos y validación cruzada k-fold.

La aplicación trabaja con dos archivos de texto con el formato que se vio en clase: un conjunto de entrenamiento `T` y un conjunto de prueba `P`. Todo se maneja desde una interfaz con pestañas, y los resultados se muestran en pantalla y también se pueden guardar en archivos.

---

## Tecnologías usadas

- **Lenguaje:** Free Pascal .
- **IDE / framework:** Lazarus con LCL.
- **Gráficas:** TAChart (`TAChartLazarusPkg`), que ya viene con Lazarus.
- **Compatibilidad:** pensado para escritorio Linux/Windows. En Linux necesita las librerías GTK2 de Lazarus.

El proyecto se puede abrir directamente con Lazarus desde `proyecto.lpi`, o compilar desde terminal:

```bash
lazbuild proyecto.lpi
```

El ejecutable se genera como `proyecto`.

---

## Estructura del proyecto

| Archivo | Qué contiene |
|---|---|
| `proyecto.lpr` | Programa principal. Solo crea el formulario y arranca la aplicación. |
| `Unit1.pas` | Toda la lógica de la interfaz: normalización, estadísticas, gráficas, kNN, selección de atributos y validación cruzada. |
| `Unit1.lfm` | Diseño del formulario (pestañas, botones, grids, gráficas). |
| `udatos.pas` | Unidad de datos. Lee los archivos, guarda la metadata de los atributos y calcula la distancia mixta. |
| `ST2-T.txt` | Conjunto de entrenamiento de ejemplo. |
| `ST2-P.txt` | Conjunto de prueba de ejemplo. |
| `minmax.txt`, `robust.txt` | Ejemplos de archivos normalizados que se generaron con la aplicación. |

La separación principal es esta: `udatos.pas` se encarga de los datos “duros” (cargar, tipos de atributo, distancias), y `Unit1.pas` se encarga de la interfaz y de los algoritmos que usan esos datos.

---

## Formato de los archivos de entrada

La primera línea es la metadata. Cada número indica el tipo del atributo:

- `0` → atributo numérico.
- Un número mayor que cero → atributo nominal con esa cantidad de valores posibles.

El último número de la metadata es la cantidad de clases. Después vienen las filas de datos, separadas por comas, y la última columna es la clase.

Por ejemplo, la metadata de `ST2-T.txt` es:

```text
0,0,3,2,0,0,0,0,0,0,0,0,4,4,2,11
```

Eso significa: 15 atributos (los que tienen `0` son numéricos y los que tienen `3`, `2`, `4`, `4`, `2` son nominales) y 11 clases. Los atributos nominales quedan en las posiciones 3, 4, 13, 14 y 15 si se cuentan desde 1.

El conjunto de prueba `P` usa el mismo formato y también trae la clase real en la última columna, lo que permite calcular la exactitud.

---

# Fase 1 — Preprocesamiento

## Carga y visualización

Al abrir un archivo de entrenamiento desde el menú **Archivo → Abrir Entrenamiento**, los datos se cargan en `StringGrid1` y también se guardan en un objeto `TConjuntoDatos`. La aplicación muestra cuántas filas, columnas y clases tiene el conjunto.

La carga no es solo “leer el CSV”: en `udatos.pas` se valida que todas las filas tengan la misma cantidad de columnas, que los valores numéricos sean válidos y que la clase sea un entero. Si algo está mal, se muestra un mensaje con la fila y la columna del error.

## Normalización Min-Max

El botón **Min-Max Scaling** toma los valores `Min` y `Max` que el usuario escribe en los campos de la parte inferior y transforma cada atributo con la fórmula clásica:

```text
x' = Min + ((x - xmin) / (xmax - xmin)) * (Max - Min)
```

Donde `xmin` y `xmax` son el mínimo y el máximo de esa columna. La implementación está en `MinMaxColumna`.

Si una columna es constante (`xmax = xmin`), se deja igual para evitar una división entre cero.

## Normalización Robust Scaling

El botón **Robust Scaling** usa la mediana y el rango intercuartílico:

```text
x' = (x - mediana) / (Q3 - Q1)
```

La mediana y los cuartiles se calculan ordenando la columna y tomando los cuantiles 0.5, 0.25 y 0.75. La ventaja de este método es que no se deja arrastrar tanto por valores atípicos como Min-Max.

La implementación está en `RobustColumna`, y usa una función auxiliar `Cuantil`.

## Guardado de los datos normalizados

Con el menú **Archivo → Guardar** se guarda el contenido actual de `StringGrid1` usando `SaveToCSVFile`. Como la metadata se cargó como la primera fila del grid, el archivo de salida conserva el mismo formato del archivo de entrada.

En el repositorio están `minmax.txt` y `robust.txt` como ejemplos de salidas generadas con la aplicación.

## Estadísticos por atributo

En la pestaña **Estadísticas**, el botón **Calcular Resumen** recorre cada atributo del grid (pensado para los numéricos) y calcula:

- mínimo,
- máximo,
- media,
- desviación estándar,
- sesgo,
- kurtosis.

La media y los momentos se calculan en dos pasadas: primero la media, y luego las sumas de `(x - media)^2`, `(x - media)^3` y `(x - media)^4`. El sesgo y la kurtosis se obtienen dividiendo esos momentos entre la desviación estándar elevada a la potencia correspondiente. La kurtosis que se muestra es la **kurtosis de exceso**, por eso al final se le resta 3.

La desviación estándar es poblacional (se divide entre `n`, no entre `n-1`), que es lo que pedía el curso.

## Correlación entre atributos

En la pestaña **Correlación / Dispersión**, el botón **Buscar Corre.** calcula la correlación de Spearman entre todos los pares de atributos y muestra en un `ListBox` los pares cuyo valor absoluto sea mayor o igual a `0.50`.

Se eligió Spearman en vez de Pearson porque trabaja con rangos y no supone una relación lineal. Además, para atributos que no son estrictamente numéricos o que tienen valores repetidos, se comporta mejor. La función `Rango` calcula los rangos promedio cuando hay empates, y `Spearman` aplica la fórmula de correlación sobre esos rangos.

## Gráfica de dispersión

Con los dos `ComboBox` se eligen dos atributos, y el botón **Graficar Disp.** dibuja una gráfica de dispersión con:

- un punto por cada fila del conjunto,
- una línea de tendencia calculada por mínimos cuadrados,
- el valor de Spearman en el título de la gráfica.

La línea de tendencia se calcula con la fórmula usual:

```text
b1 = Sxy / Sxx
b0 = mediaY - b1 * mediaX
```

## Mapa de calor

En la pestaña **Color**, el botón **Dibujar Grafica de Color** genera un mapa de calor con:

- eje X: atributos,
- eje Y: elementos del conjunto,
- color: valor del atributo, usando una paleta tipo arcoíris.

Primero se recorren todas las columnas para guardar los valores y encontrar el mínimo y máximo globales. Después se configura el `TColorMapSeries` con esos límites y se le dice que no interpole, para que cada celda tenga un color plano. La escala va de azul (valores bajos) a rojo (valores altos), como indica la etiqueta de la interfaz.

---

# Fase 2 — Clasificación con kNN

## La idea general

El clasificador recibe un conjunto de entrenamiento `T` y un conjunto de prueba `P`. Para cada fila de `P` busca las `k` filas de `T` más parecidas, mira las clases de esos vecinos y asigna la clase que más se repita.

El valor de `k` lo escribe el usuario en el campo **Valor de K**.

## Distancia mixta 

Esta fue una de las partes que más se dificultó, porque al principio se tenia un plan para  una “similitud” que no era una funcion de distancia. Pero se adaptó a la función mixta vista en clase.

**Atributo numérico:**

```text
d(a,b) = |a - b| / (|a| + |b|)
```

  Si `a = 0` y `b = 0`, entonces `d(a,b) = 0`.

- **Atributo nominal:**

```text
d(a,b) = suma sobre todas las clases c de |P(c|a) - P(c|b)|
```

  Donde `P(c|a)` es la probabilidad de la clase `c` dado el valor nominal `a`. Esas probabilidades se estiman contando, en `T`, cuántas filas tienen el valor `a` y qué clase tienen.

- **Valor faltante:** si `a` o `b` es faltante, `d(a,b) = 1`.

- **Distancia total:** se promedian las distancias de todos los atributos usados. Se eligió el promedio y no la suma para que el resultado no dependa de cuántos atributos se estén usando; así la comparación entre “todos” y “relevantes” es más justa.

Un fragmento representativo de `udatos.pas`:

```pascal
if Info.Tipo = taNumerico then
begin
  if (ValorA = 0.0) and (ValorB = 0.0) then
    Exit(0.0);
  Exit(Abs(ValorA - ValorB) / (Abs(ValorA) + Abs(ValorB)));
end;

// nominal
Result := Result + Abs(ProbA - ProbB);
```

Para los atributos nominales se precalculan las tablas `P(c|valor)` al cargar `T` con `CalcularTablasNominales`. Si en `P` aparece un valor nominal que no estaba en `T`, se usa la distribución global de clases `P(c)` como respaldo, y así el programa no se cae.

Con las dos primeras filas de `ST2-T.txt`, la distancia promedio usando los 15 atributos da `0.178288`. Ese valor nos sirvió para comprobar que la fórmula estaba bien implementada.

## Búsqueda de los k vecinos

`ObtenerVecinos` recorre todas las filas de `T`, calcula la distancia contra la fila de `P` y se queda con las `k` distancias más pequeñas. La lista se mantiene ordenada de menor a mayor con una inserción, así que al final los vecinos quedan del más cercano al más lejano.

Ese orden es importante porque el archivo de salida debe mostrar primero las instancias más similares (o sea, con menor distancia).

## Votación

Hay dos formas de votar, seleccionables en el `ComboBox`:

- **Mayoría simple:** cada vecino vale un voto.
- **Ponderado por similitud:** cada vecino pesa según su cercanía. Como estamos trabajando con distancias, se usa `1 / (1 + d)`. Así, un vecino con distancia 0 pesa 1, y un vecino lejano pesa cada vez menos.

La etiqueta de la interfaz todavía dice “Ponderado por similitud”, pero internamente el peso se calcula con la distancia.

## Exactitud y error en P

Después de clasificar todas las filas de `P`, se compara la clase predicha con la clase real y se calcula:

```text
exactitud = aciertos / total
error     = 1 - exactitud
```

Los resultados se muestran en las etiquetas de resumen y también por instancia en `StringGrid3`, con columnas para la clase real, la clase predicha, si coinciden y los vecinos encontrados.

Además se calcula una exactitud por **Leave-One-Out (LOO)** sobre `T`, que sirve como referencia interna: se entrena con todas las filas menos una y se prueba con la que se dejó fuera. No es lo mismo que la exactitud en `P`, porque `P` es un conjunto aparte.

## Archivo de salida

Con el menú **Archivo → Guardar Resultados** se genera un archivo con dos líneas por cada fila de `P`:

1. los índices de los `k` vecinos, separados por comas;
2. las distancias correspondientes, separadas por comas.

Los índices se escriben en base 1, y las distancias con 4 decimales y punto decimal (sin importar la configuración regional del sistema). El orden es ascendente, igual que el ejemplo del enunciado:

```text
53,15,29
0.34,0.55,0.58
185,89,16
0.22,0.78,0.96
```

En el código, el archivo se arma con un `TStringList` y se guarda con `SaveToFile`.

## Selección de atributos relevantes

Para descartar atributos se usó **ganancia de información**. La idea es medir cuánto reduce la incertidumbre de la clase cada atributo.

El proceso es:

1. Agrupar los valores de cada atributo según su tipo:
   - **Nominal:** cada valor distinto es un grupo. No se interpreta el código como número ni se mete en bins.
   - **Numérico:** se discretiza en 10 bins de igual ancho.
2. Calcular la entropía de la clase.
3. Calcular la entropía condicionada por el atributo.
4. La ganancia es `H(clase) - H(clase | atributo)`.

Para un atributo nominal con valores `v`, la entropía condicionada se calcula así:

```text
H(clase | atributo) = suma_v P(v) * H(clase | v)
```

Donde `P(v)` es la proporción de filas con el valor `v` y `H(clase | v)` es la entropía de las clases dentro de ese grupo. Esto es distinto a discretizar por rango: si los códigos fueran `10, 100, 1000`, se tratan como tres categorías separadas y no se mezclan por caer cerca en una recta numérica.

En el código, la función `AgruparAtributo` devuelve un identificador de grupo por fila y la cantidad de grupos. `GananciaInfo` usa esa cantidad en vez de asumir siempre `Bins`.

Después se ordenan los atributos de mayor a menor ganancia y se corta en el **mayor salto** entre dos valores consecutivos del ranking. Ese corte separa los atributos que aportan información de los que ya no aportan casi nada.

El fragmento clave del corte es:

```pascal
Salto := IG[Orden[i]] - IG[Orden[i + 1]];
if Salto > MayorSalto then
begin
  MayorSalto := Salto;
  CorteIdx := i;
end;
```

Con `ST2-T.txt`, este método selecciona **10 de 15 atributos**. Los relevantes son los atributos 1, 2, 5, 6, 7, 8, 9, 10, 11 y 12 (contando desde 1). Los atributos 3, 4, 13, 14 y 15, que son justamente los nominales, quedan descartados. Esto no cambia respecto a la versión anterior porque en este dataset los códigos nominales son `0, 1, 2, 3` y cada uno ya caía en un bin distinto; la diferencia se vería con códigos nominales arbitrarios.

Los atributos elegidos se muestran en la etiqueta **Atributos usados** y el ranking completo se escribe en el `Memo` de la pestaña del clasificador. El `Memo` también indica cómo se agrupó cada tipo de atributo.

## Comparación: todos vs relevantes

La pestaña **Clasificador** tiene tres botones:

- **Clasificar con todos:** usa los 15 atributos.
- **Clasificar con Relevantes:** usa solo los atributos elegidos por ganancia de información.
- **Comparar:** corre ambas clasificaciones en una sola pasada y muestra la diferencia.

La comparación se hace tanto en `P` como en `T` con LOO, para no quedarse solo con el resultado de un conjunto. Las diferencias se muestran con signo, para ver si los relevantes mejoran o empeoran.

---

# Fase 3 — Validación cruzada k-fold

## Qué es lo que se implementó

La validación cruzada k-fold parte `T` en `k` pliegues. En cada iteración se entrena con `k-1` pliegues y se prueba con el pliegue que quedó fuera. Al final se reporta el resultado de cada pliegue y el promedio.

El usuario escribe la cantidad de pliegues en **Numero de Pliegues** (por defecto 10) y ejecuta con **Ejecutar K-FOLD**. El valor de `k` del kNN es el mismo que ya se usa en la fase 2.

## Partición estratificada

Para que los pliegues queden parecidos, la partición es **estratificada por clase**:

1. Se agrupan los índices de `T` por clase.
2. Se baraja cada grupo con una semilla fija (`RandSeed := 20261116`) para que el resultado sea reproducible.
3. Se reparten los elementos de cada clase por turnos entre los pliegues.

El reparto se hace con esta idea:

```pascal
FoldDe[PorClase[c][i]] := (Offset + i) mod Pliegues;
```

Si por alguna distribución algún pliegue quedara vacío, se hace un reparto aleatorio de respaldo. También se recorta `k` si el pliegue de entrenamiento más pequeño no alcanza para tantos vecinos.

## Resultados que se muestran

Cada pliegue produce una fila en `StringGrid4` con:

- número de pliegue,
- tamaño del entrenamiento,
- tamaño de la prueba,
- aciertos,
- exactitud,
- error.

Como se evalúan dos variantes, “todos” y “relevantes”, las celdas muestran ambos valores separados por `|`. Por ejemplo, una celda podría verse así:

```text
31/33|32/33
```

Después de la tabla se muestran:

- promedio de exactitud y desviación estándar para todos los atributos,
- promedio y desviación estándar para los atributos relevantes.

En el `Memo` de la pestaña se escribe el detalle de cada pliegue y la exactitud global.

## Relación con LOO

Leave-One-Out es un caso particular de k-fold cuando `k = |T|`: cada pliegue tiene un solo elemento. Por eso LOO suele dar un resultado parecido pero no idéntico al de un 10-fold, ya que en 10-fold cada modelo se entrena con menos datos.

En la aplicación se mantienen las dos cosas: LOO como referencia de la fase 2 y k-fold como resultado principal de la fase 3.

---

# Cómo usar la aplicación

1. Abrir `proyecto.lpi` en Lazarus y compilar, o ejecutar `lazbuild proyecto.lpi`.
2. Cargar el conjunto de entrenamiento con **Archivo → Abrir Entrenamiento**.
3. En la pestaña **Datos / Normalizacion** se pueden aplicar Min-Max o Robust Scaling y guardar el resultado con **Archivo → Guardar**.
4. En **Estadísticas** se calcula el resumen por atributo.
5. En **Correlación / Dispersión** se buscan pares correlacionados y se grafican dos atributos.
6. En **Color** se dibuja el mapa de calor.
7. Cargar el conjunto de prueba con **Archivo → Abrir Prueba**.
8. En la pestaña **Clasificador** elegir `k` y el tipo de voto, seleccionar atributos relevantes y clasificar o comparar.
9. Guardar los detalles de la clasificación con **Archivo → Guardar Resultados**.
10. En la misma pestaña, escribir la cantidad de pliegues y ejecutar el k-fold.

---

# Resultados y observaciones

- El conjunto `ST2-T.txt` tiene 329 filas de datos, 15 atributos y 11 clases.
- Los atributos nominales son los de las posiciones 3, 4, 13, 14 y 15.
- Todos los valores nominales que aparecen en `ST2-P.txt` existen en `ST2-T.txt`, así que el respaldo de la distribución previa no se activa con este dataset, pero queda implementado para otros casos.
- La ganancia de información selecciona 10 de 15 atributos, por lo que la comparación entre “todos” y “relevantes” sí cambia el conjunto de entrada. Los nominales se agrupan por categoría exacta; aun así quedan al final porque su relación con la clase es baja en este dataset.
- La distancia entre las dos primeras filas de `ST2-T.txt` es `0.178288`, un valor que usamos para validar la implementación de la fórmula de la página 21.

---

# Limitaciones y cosas que mejoraríamos

Somos conscientes de que el proyecto se puede pulir. Estas son las cosas que dejaríamos anotadas para una siguiente versión:

1. **Normalización, estadísticas y correlación sobre atributos nominales.** La interfaz trabaja sobre el grid y aplica los métodos a todas las columnas de atributos, sin filtrar por tipo. Lo ideal sería aplicar Min-Max, Robust Scaling, los estadísticos y la correlación solo a los atributos numéricos.

2. **Mapa de calor con atributos nominales.** La gráfica recorre todas las columnas de atributos, así que los nominales aparecen como bandas de color. Para que sea estrictamente lo pedido, habría que filtrar solo los numéricos.

3. **Selección de atributos y tablas nominales en la validación cruzada.** Actualmente la ganancia de información y las probabilidades `P(c|valor)` se calculan con todo `T` antes de partir en pliegues. Para una validación cruzada estrictamente correcta, esas cosas deberían recalcularse solo con el entrenamiento de cada pliegue. Es una fuga de información que hace que el resultado de “relevantes” quede un poco optimista.

4. **Guardado de resultados.** `GuardarResultados` guarda la variante de relevantes si existe, aunque la última clasificación haya sido con todos. Lo correcto sería recordar cuál fue la última variante ejecutada y guardar esa.

5. **Etiquetas de la interfaz.** Algunos textos todavía dicen “similitud” aunque internamente ya se trabaja con distancias. Los dejamos así para no cambiar el diseño que ya estaba armado.

6. **Sesgo de la IG hacia atributos con muchas categorías.** Ya se corrigió el tratamiento de los nominales: ahora se agrupan por categoría exacta y no se discretizan como números. Pero la ganancia de información todavía puede favorecer atributos con muchos valores distintos. Una mejora sería usar gain ratio, agrupar categorías raras o exigir un mínimo de filas por categoría; eso obligaría a recalibrar el corte por mayor salto.

7. **Agregación de distancias.** Se usó el promedio entre atributos, que es lo que se decidió mientras se confirmaba con el profesor si la función de clase usa promedio o suma.

---

# Conclusión

El proyecto cumple con las tres fases del enunciado: preprocesa los datos, clasifica instancias nuevas con un kNN propio usando la distancia mixta de clase, selecciona atributos con ganancia de información, compara todos contra relevantes y evalúa con validación cruzada k-fold mostrando cada pliegue y el promedio.

La parte que más nos hizo aprender fue la distancia mixta: al principio parecía solo una fórmula, pero cambia por completo la forma de buscar vecinos, de votar y hasta el formato del archivo de salida. También nos dimos cuenta de que una validación cruzada no es solo partir los datos, sino cuidar que la selección de atributos y las probabilidades se calculen sin mirar el pliegue de prueba.

---

## Referencias

- Apuntes y diapositivas del curso de Minería de Datos (`MDatos-Ot26-VI.pdf`), en especial:
  - página 21: función mixta de similaridad/distancia;
  - página 169: validación cruzada k-fold.
- Documentación de Free Pascal y Lazarus.
- Documentación de TAChart para las gráficas.
