# --Examen parcial 19 nov 2021
# --Andrés Fernández - 22062204


# PREGUNTA 1 --------------------------------------------------------------
## Carga las librerías necesarias, debe realizarlo en UNA SOLA  LINEA -----
# 1 PTO

# --(sólo si no está instalado ya)
# --install.packages("pacman")

pacman::p_load(tidyverse, httr, xml2, jsonlite, leaflet, leaflet.extras, janitor)


# PREGUNTA 2---------------------------------------------------------------
##Recibirás un archivo con el que tendrás que trabajar (CANVAS)-----------
# Recibirás una URL que deberás usar para descargar.

urls = c("https://datos.madrid.es/egob/catalogo/202584-0-aparcamientos-residentes.csv","https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes/PreciosCarburantes/EstacionesTerrestres/","https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes/PreciosCarburantes/Listados/Provincias/")

# Trae los archivos  a RStudio mediante el uso de API Rest
## LEE los archivos y responda por cada URL:
## Que tipo de Charset tiene UTF-8 ?
## Cual es la aplicación del archivo XML, ?
## Cual es el codigo de recibido 200 ?

peso <- 0

# --Archivo 1
file1 <- GET(urls[1])
headers(file1)
# --Charset: ISO-8859-1
# --Tipo: CSV
status_code(file1)
# --200
peso <- peso + as.numeric(headers(file1)$`content-length`)

# --Archivo 2
file2 <- GET(urls[2])
headers(file2)
# --Charset: UTF-8
# --Tipo: XML
status_code(file2)
# --200
peso <- peso + as.numeric(headers(file2)$`content-length`)

# --Archivo 3
file3 <- GET(urls[3])
headers(file3)
# --Charset: UTF-8
# --Tipo: XML
status_code(file2)
# --200
peso <- peso + as.numeric(headers(file3)$`content-length`)

#Cual es el peso total de los archivos recibidos en MB
peso/1024/1024
# --Resultado: 14,96 MB

# PREGUNTA 3---------------------------------------------------------------
# Guarde en un archivo ( por cada url) con sus correspondientes extensiones 
# en el directorio de trabajo, los archivos de llamaran f0.xxx --------
# 1 PTO
GET(urls[1], write_disk("f0.csv"))
GET(urls[2], write_disk("f1.xml"))
GET(urls[3], write_disk("f2.xml"))

# PREGUNTA 4---------------------------------------------------------------
# Lea los archivos con la libreria correspondiente de tidyverse y guardelos 
# en variables (r_xxx)
# 1 PUNTO
f0 <- read_csv2("f0.csv", col_names=TRUE) # Uso csv2 para que el separador sea ;
f1 <- read_xml("f1.xml")
f2 <- read_xml("f2.xml")


# PREGUNTA 5---------------------------------------------------------------
# Guarde el archivo de las galineras como un tibble en la variable ds

# --En las prácticas he comprobado que el archivo de las gasolineras
# --es más fácil de manejar si se accede con JSON
ds_previo <- fromJSON(urls[2])
ds <- as_tibble(ds_previo$ListaEESSPrecio)

# Cuantas observaciones tiene ?
# --Hay 11285 observaciones, con 32 variables cada una.

# Asegurese que los datos esten en su correcto formato, quite acentos, espacios
# en blanco.
ds_clean = ds %>% clean_names() %>% glimpse()
# --Todas las columnas son strings
ds_clean2 = ds_clean %>% type_convert(locale = locale(decimal_mark=",")) %>% glimpse()
# --Ya tenemos las columnas que necesitamos como datos numéricos

# Clasifique las gasolineras entre low-cost y no low-cost., cree una nueva columna.
# --Las gasolineras no low-cost son las marcas tradicionales: REPSOL, CEPSA, etc.
# --Busco las gasolineras con más franquicias para ver cuáles son las marcas tradicionales:
count(ds_clean2, rotulo, sort="TRUE")
caras <- c("REPSOL", "CEPSA", "GALP", "SHELL", "BP", "PETRONOR")

ds_conPrecio <- mutate(ds_clean2, cara = ifelse(rotulo %in% caras, TRUE, FALSE))

# Cuántas gasolineras tiene la provincia de Granada y LA Coruña ¿?
ds_Granada = filter(ds_clean2, provincia == "GRANADA")
ds_LaCoruna = filter(ds_clean2, provincia == "CORUÑA (A)")
# --Hay 275 gasolineras en Granada, y 273 en La Coruña.

# PREGUNTA 6---------------------------
# Cual es el PRECIO MEDIO del gasóleo EN EL TERRITORIO NACIONAL a nivel provincias, excepto las grandes CIUDADES ESPAÑOLAS ("MADRID", "BARCELONA", "SEVILLA", "VALENCIA")
ds_provincias = filter(ds_clean2, provincia != "MADRID") %>% filter(provincia != "BARCELONA") %>% filter(provincia != "SEVILLA") %>% filter(provincia != "VALENCIA")
ds_provincias_vendenGasoleo = filter(ds_provincias, is.na(precio_gasoleo_a) == FALSE)
precioGasoleoProvincias = mean(ds_provincias_vendenGasoleo$precio_gasoleo_a)
# --El precio medio es 1,3668 euros.

# Pregunta 7 --------------------------------------------------------------
#Queremos abrir una nueva estación de servicio, como no queremos pagar franquicias ya que es mucho dinero;
#nuestro objetivo es montar una gasolinera low-cost, compitiendo con lo que mejor podemos ofrecer, y es :24h y precio

#Filtre por las gasolineras que están abiertas 24 horas y cree un nuevo data set eliminando esta última variable.
ds_no24h = filter(ds_clean2, horario != "L-D: 24H")

#Busque el nicho de mercado en ll municipio será asignado en el examen.( en función de donde estéis sentados), 
#guárdelo en un archivo con su número de expediente y que sea de tipo Excel.
#-- Municipio asignado: Alcalá de Henares
ds_Alcala = filter(ds_no24h, municipio == "Alcalá de Henares")
write_excel_csv(ds_Alcala, "22062204.xls")

# Genere un mapa interactivo de calor donde aparezca cada una de las estaciones asignadas en su nicho.( Guárdelo como página web)
m <- ds_Alcala %>% leaflet() %>% addProviderTiles("CartoDB") %>% addHeatmap(lng = ~longitud_wgs84,lat = ~latitud, radius = 12) %>% addCircles(lng = ~longitud_wgs84,lat = ~latitud)
m


# PREGUNTA 8---------------------------------------------------------------
## Existe alguna diferencia entre el precio medio del gasóleo y la gasolina 98 e5
##entre los distritos de la zona norte ( Pozuelo, Las Rozas, Tres Cantos) y la zona sur ( Aranjuez, Valdemoro, Pinto) de la comunidad de Madrid ?

norte <- c("POZUELO DE ALARCON", "ROZAS DE MADRID (LAS)", "TRES CANTOS")
sur <- c("ARANJUEZ", "VALDEMORO", "PINTO")

ds_norte = filter(ds_clean2, localidad %in% norte) 
ds_norte_vendenGasoleo = filter(ds_norte, is.na(precio_gasoleo_a) == FALSE)
ds_norte_vendenGasolina = filter(ds_norte, is.na(precio_gasolina_98_e5) == FALSE)

precio_gasoleo_norte = mean(ds_norte_vendenGasoleo$precio_gasoleo_a)
precio_gasolina_norte = mean(ds_norte_vendenGasolina$precio_gasolina_98_e5)

ds_sur = filter(ds_clean2, localidad %in% sur) 
ds_sur_vendenGasoleo = filter(ds_sur, is.na(precio_gasoleo_a) == FALSE)
ds_sur_vendenGasolina = filter(ds_sur, is.na(precio_gasolina_98_e5) == FALSE)

precio_gasoleo_sur = mean(ds_sur_vendenGasoleo$precio_gasoleo_a)
precio_gasolina_sur = mean(ds_sur_vendenGasolina$precio_gasolina_98_e5)

# Guarde en una tibble.
lugar <- c("norte", "sur")
precio_gasoleo <- c(precio_gasoleo_norte, precio_gasoleo_sur)
precio_gasolina <- c(precio_gasolina_norte, precio_gasolina_sur)
ds_nortesur <- tibble(lugar, precio_gasoleo, precio_gasolina)

# PINTA EL GRAFICO MAS APROPIADO
grafico <- ggplot(ds_nortesur, aes(precio_gasoleo, precio_gasolina), show.legend = TRUE) + geom_point()
grafico
