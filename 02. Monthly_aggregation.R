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

########################################
### IMPORT DATA (using imputed data) ###
########################################

Viviendas_y_hogares <- read.csv("CSV/Viviendas y hogares.csv",sep=";")
Viviendas_y_hogares_Urbano <- Viviendas_y_hogares %>% filter(P3==1&!is.na(P3))

## Convert columns to numeric
V <- c(97, 99, 100, 101, 102, 103, 104, 105)
for (i in V) {
  Viviendas_y_hogares_Urbano[,i] <- 
    as.numeric(gsub(",", ".", gsub("\\.", "", Viviendas_y_hogares_Urbano[,i])))
}

## Drop special characteres from the REGION and DOMINIO variables
Viviendas_y_hogares_Urbano <- Viviendas_y_hogares_Urbano %>% 
  mutate(REGION = stri_trans_general(REGION, 'Latin-ASCII')) %>% 
  mutate(DOMINIO = stri_trans_general(DOMINIO, 'Latin-ASCII'))
rm(Viviendas_y_hogares)

Caracteristicas_generales_personas <- 
  read.csv("CSV/Caracteristicas generales personas.csv", sep=";")

Gastos_diarios_urbano_comidas_preparadas_fuera <-
  read.csv("CSV/GDU_comprepfuera_Imputados.csv")
Gastos_diarios_urbano_comidas_preparadas_fuera <- 
  Gastos_diarios_urbano_comidas_preparadas_fuera[2:16]

Gastos_diaros_personales_urbano <- read.csv("CSV/GDPU_Imputados.csv")
Gastos_diaros_personales_urbano <- Gastos_diaros_personales_urbano[2:16]

Gastos_diarios_urbano_capc <- 
  read.delim("CSV/Gastos diarios Urbano - Capitulo C.txt")
## Drop the registers that have no value of last purchase
## Or have 99 as value because in Colombia the minimum amount 
## of money in coins is 100 pesos
Gastos_diarios_urbano_capc <- 
  Gastos_diarios_urbano_capc %>% filter(!is.na(NC2_CC_P3_S1) & NC2_CC_P3_S1 >99)

Gastos_diarios_urbano_mercado <- 
  read.csv("CSV/Gastos diarios Urbanos - Mercados.csv", sep=";")
## Drop the registers that have no value of last purchase
## Or have 99 as value because in Colombia the minimum amount 
## of money in coins is 100 pesos
Gastos_diarios_urbano_capc <- 
Gastos_diarios_urbano_mercado <- 
  Gastos_diarios_urbano_mercado %>% filter(!is.na(NC2_CC_P4S1) & NC2_CC_P4S1 >99)

Gastos_diarios_urbanos <- 
  read.csv("CSV/Gastos_diarios_urbanos_Imputados.csv")
Gastos_diarios_urbanos <- Gastos_diarios_urbanos[2:16]

Gastos_menos_frecuentes_articulos <- 
  read.csv("CSV/Gastos_menos_frecuentes_articulos_Imputados.csv")
Gastos_menos_frecuentes_articulos <- 
  Gastos_menos_frecuentes_articulos[2:15]

Gastos_menos_frecuentes_medpag <- 
  read.csv("CSV/Gastos menos frecuentes - Medio de pago.csv", sep=";")

Gastos_personales_urbano_comidas_preparadas_fuera <-
  read.csv("CSV/GPU_comprepfuera_Imputados.csv")
Gastos_personales_urbano_comidas_preparadas_fuera <- 
  Gastos_personales_urbano_comidas_preparadas_fuera[2:16]

####################################################
######### CALCULATE MONTLHY EXPENDITURES ###########
####################################################

## Using the montlhy factors available in the survey manual, 
## the expenses are transformed to monthly expenses

### HOUSEHOLD DAILY ESPENSES ###
aux_fun<-function(x,y){
  ltable<-c("1"=2.14,"2"=2.14,"3"=2.14,"4"=2,"5"=1,"6"=1/2,"7"=1/3,"9"=1)
  aux<-ltable[as.character(x)]
  aux*y
}


Gastos_diarios_urbano_capc <- Gastos_diarios_urbano_capc %>% 
  mutate(Gto_mes=aux_fun(NC2_CC_P2,NC2_CC_P3_S1)) 

Gastos_diarios_urbanos <- Gastos_diarios_urbanos%>% 
  mutate(Gto_mes=aux_fun(NH_CGDU_P9,NH_CGDU_P8)) 


### Personal daily expenses and food prepared outside the house

aux_fun2<-function(x,y){
  ltable<-c("1"=4.28,"2"=4.28,"3"=4.28,"4"=2,"5"=1,"6"=1/2,"7"=1/3,"9"=1)
  aux<-ltable[as.character(x)]
  aux*y
}

Gastos_diarios_urbano_comidas_preparadas_fuera <- 
  Gastos_diarios_urbano_comidas_preparadas_fuera %>% 
  mutate(Gto_mes=aux_fun2(NH_CGDUCFH_P6,NH_CGDUCFH_P5)) 


Gastos_diaros_personales_urbano <- Gastos_diaros_personales_urbano %>% 
  mutate(Gto_mes=aux_fun2(NC4_CC_P6,NC4_CC_P5)) 


Gastos_personales_urbano_comidas_preparadas_fuera <- 
  Gastos_personales_urbano_comidas_preparadas_fuera %>% 
  mutate(Gto_mes=aux_fun2(NH_CGPUCFH_P6,NH_CGPUCFH_P5)) 



#### Less frequent expenses ###

# For this particular chapter, the monthly factor is available for
# groups of expenses, so we need to divide the data frame in those groups
# to apply the right factor
Gastos_menos_frecuentes_articulos1 <- 
  Gastos_menos_frecuentes_articulos %>%
  filter(CAP=="A11" | CAP=="B11" | CAP=="F11" | CAP=="E11"| CAP=="H11"| 
                         CAP=="J11"| CAP=="L11" | CAP=="K11"| CAP=="C11")

aux_fun3<-function(x,y){
  ltable<-c("3"=1,"4"=1,"5"=1,"6"=1/2,"7"=1/3,"8"=1/12,"9"=1,"10"=1/6)
  aux<-ltable[as.character(x)]
  aux*y
}

Gastos_menos_frecuentes_articulos1 <- 
  Gastos_menos_frecuentes_articulos1 %>% 
  mutate(Gto_mes=aux_fun3(P10270S3,Pago)) 

Gastos_menos_frecuentes_articulos2 <- 
  Gastos_menos_frecuentes_articulos %>% 
  filter(CAP=="D11" | CAP=="D12" | CAP=="J12" 
         | CAP=="G11" | CAP=="F12" | CAP=="D14"
         | CAP=="I11" | CAP=="D16" | CAP=="D15" 
         | CAP=="D13" )

aux_fun4<-function(x,y){
  ltable<-c("3"=1/3,"4"=1/3,"5"=1/3,"6"=1/3,"7"=1,"8"=1/4,"9"=1,"10"=1/2)
  aux<-ltable[as.character(x)]
  aux*y
}

Gastos_menos_frecuentes_articulos2 <- 
  Gastos_menos_frecuentes_articulos2 %>% 
  mutate(Gto_mes=aux_fun4(P10270S3,Pago)) 

Gastos_menos_frecuentes_articulos3 <- 
  Gastos_menos_frecuentes_articulos %>% 
  filter(CAP!="A11" | CAP!="B11" | CAP!="F11" | CAP!="E11"| CAP!="H11"|
           CAP!="J11"| CAP!="L11" | CAP!="K11"| CAP!="C11" |CAP!="D11"|
           CAP!="D12" | CAP!="J12" | CAP!="G11"| CAP!="F12"| 
           CAP!="D14"| CAP!="I11" | CAP!="D16"| CAP!="D15" | CAP!="D13")

aux_fun5<-function(x,y){
  ltable<-c("3"=1/12,"4"=1/12,"5"=1/12,"6"=1/12,"7"=1/12,"8"=1/12,"9"=1/12,"10"=1/12)
  aux<-ltable[as.character(x)]
  aux*y
}

Gastos_menos_frecuentes_articulos3 <- 
  Gastos_menos_frecuentes_articulos3 %>% 
  mutate(Gto_mes=aux_fun5(P10270S3,Pago)) 


Gastos_menos_frecuentes_articulos <- 
  rbind(Gastos_menos_frecuentes_articulos1,
        Gastos_menos_frecuentes_articulos2,
        Gastos_menos_frecuentes_articulos3)


### Daily Expenditures of Urban Households in market purchases ###
# This particular chapter already have the montlhy expenses

Gastos_diarios_urbano_mercado <- Gastos_diarios_urbano_mercado %>%
  mutate(Gto_mes=NC2_CC_P4S1)



### Drop not used Data Frames ###
rm(Gastos_menos_frecuentes_articulos1)
rm(Gastos_menos_frecuentes_articulos2)
rm(Gastos_menos_frecuentes_articulos3)


### Aggregate expenses by DIRECTORIO variable ###
length(unique(Gastos_diarios_urbano_capc$DIRECTORIO))

GDU_capc <- Gastos_diarios_urbano_capc %>% 
            group_by(DIRECTORIO) %>% 
            summarise(Gto_CapC=sum(Gto_mes))

Gastos_diarios_urbano_mercado [,7] <-
  as.numeric(gsub(",", ".", gsub("\\.", "", Gastos_diarios_urbano_mercado$FEX_C)))

GDU_mercado <- 
  as.data.frame(cbind(Gastos_diarios_urbano_mercado$DIRECTORIO,
                      Gastos_diarios_urbano_mercado$NC2_CC_P4S1))
names(GDU_mercado) = c("DIRECTORIO", "Gto_mercados")


GMF_medpag <- Gastos_menos_frecuentes_medpag %>%
  mutate(Acueducto=P10272S1A1/P10272S1A2) %>%
  mutate(Basuras_Aseo=P10272S2A1/P10272S2A2) %>%
  mutate(Alcantarillado=P10272S3A1/P10272S3A2) %>% 
  mutate(Energia=P10272S4A1/P10272S4A2) %>%
  mutate(Alumbrado=P10272S5A1/P10272S5A2) %>%
  mutate(GasN_Tuberia=P10272S6A1/P10272S6A2) %>%
  mutate(Telefono_fijo=P10272S7A1/P10272S7A2) %>%
  mutate(Internet_fijo=P10272S8A1/P10272S8A2) %>%
  mutate(TV=P10272S9A1/P10272S9A2) %>%
  mutate(Viajes=P3J1324)
GMF_medpag[is.na(GMF_medpag)] <- 0

GMF_medpag <- GMF_medpag %>%
    mutate(Servicios=Acueducto+Basuras_Aseo+Alcantarillado+Energia+
           Alumbrado+GasN_Tuberia+Telefono_fijo+Internet_fijo+TV) %>% 
  select(DIRECTORIO, Viajes, Servicios)#, FEX_C)
names(GMF_medpag)[1] = "DIRECTORIO"

rm(Gastos_diarios_urbano_capc)
rm(Gastos_diarios_urbano_mercado)
rm(Gastos_menos_frecuentes_medpag)


GDU_comprepfuera <- Gastos_diarios_urbano_comidas_preparadas_fuera %>%
  select(DIRECTORIO, Gto_mes, indicador)
rm(Gastos_diarios_urbano_comidas_preparadas_fuera)

GDU <- Gastos_diarios_urbanos %>% 
  select(DIRECTORIO ,Gto_mes, indicador)
rm(Gastos_diarios_urbanos)

GDP <- Gastos_diaros_personales_urbano %>% 
  select(DIRECTORIO,Gto_mes,indicador)
rm(Gastos_diaros_personales_urbano)

GPU_comprepfuera <- Gastos_personales_urbano_comidas_preparadas_fuera %>%
  select(DIRECTORIO,Gto_mes,indicador)
rm(Gastos_personales_urbano_comidas_preparadas_fuera)

GMF_art <- Gastos_menos_frecuentes_articulos %>%
  select(DIRECTORIO ,Gto_mes, indicador)
rm(Gastos_menos_frecuentes_articulos)


##########################################
#### SAVE FILES WITH MONTHLY EXPENSES ####
##########################################

write.table(Caracteristicas_generales_personas, 
            file = "Processed_files/Caracteristicas_generales_personas.csv", 
            sep = ";", col.names = TRUE, row.names = FALSE)

write.table(GDP, 
            file = "Processed_files/GDP.csv", 
            sep = ";", col.names = TRUE, row.names = FALSE)

write.table(GDU, 
            file = "Processed_files/GDU.csv", 
            sep = ";", col.names = TRUE, row.names = FALSE)

write.table(GDU_capc, 
            file = "Processed_files/GDU_capc.csv", 
            sep = ";", col.names = TRUE, row.names = FALSE)

write.table(GDU_comprepfuera, 
            file = "Processed_files/GDU_comprepfuera.csv", 
            sep = ";", col.names = TRUE, row.names = FALSE)

write.table(GDU_mercado, 
            file = "Processed_files/GDU_mercado.csv", 
            sep = ";", col.names = TRUE, row.names = FALSE)

write.table(GMF_art, 
            file = "Processed_files/GMF_art.csv", 
            sep = ";", col.names = TRUE, row.names = FALSE)

write.table(GMF_medpag, 
            file = "Processed_files/GMF_medpag.csv", 
            sep = ";", col.names = TRUE, row.names = FALSE)

write.table(GPU_comprepfuera, 
            file = "Processed_files/GPU_comprepfuera.csv", 
            sep = ";", col.names = TRUE, row.names = FALSE)

write.table(Viviendas_y_hogares_Urbano, 
            file = "Processed_files/Viviendas_y_hogares_Urbano.csv", 
            sep = ";", col.names = TRUE, row.names = FALSE)


