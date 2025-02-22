#' @title Processa dados das empresas agrícolas a partir do dataframe dos sócios que são parlamentares em exercício
#' @description A partir de um um dataframe contendo cnpj das empresas e os sócios,
#' filtra as que são agrícolas e adiciona novas informações
#' @param empresas_deputados Dataframe com as informações dos parlamentares sócios em empresas
#' @param somente_agricolas Flag para indicar se deve filtrar as empresas agrícolas ou não
#' @return Dataframe com informações dos sócios e das empresas agrícolas
fetch_socios_empresas_parlamentares <- function(
  empresas_deputados = here::here("parlametria/raw_data/empresas/empresas_parlamentares.csv"),
  somente_agricolas = FALSE) {
  library(tidyverse)
  
  source(here::here("parlametria/crawler/empresas/fetcher_empresas.R"))
  
  empresas_socios_agricolas <- 
    fetch_empresas(empresas_deputados, 
                   somente_agricolas)
  
  empresas_socios_agricolas <- empresas_socios_agricolas %>% 
    select(id_parlamentar = id, 
           cnpj, 
           nome_socio, 
           cnpj_cpf_do_socio, 
           percentual_capital_social, 
           data_entrada_sociedade)
  
  return(empresas_socios_agricolas)
}