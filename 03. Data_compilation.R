## Set as working directory the folder where this file is
actual_wd <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(actual_wd)

## Install packages of they are not already installed
x <- c("rJava", "xlsxjars", "xlsx", "WriteXLS", "tidyverse", 
       "missForest", "doParallel", "stringi")
new.packages <- x[!(x %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

## Load the packages
lapply(x, library, character.only = TRUE)

rm(actual_wd, x, new.packages)


##############################################
### IMPORT DATA (using monthly aggregation ###
##############################################

Caracteristicas_generales_personas <- 
  read.table(file = "Processed_files/Caracteristicas_generales_personas.csv", 
                                               header = TRUE, sep = ";")
Caracteristicas_generales_personas [,263]<-
  as.numeric(gsub(",", ".", gsub("\\.", "", Caracteristicas_generales_personas$FEX_C)))


GDP <- read.table(file = "Processed_files/GDP.csv", 
                  header = TRUE, sep = ";")

GDU <- read.table(file = "Processed_files/GDU.csv", 
                  header = TRUE, sep = ";")

GDU_capc <- read.table(file = "Processed_files/GDU_capc.csv", 
                       header = TRUE, sep = ";")
names(GDU_capc)[2] = "1"

GDU_comprepfuera <- read.table(file = "Processed_files/GDU_comprepfuera.csv", 
                               header = TRUE, sep = ";")

GDU_mercado <- read.table(file = "Processed_files/GDU_mercado.csv", 
                          header = TRUE, sep = ";")
names(GDU_mercado)[2] = "1"
GDU_mercado[,2] <- GDU_mercado[,2]*1
  

GMF_art <- read.table(file = "Processed_files/GMF_art.csv", 
                      header = TRUE, sep = ";")

GMF_medpag <- read.table(file = "Processed_files/GMF_medpag.csv", 
                         header = TRUE, sep = ";")

GPU_comprepfuera <- read.table(file = "Processed_files/GPU_comprepfuera.csv", 
                               header = TRUE, sep = ";")

Viviendas_y_hogares <- read.csv("Processed_files/Viviendas y hogares.csv",sep=";")
Viviendas_y_hogares_Urbano<-Viviendas_y_hogares %>% filter(P3==1&!is.na(P3))

V <- c(97, 99, 100, 101, 102, 103, 104, 105)
for (i in V) {
  Viviendas_y_hogares_Urbano[,i] <- 
    as.numeric(gsub(",", ".", gsub("\\.", "", Viviendas_y_hogares_Urbano[,i])))
}


### Aggregate information by DIRECTORIO and Indicador (Variable
### which indicates the type of good bought), to generate the 
### monthly expenses of every house in every type of good

GDP <- GDP %>% group_by(DIRECTORIO, indicador) %>% 
  summarise(cuantos=length(indicador),Gasto=sum(Gto_mes))

GDU <- GDU %>% group_by(DIRECTORIO, indicador) %>% 
  summarise(cuantos=length(indicador),Gasto=sum(Gto_mes))
  
GDU_comprepfuera <- GDU_comprepfuera %>% group_by(DIRECTORIO, indicador) %>% 
  summarise(cuantos=length(indicador),Gasto=sum(Gto_mes))

GMF_art <- GMF_art %>% group_by(DIRECTORIO, indicador) %>% 
  summarise(cuantos=length(indicador),Gasto=sum(Gto_mes))
  
GPU_comprepfuera <- GPU_comprepfuera %>% group_by(DIRECTORIO, indicador) %>% 
  summarise(cuantos=length(indicador),Gasto=sum(Gto_mes))


### Transform from long to wide splitting by indicador

GDP <- GDP %>%  select(DIRECTORIO, indicador, Gasto) %>% 
  spread(indicador, Gasto, fill=0)

GDU <- GDU %>%  select(DIRECTORIO, indicador, Gasto) %>% 
  spread(indicador, Gasto, fill=0)

GDU_comprepfuera <- GDU_comprepfuera %>%  select(DIRECTORIO, indicador, Gasto) %>% 
  spread(indicador, Gasto, fill=0)

GMF_art <- GMF_art %>%  select(DIRECTORIO, indicador, Gasto) %>% 
  spread(indicador, Gasto, fill=0)

GPU_comprepfuera <- GPU_comprepfuera %>%  select(DIRECTORIO, indicador, Gasto) %>% 
  spread(indicador, Gasto, fill=0)



### Join all expenses to obtain one Data Frame containing monthly expenses
### of each house in each type of good

Gastos_TOTAL <- full_join(GDP, GDU, all=TRUE)
Gastos_TOTAL <- full_join(Gastos_TOTAL, GDU_capc, all=TRUE)
Gastos_TOTAL <- full_join(Gastos_TOTAL, GDU_comprepfuera, all=TRUE)
Gastos_TOTAL <- full_join(Gastos_TOTAL, GDU_mercado, all=TRUE)
Gastos_TOTAL <- full_join(Gastos_TOTAL, GMF_art, all=TRUE)
Gastos_TOTAL <- full_join(Gastos_TOTAL, GMF_medpag, all=TRUE)
Gastos_TOTAL <- full_join(Gastos_TOTAL, GPU_comprepfuera, all=TRUE)

Gastos_TOTAL[is.na(Gastos_TOTAL)] <- 0
Gastos_TOTAL <- aggregate(Gastos_TOTAL, 
                          by=list(Gastos_TOTAL$DIRECTORIO), FUN=sum, na.rm=TRUE) 
Gastos_TOTAL <- cbind(Gastos_TOTAL[1], Gastos_TOTAL[3:16])
names(Gastos_TOTAL)[1] = "DIRECTORIO"


### Extract important characteristics from the houses and households
### table

Viviendas_y_hogares_Urbano <- Viviendas_y_hogares_Urbano %>% 
  select(DIRECTORIO, REGION, DOMINIO, P3, P5747, P8520S1A1, P1647, P5010, P5090, P5100S4, P5110, 
         P5140, P5240, P5230, P6008, FEX_C, IT, ICGU, ICMUG, ICMDUG, GTUG, GCUG, GCMUG)
names(Viviendas_y_hogares_Urbano)[5:15] <- 
  c("TIPO_VIV", "ESTRATO", "NUM_CUARTOS", "DORMITORIOS", "PROPIEDAD_VIV",
    "PAGO_CUOTA_CASA", "ARRIENDO_IMPUT", "ARRIENDO", "INGRESOS_SUFICIENTES",
    "POBRE", "PERS_HOGAR")

Viviendas_y_hogares_Urbano <- Viviendas_y_hogares_Urbano %>% 
  mutate(ARRIENDO=ifelse(is.na(ARRIENDO),0,ARRIENDO)) %>%
  mutate(ARRIENDO_IMPUT=ifelse(is.na(ARRIENDO_IMPUT),0,ARRIENDO_IMPUT)) %>% 
  mutate(PAGO_CUOTA_CASA=ifelse(is.na(PAGO_CUOTA_CASA),0,PAGO_CUOTA_CASA)) %>%
  mutate(Gto_VIVIENDA = ifelse(ARRIENDO > 100, ARRIENDO, 
        ifelse(ARRIENDO_IMPUT > 100, ARRIENDO_IMPUT, PAGO_CUOTA_CASA))) %>%
  select(-c("ARRIENDO", "ARRIENDO_IMPUT", "PAGO_CUOTA_CASA"))


### Extract important characteristics from the general people 
### characteristics table

Caracteristicas_generales_personas <- Caracteristicas_generales_personas %>%
  select(DIRECTORIO, P6020, P6040, P6050, P6080, P6120, P6210, P6210S2, P1652S1A1, 
         P1652S2A1, P6500, P6800, P6920S1, P6990S1, P9450S1, FEX_C)
names(Caracteristicas_generales_personas) <- 
  c("DIRECTORIO", "GENERO", "EDAD", "PARENTEZCO", "ETNIA", "GTO_SALUD",
    "NIVEL_EDUCAT", "ULTIMO_DIPLOMA", "GTO_IMPTOS", "GTO_RETEFUENTE",
    "ING_EMPLEO", "HORAS DE TRABAJO", "GTO_PENSIONES", "GTO_ARL", 
    "GTO_CAJA_COMP", "FEX_C")

Caracteristicas_generales_personas <- Caracteristicas_generales_personas %>% 
  mutate(GTO_SALUD=ifelse(is.na(GTO_SALUD)|GTO_SALUD<100,0,GTO_SALUD)) %>%
  mutate(GTO_IMPTOS=ifelse(is.na(GTO_IMPTOS)|GTO_IMPTOS<100,0,GTO_IMPTOS)) %>% 
  mutate(GTO_RETEFUENTE=ifelse(is.na(GTO_RETEFUENTE)|GTO_RETEFUENTE<100,0,GTO_RETEFUENTE)) %>%
  mutate(GTO_PENSIONES=ifelse(is.na(GTO_PENSIONES)|GTO_PENSIONES<100,0,GTO_PENSIONES)) %>%
  mutate(GTO_ARL=ifelse(is.na(GTO_ARL)|GTO_ARL<100,0,GTO_ARL)) %>%
  mutate(GTO_CAJA_COMP=ifelse(is.na(GTO_CAJA_COMP)|GTO_CAJA_COMP<100,0,GTO_CAJA_COMP)) %>%
  mutate(Gto_EMPLEO = GTO_SALUD+GTO_IMPTOS+GTO_RETEFUENTE+GTO_PENSIONES+GTO_ARL+GTO_CAJA_COMP) %>%
  select(-c("GTO_SALUD", "GTO_IMPTOS", "GTO_RETEFUENTE", "GTO_PENSIONES", "GTO_ARL", "GTO_CAJA_COMP"))

CGP <- Caracteristicas_generales_personas %>% 
  select(c("DIRECTORIO", "GENERO", "ING_EMPLEO", "Gto_EMPLEO")) 
CGP$GENERO <- as.factor(CGP$GENERO)
str(CGP)
names(CGP)[1] = "DIRECTORIO"

CGP <- CGP %>% mutate(Hombres_HOGAR = ifelse(CGP$GENERO==1,1,0)) %>%
  mutate(Mujeres_HOGAR = ifelse(CGP$GENERO==2,1,0)) %>% 
  mutate(ING_EMPLEO_HOGAR = ING_EMPLEO) %>%
  mutate(Gto_EMPLEO_HOGAR = Gto_EMPLEO)


CGP <- select(CGP,c("DIRECTORIO","Hombres_HOGAR","Mujeres_HOGAR","ING_EMPLEO_HOGAR",
                        "Gto_EMPLEO_HOGAR")) %>% 
  mutate(ING_EMPLEO_HOGAR= ifelse(is.na(ING_EMPLEO_HOGAR), 
                                  0,ING_EMPLEO_HOGAR))
CGP <- aggregate(CGP, by=list(CGP$DIRECTORIO), FUN=sum, na.rm=TRUE) 
CGP <- cbind(CGP[1], CGP[3:6])
names(CGP)[1] = "DIRECTORIO"


JH <- Caracteristicas_generales_personas %>% filter(PARENTEZCO==1) %>%
  select(c("DIRECTORIO","GENERO","EDAD","ETNIA", "NIVEL_EDUCAT")) %>%
  mutate(GENERO_JH = ifelse(GENERO==1,"H","M")) %>% mutate(ETNIA_JH = ETNIA) %>%
  mutate(EDAD_JH = EDAD) %>% mutate(EDUCACION_JH = NIVEL_EDUCAT) %>%
  select(-c("GENERO","ETNIA","EDAD","NIVEL_EDUCAT"))
names(JH)[1] = "DIRECTORIO"

PERSONAS <- full_join(CGP, JH, all=TRUE)

### Create a table with the important household's and peoples's 
### characteristics
CARACTERISTICAS <- left_join(Viviendas_y_hogares_Urbano, PERSONAS)


rm(Caracteristicas_generales_personas, PERSONAS, CGP, GDP, GDU, GDU_capc,
   GDU_comprepfuera, GDU_mercado, GMF_art, GMF_medpag, GPU_comprepfuera,
   JH, Viviendas_y_hogares, Viviendas_y_hogares_Urbano)


### Join the montlhy expenditures with the characteristicas found 
### in the previous step
ENPH <- right_join(Gastos_TOTAL, CARACTERISTICAS)
names(ENPH)[2:15] = c("Gto_AlimyBeb_NA", "Gto_Beb_ATE", "Gto_ropa",
                      "Gto_transp", "Gto_IyC", "Gto_RyC", "Gto_Diversos",
                      "Gto_Aloj_Serv", "Gto_RestyHot", "Gto_ArtHogar",
                      "Gto_Salud", "Gto_Educ", "Gto_Viajes", "Gto_ServiciosP")
names(ENPH)[35] = "Gto_Arriendo"

### Calculate total monthly expenses
ENPH <- ENPH %>% select(-c(ICMUG, ICMDUG,GTUG, GCUG, GCMUG)) %>% 
  mutate(GASTO_TOTAL = Gto_AlimyBeb_NA + Gto_Beb_ATE + Gto_ropa +
           Gto_transp + Gto_IyC + Gto_RyC + Gto_Diversos +
           Gto_Aloj_Serv + Gto_RestyHot + Gto_ArtHogar + 
           Gto_Salud + Gto_Educ + Gto_ServiciosP +
           Gto_Arriendo + Gto_EMPLEO_HOGAR) 

### Select variables if interest
ENPH <- ENPH %>% select(c("DIRECTORIO", "REGION", "DOMINIO", "TIPO_VIV", "ESTRATO", "NUM_CUARTOS", 
                          "DORMITORIOS", "PROPIEDAD_VIV", "INGRESOS_SUFICIENTES", "POBRE", "PERS_HOGAR", 
                          "Hombres_HOGAR", "Mujeres_HOGAR", "GENERO_JH", "ETNIA_JH", "EDAD_JH", 
                          "EDUCACION_JH", "Gto_AlimyBeb_NA", "Gto_Beb_ATE", "Gto_ropa", "Gto_transp", 
                          "Gto_IyC", "Gto_RyC", "Gto_Diversos", "Gto_Aloj_Serv", "Gto_RestyHot", 
                          "Gto_ArtHogar", "Gto_Salud", "Gto_Educ", "Gto_ServiciosP", 
                          "Gto_Arriendo", "Gto_EMPLEO_HOGAR", "GASTO_TOTAL", "IT", "FEX_C"))

ENPH <- ENPH %>% mutate(Prop_Gto_AlimyBeb_NA = Gto_AlimyBeb_NA/GASTO_TOTAL) %>% 
  filter(Prop_Gto_AlimyBeb_NA!=0)


### Extract table found to a csv file called ENPH_FINAL
write.table(ENPH, file = "Processed_files/ENPH_FINAL.csv", 
            sep = ";", col.names = TRUE, row.names = FALSE)
