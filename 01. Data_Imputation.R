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
########## DATA MANIPULATION #################
##############################################

## Import daily personal expenditures
GDPU_I <- read.csv("CSV/Gastos diarios personales Urbano.csv", sep=";")
## Filter for those who has zero or no value in the variable 
## how much was paid for the good
GDPU_I <- GDPU_I%>%
  filter(!is.na(NC4_CC_P5)) %>% filter(NC4_CC_P5!=0) 
## Select variables Name of the good, amount, acquisition format, 
## amount payed, frequency and expansion factor
GDPU_I <- GDPU_I%>%
  select(DIRECTORIO,NC4_CC_P1_1, NC4_CC_P2, NC4_CC_P3, NC4_CC_P5, NC4_CC_P6, FEX_C)
## Convert into numeric the variables amount payed and expansion factor, 
## but first change comma by period.
GDPU_I[,3]<-as.numeric(gsub(",", ".", gsub("\\.", "", GDPU_I$NC4_CC_P2)))
GDPU_I[,7]<-as.numeric(gsub(",", ".", gsub("\\.", "", GDPU_I$FEX_C)))



## Import daily Urban household expenditures - Food prepared outside home
GDUCPF_I <-read.csv("CSV/Gastos diarios del hogar Urbano - Comidas preparadas fuera del hogar.csv", sep=";")
## Filter for those who has zero or no value in the variable 
## how much was paid for the good
GDUCPF_I <-GDUCPF_I %>%
  filter(!is.na(NH_CGDUCFH_P5)) %>% filter(NH_CGDUCFH_P5!=0) 
## Select variables COICOP code, type of food, quantity, how much was paid, 
## frequency, type of expenditure, and expansion factor
GDUCPF_I <- GDUCPF_I %>%
  select(DIRECTORIO,NH_CGDUCFH_P1_1, NH_CGDUCFH_P1_2, NH_CGDUCFH_P2,NH_CGDUCFH_P5,
          NH_CGDUCFH_P6,NH_CGDUCFH_P7, FEX_C)
## Convert as numeric type of food, quantity and expansion factor,
## but first change comma by period.
GDUCPF_I[,3]<-as.numeric(gsub(",", ".", gsub("\\.", "", GDUCPF_I$NH_CGDUCFH_P1_2)))
GDUCPF_I[,4]<-as.numeric(gsub(",", ".", gsub("\\.", "", GDUCPF_I$NH_CGDUCFH_P2)))
GDUCPF_I[,8]<-as.numeric(gsub(",", ".", gsub("\\.", "", GDUCPF_I$FEX_C)))


## Import Personal urban expenditures - Food prepared outside home
GPUCPF_I <-read.csv("CSV/Gastos personales Urbano - Comidas preparadas fuera del Hogar.csv", sep=";")
## Filter for those who has zero or no value in the variable 
## how much was paid for the good
GPUCPF_I <- GPUCPF_I %>%
  filter(NH_CGPUCFH_P5 >= 50) %>% filter(!between(NH_CGPUCFH_P5,51,99)) 
## Select variables COICOP code, type of food, quantity, how much was paid, 
## frequency, and expansion factor
GPUCPF_I <- GPUCPF_I %>%
  select(DIRECTORIO, NH_CGPUCFH_P1_S1, NH_CGPUCFH_P1_S2, NH_CGPUCFH_P2,
          NH_CGPUCFH_P5, NH_CGPUCFH_P6, FEX_C)
## Convert as numeric type of how much was paid and expansion factor
GPUCPF_I[,4]<-as.numeric(gsub(",", ".", gsub("\\.", "", GPUCPF_I$NH_CGPUCFH_P2)))
GPUCPF_I[,7]<-as.numeric(gsub(",", ".", gsub("\\.", "", GPUCPF_I$FEX_C)))


## Import houses and households
VYH <- read.csv("CSV/Viviendas y hogares.csv",sep=";")

## Filter only urban houses
VYHU_I <-VYH %>% filter(P3==1&!is.na(P3))
## Select variables of interest 
VYHU_I <- select(VYHU_I, DIRECTORIO, REGION, 
                 DOMINIO, P448, P811, P8520S1, P8520S1A1,
                 P8520S2, P8520S3, P8520S4, P8520S5, P1647, P5010,
                 P814, P5070, P5160, P5090, P5230, P1646S1,
                 P1646S2, P1646S3, P1646S4, P1646S5, P1646S6,
                 P1646S7, P1646S8, P1646S9, P1646S10, P1646S11,
                 P1646S12, P1646S13, P1646S14, P1646S15, P1646S16,
                 P1646S17, P1646S18, P1646S19, P1646S20, P1646S21,
                 P1646S22, P1646S23, P1646S24, P1646S25, P1646S26,
                 P1646S27, P1646S28, P1646S29, P1646S30, P6008, FEX_C,
                 IT, ICGU, ICMUG, ICMDUG, GTUG, GCUG, GCMUG)
## Convert as numeric variables of interest,
## but first change comma by period
V <- c(50, 51, 52, 53, 54, 55, 56, 57)
for (i in V) {
  VYHU_I [,i]<-as.numeric(gsub(",", ".", gsub("\\.", "", VYHU_I[,i])))
}


################################################################
### Join Houses and Households with Urban Daily expenditures ###

GDU_comprepfuera_IM <- left_join(GDUCPF_I, VYHU_I) 
rm(GDUCPF_I)

## Transform into character DOMINIO and REGION variables 
GDU_comprepfuera_IM$DOMINIO<-as.character(GDU_comprepfuera_IM$DOMINIO)
GDU_comprepfuera_IM$REGION<-as.character(GDU_comprepfuera_IM$REGION)

## Create a new variable called indicador, which codes the COICOP code as
## the first number to work with the food category 
GDU_comprepfuera_IM <- GDU_comprepfuera_IM %>% 
  mutate(indicador=ifelse(NH_CGDUCFH_P1_1 %in% 1000000:1999999,1,
                          ifelse(NH_CGDUCFH_P1_1 %in% 2000000:2999999,2,
                                 ifelse(NH_CGDUCFH_P1_1 %in% 3000000:3999999,3, 
                                        ifelse(NH_CGDUCFH_P1_1 %in% 4000000:4999999,4, 
                                               ifelse(NH_CGDUCFH_P1_1 %in% 5000000:5999999,5, 
                                                      ifelse(NH_CGDUCFH_P1_1 %in% 6000000:6999999,6,
                                                             ifelse(NH_CGDUCFH_P1_1 %in% 7000000:7999999,7, 
                                                                    ifelse(NH_CGDUCFH_P1_1 %in% 8000000:8999999,8,
                                                                           ifelse(NH_CGDUCFH_P1_1 %in% 9000000:9999999,9,
                                                                                  ifelse(NH_CGDUCFH_P1_1 %in% 10000000:10999999,10,
                                                                                         ifelse(NH_CGDUCFH_P1_1 %in% 11000000:11999999,11,12)))))))))))) 


### Select variables of interest 
GDU_comprepfuera_IM <- GDU_comprepfuera_IM %>% select(DIRECTORIO, indicador, NH_CGDUCFH_P1_2, NH_CGDUCFH_P2,
            NH_CGDUCFH_P2,NH_CGDUCFH_P5, NH_CGDUCFH_P6,REGION, DOMINIO, P8520S1A1, 
            P5160, P5090, P5230, P6008, IT, GTUG) 

### Clean the Spanish special codes, as the database 
### has tildes and Ñ, when uploading the data to R, we create 
### weird characters, we need to fix the problems
GDU_comprepfuera_IM <- GDU_comprepfuera_IM %>% 
  mutate(REGION = stri_trans_general(REGION, 'Latin-ASCII')) %>% 
  mutate(DOMINIO = stri_trans_general(DOMINIO, 'Latin-ASCII'))


### Transform variables to factor
R <- c(2, 4, 6, 7, 8, 9, 10, 11, 12)
for (i in R) {
  GDU_comprepfuera_IM[,i] <- 
    as.factor(GDU_comprepfuera_IM[,i])
}

## Now we select the Parallelize commands of the imputation method to
## improve the time of computing
doParallel::registerDoParallel(cores = 4)
doRNG::registerDoRNG(seed = 123)

## Using the missForest package, we impute missing values 
GDU_comprepfuera_Imputados <- missForest(GDU_comprepfuera_IM, verbose = T, 
                                         parallelize = "forest")  
## Extract estimation errors
GDU_comprepfuera_Imputados$OOBerror

## Extract the imputed data to a csv file to use later
write.csv(GDU_comprepfuera_Imputados$ximp, file="CSV/GDU_comprepfuera_Imputados.csv")


##########################################################
#### Join Houses and Urban Personal daily expenditures ###
GDPU_IM <- left_join(GDPU_I, VYHU_I)
rm(GDPU_I)

## Transform into character DOMINIO and REGION variables 
GDPU_IM$DOMINIO<-as.character(GDPU_IM$DOMINIO)
GDPU_IM$REGION<-as.character(GDPU_IM$REGION)

## Create a new variable called indicador, which codes the COICOP code as
## the first number to work with the food category 
GDPU_IM <- GDPU_IM %>% 
  mutate(indicador=ifelse(NC4_CC_P1_1 %in% 1000000:1999999,1,
                          ifelse(NC4_CC_P1_1 %in% 2000000:2999999,2,
                                 ifelse(NC4_CC_P1_1 %in% 3000000:3999999,3, 
                                        ifelse(NC4_CC_P1_1 %in% 4000000:4999999,4, 
                                               ifelse(NC4_CC_P1_1 %in% 5000000:5999999,5, 
                                                      ifelse(NC4_CC_P1_1 %in% 6000000:6999999,6,
                                                             ifelse(NC4_CC_P1_1 %in% 7000000:7999999,7, 
                                                                    ifelse(NC4_CC_P1_1 %in% 8000000:8999999,8,
                                                                           ifelse(NC4_CC_P1_1 %in% 9000000:9999999,9,
                                                                                  ifelse(NC4_CC_P1_1 %in% 10000000:10999999,10,
                                                                                         ifelse(NC4_CC_P1_1 %in% 11000000:11999999,11,12)))))))))))) 

### Select variables of interest 
GDPU_IM <- GDPU_IM %>% select( DIRECTORIO, indicador, NC4_CC_P2, NC4_CC_P3,
            NC4_CC_P5, NC4_CC_P6, REGION, DOMINIO, P8520S1A1, 
            P5160, P5090, P5230, P6008, IT, GTUG) 

### Clean the Spanish special codes, as the database 
### has tildes and Ñ, when uploading the data to R, we create 
### weird characters, we need to fix the problems
GDPU_IM <- GDPU_IM %>% 
  mutate(REGION = stri_trans_general(REGION, 'Latin-ASCII')) %>% 
  mutate(DOMINIO = stri_trans_general(DOMINIO, 'Latin-ASCII'))


### Transform variables to factor
R <- c(2, 4, 6, 7, 8, 9, 10, 11, 12)
for (i in R) {
  GDPU_IM [,i] <- 
    as.factor(GDPU_IM [,i])
}


## Using the missForest package, we impute missing values 
GDPU_Imputados <- missForest(GDPU_IM, verbose = T, 
                             parallelize = "forest")  

## Extract estimation errors
GDPU_Imputados$OOBerror

## Extract the imputed data to a csv file to use later
write.csv(GDPU_Imputados$ximp, file="CSV/GDPU_Imputados.csv")



########################################################
### Join Houses and Households with GPU_Comprepfuera ###

GPU_comprepfuera_IM <- left_join(GPUCPF_I, VYHU_I) 
rm(GPUCPF_I)

## Transform into character DOMINIO and REGION variables 
GPU_comprepfuera_IM$DOMINIO<-as.character(GPU_comprepfuera_IM$DOMINIO)
GPU_comprepfuera_IM$REGION<-as.character(GPU_comprepfuera_IM$REGION)

## Create a new variable called indicador, which codes the COICOP code as
## the first number to work with the food category 
GPU_comprepfuera_IM <- GPU_comprepfuera_IM %>% 
  mutate(indicador=ifelse(NH_CGPUCFH_P1_S1 %in% 1000000:1999999,1,
                          ifelse(NH_CGPUCFH_P1_S1 %in% 2000000:2999999,2,
                                 ifelse(NH_CGPUCFH_P1_S1 %in% 3000000:3999999,3, 
                                        ifelse(NH_CGPUCFH_P1_S1 %in% 4000000:4999999,4, 
                                               ifelse(NH_CGPUCFH_P1_S1 %in% 5000000:5999999,5, 
                                                      ifelse(NH_CGPUCFH_P1_S1 %in% 6000000:6999999,6,
                                                             ifelse(NH_CGPUCFH_P1_S1 %in% 7000000:7999999,7, 
                                                                    ifelse(NH_CGPUCFH_P1_S1 %in% 8000000:8999999,8,
                                                                           ifelse(NH_CGPUCFH_P1_S1 %in% 9000000:9999999,9,
                                                                                  ifelse(NH_CGPUCFH_P1_S1 %in% 10000000:10999999,10,
                                                                                         ifelse(NH_CGPUCFH_P1_S1 %in% 11000000:11999999,11,12)))))))))))) 


### Select variables of interest 
GPU_comprepfuera_IM <- GPU_comprepfuera_IM %>% select(DIRECTORIO, indicador, NH_CGPUCFH_P1_S2, NH_CGPUCFH_P2,
            NH_CGPUCFH_P5, NH_CGPUCFH_P6, REGION, DOMINIO, P8520S1A1, 
            P5160, P5090, P5230, P6008, IT, GTUG) 

### Clean the Spanish special codes, as the database 
### has tildes and Ñ, when uploading the data to R, we create 
### weird characters, we need to fix the problems
GPU_comprepfuera_IM <- GPU_comprepfuera_IM %>% 
  mutate(REGION = stri_trans_general(REGION, 'Latin-ASCII')) %>% 
  mutate(DOMINIO = stri_trans_general(DOMINIO, 'Latin-ASCII'))

### Transform variables to factor
R <- c(2, 3, 6, 7, 8, 9, 10, 11, 12)
for (i in R) {
  GPU_comprepfuera_IM[,i] <- 
    as.factor(GPU_comprepfuera_IM[,i])
}


## Using the missForest package, we impute missing values 
GPU_comprepfuera_Imputados <- missForest(GPU_comprepfuera_IM,verbose = T, parallelize = "forest")  

## Extract estimation errors
GPU_comprepfuera_Imputados$OOBerror

## Extract the imputed data to a csv file to use later
write.csv(GPU_comprepfuera_Imputados$ximp, file="CSV/GPU_comprepfuera_Imputados.csv")


