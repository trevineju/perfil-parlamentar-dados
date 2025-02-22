#' @title Processa dados de receitas dos parlamentares
#' @description A partir de um csv das receitas dos parlamentares processa e sumariza os dados
#' @param datapath Caminho para os dados de receitas
#' @param candidatos_datapath Caminho para os dados de candidatos nas eleições de 2018
#' @return Dataframe
#' @examples
#' doacoes <- processa_doacoes_partidarias_tse()
#' 
#' Observações 
#' 1. Consideramos apenas doações nas quais a origem de Receita é proveniente de Recursos de partido político
#' 2. Os candidatos que situação de candidatura APTO e DEFERIDO (com recurso ou não) são considerados. 
#' Atribuímos 0 se não existirem receitas mas o candidato ainda participou da eleição
#' 3. Consideramos apenas as doações do mesmo partido do candidato na eleição.
processa_doacoes_partidarias_tse <- 
  function(receitas_datapath = here::here("parlametria/raw_data/dados_tse/receitas_candidatos_2018_BRASIL.csv.zip"),
           candidatos_datapath = here::here("parlametria/raw_data/dados_tse/consulta_cand_2018_BRASIL.csv.zip")) {
    
  library(tidyverse)
    
  candidatos <- read_delim(candidatos_datapath, delim = ";", col_types = cols(SQ_CANDIDATO = "c"),
                           locale = locale(encoding = 'latin1')) %>% 
    filter(DS_SITUACAO_CANDIDATURA == "APTO") %>% 
    filter(DS_DETALHE_SITUACAO_CAND %in% c("DEFERIDO", "DEFERIDO COM RECURSO")) %>% 
    select(DS_CARGO, SG_UE, SQ_CANDIDATO, NM_CANDIDATO, NR_CPF_CANDIDATO, SG_PARTIDO) %>% 
    mutate(DS_CARGO = str_to_title(DS_CARGO)) %>% 
    filter(DS_CARGO %in% c("Deputado Federal", "Senador"))
    
  receitas <- read_delim(receitas_datapath, delim = ";", col_types = cols(SQ_CANDIDATO = "c", VR_RECEITA = "c"),
                         locale = locale(encoding = 'latin1')) %>% 
    select(DS_CARGO, SG_UE, SQ_CANDIDATO, NM_CANDIDATO, NR_CPF_CANDIDATO, SG_PARTIDO, 
           DS_FONTE_RECEITA, DS_ORIGEM_RECEITA, NM_DOADOR, NM_DOADOR_RFB, SG_PARTIDO_DOADOR, VR_RECEITA) %>% 
    mutate(VR_RECEITA = as.numeric(gsub(",", ".", VR_RECEITA)))
  
  receitas_filtradas <- receitas %>% 
    filter(DS_CARGO %in% c("Deputado Federal", "Senador"),
           SG_PARTIDO == SG_PARTIDO_DOADOR) %>% 
    filter(trimws(DS_ORIGEM_RECEITA, which = "both") == "Recursos de partido político")
  
  receitas_group <- receitas_filtradas %>% 
    group_by(SQ_CANDIDATO) %>% 
    summarise(total_receita = sum(VR_RECEITA))
  
  candidatos_receita <- candidatos %>% 
    left_join(receitas_group, by = c("SQ_CANDIDATO")) %>% 
    mutate(total_receita = if_else(is.na(total_receita), 0, as.numeric(total_receita))) %>% 
    select(id_tse = SQ_CANDIDATO, cargo = DS_CARGO, uf = SG_UE, partido = SG_PARTIDO, nome = NM_CANDIDATO,
           cpf = NR_CPF_CANDIDATO, total_receita)
  
  return(candidatos_receita)
  }


#' @title Importa dados de receitas dos candidatos em eleições anteriores a 2018 (usa o formato antigo dos dados do TSE)
#' @description Importa usando o formato antigo dos dados do TSE os dados de receitas dos candidatos
#' @param datapath Caminho para os dados de receita (.txt)
#' @return Dataframe contendo receitas dos candidatos com colunas específicas
#' @examples
#' receitas <- import_receita_tse_modelo_antigo()
import_receita_tse_modelo_antigo <- function(datapath = here::here("parlametria/raw_data/dados_tse/receitas_candidatos_2014_brasil.txt.zip")) {
  library(tidyverse)
  library(here)
  
  receita_tse <- read_delim(datapath, delim = ";", 
                            col_types = cols(`Sequencial Candidato` = "c", `Valor receita` = "c"), 
                            locale = locale(encoding = 'latin1')) %>% 
    select(SQ_CANDIDATO = `Sequencial Candidato`, NR_CPF_CNPJ_DOADOR = `CPF/CNPJ do doador`,
           NM_DOADOR = `Nome do doador`, NM_DOADOR_RFB = `Nome do doador (Receita Federal)`,
           DS_ORIGEM_RECEITA = `Tipo receita`, VR_RECEITA = `Valor receita`)
  
  return(receita_tse)
}

#' @title Processa dados de receitas dos candidatos em 2018 para Deputado e Senador
#' @description Sumariza dados de receitas e apresenta os doadores para a campanha do candidato. 
#' Esse tratamento é realizado tendo como entrada os dados do TSE de declaração dos bens do candidato.
#' @param receitas_datapath Caminho para os dados de receitas
#' @param candidatos_datapath Caminho para os dados de candidatos nas eleições de 2018
#' @param ano Ano da eleição
#' @return Dataframe contendo doações feitas por partidos, candidatos e pessoas físicas para os candidatos em 2018
#' @examples
#' doacoes <- processa_doacoes_tse()
#' Foram filtrados os candidatos apenas dos cargos de Senador e Deputado Federal.
#' Obs: Assume que os dados de receitas e  candidatos estão disponíveis. Esses dados pode ser baixados 
#' através do script ./fetcher_receitas_tse.sh
processa_doacoes_tse <- function(
  receitas_datapath = here::here("parlametria/raw_data/dados_tse/receitas_candidatos_2018_BRASIL.csv.zip"),
  candidatos_datapath = here::here("parlametria/raw_data/dados_tse/consulta_cand_2018_BRASIL.csv.zip"),
  ano = 2018,
  summarized = TRUE) {
  
  library(tidyverse)
  library(here)
  
  candidatos <- read_delim(candidatos_datapath, delim = ";", col_types = cols(SQ_CANDIDATO = "c"),
                           locale = locale(encoding = 'latin1')) %>% 
    filter(DS_SITUACAO_CANDIDATURA == "APTO") %>% 
    filter(DS_DETALHE_SITUACAO_CAND %in% c("DEFERIDO", "DEFERIDO COM RECURSO")) %>% 
    select(DS_CARGO, SG_UE, SQ_CANDIDATO, NM_CANDIDATO, NM_URNA_CANDIDATO, NR_CPF_CANDIDATO, SG_PARTIDO) %>% 
    mutate(DS_CARGO = str_to_title(DS_CARGO)) %>% 
    filter(DS_CARGO %in% c("Deputado Federal", "Senador"))
  
  if (ano == 2018) {
    receitas <- read_delim(receitas_datapath, delim = ";", col_types = cols(SQ_CANDIDATO = "c", VR_RECEITA = "c"),
                           locale = locale(encoding = 'latin1')) %>% 
      select(SQ_CANDIDATO, NR_CPF_CNPJ_DOADOR, NM_DOADOR, NM_DOADOR_RFB, DS_ORIGEM_RECEITA, VR_RECEITA) %>% 
      mutate(VR_RECEITA = as.numeric(gsub(",", ".", VR_RECEITA)))
  } else {
    receitas <- import_receita_tse_modelo_antigo(receitas_datapath) %>% 
      mutate(VR_RECEITA = as.numeric(gsub(",", ".", VR_RECEITA)))
  }
  
  if (summarized) {
    receitas <- receitas %>% 
      group_by(SQ_CANDIDATO, NR_CPF_CNPJ_DOADOR) %>% 
      summarise(
        NM_DOADOR = first(NM_DOADOR),
        NM_DOADOR_RFB = first(NM_DOADOR_RFB),
        DS_ORIGEM_RECEITA = first(DS_ORIGEM_RECEITA),
        VR_RECEITA = sum(VR_RECEITA)
        )
    
    candidatos <- candidatos %>% 
      select(-NM_URNA_CANDIDATO)
  }
  
  candidatos_doacoes <- candidatos %>% 
    left_join(receitas, by = c("SQ_CANDIDATO")) %>% 
    mutate(VR_RECEITA = if_else(is.na(VR_RECEITA), 0, as.numeric(VR_RECEITA)))
  
  return(candidatos_doacoes)
}

#' @title Processa dados de receitas de parlamentares (deputados ou senadores) em exercício
#' @description Recupera informações dos doadores para a campanha dos parlamentares nas eleições de 2018
#' @param ano Ano da eleição. Pode ser 2018 ou 2014.
#' @param casa_origem Casa de origem do parlamentar. Pode ser camara ou senado.
#' @return Dataframe contendo doações feitas por partidos, candidatos e pessoas físicas e/ou jurídicas para os parlamentares
#' @examples
#' parlamentares_doadores <- filtra_doacoes_parlamentares_exercicio(2018, "camara")
filtra_doacoes_parlamentares_exercicio <- function(ano = 2018, casa_origem = "camara") {
  library(tidyverse)
  library(here)
  source(here("parlametria/crawler/receitas/utils_receitas.R"))
  
  if(ano == 2018) {
    receitas_datapath <- .DATAPATH_RECEITA_TSE_2018
    candidatos_datapath <- .DATAPATH_CANDIDATOS_TSE_2018
  } else if (ano == 2014) {
    receitas_datapath <- .DATAPATH_RECEITA_TSE_2014
    candidatos_datapath <- .DATAPATH_CANDIDATOS_TSE_2014
  } else {
    stop("Ano não disponível para captura dos dados de receita")
  }
  
  receitas_datapath <- here(receitas_datapath)
  candidatos_datapath <- here(candidatos_datapath)
  
  doacoes <- processa_doacoes_tse(receitas_datapath, candidatos_datapath, ano = ano, summarized = TRUE) %>% 
    select(cpf = NR_CPF_CANDIDATO, nome_candidato = NM_CANDIDATO, cpf_cnpj_doador = NR_CPF_CNPJ_DOADOR, nome_doador = NM_DOADOR_RFB, 
           origem_receita = DS_ORIGEM_RECEITA, valor_receita = VR_RECEITA)
  
  parlamentares <- read_csv(here("crawler/raw_data/parlamentares.csv")) %>% 
    filter(casa == casa_origem, em_exercicio == 1)
  
  if (casa_origem == "camara") {
    parlamentares_doacoes <- parlamentares %>% 
      left_join(doacoes, by = "cpf")
    
  } else if (casa_origem == "senado") {
    source(here("crawler/utils/utils.R"))
    
    parlamentares_doacoes <- parlamentares %>% 
      mutate(nome_padronizado = padroniza_nome(nome_civil)) %>% 
      left_join(doacoes %>% 
                  mutate(nome_padronizado = padroniza_nome(nome_candidato)),
                by = c("nome_padronizado")) %>% 
      mutate(cpf = cpf.y)
    
  } else {
    stop("O parâmetro casa_origem deve ser 'camara' ou 'senado'")
  }
  
  parlamentares_doacoes <- parlamentares_doacoes %>% 
    select(id, casa, cpf, nome_civil, nome_eleitoral, genero, uf, sg_partido, situacao, condicao_eleitoral, 
           ultima_legislatura, em_exercicio, cpf_cnpj_doador, nome_doador, origem_receita, valor_receita)
  
  return(parlamentares_doacoes)  
}

#' @title Executa processador de dados para recuperar doadores para campanhas de parlamentares (Deputados e Senadores)
#' @description Executa processador de dados para recuperar doadores para campanhas de parlamentares (Deputados e Senadores)
#' @param ano Ano da eleição. Pode ser 2018 ou 2014.
#' @return Dataframe contendo doações feitas por partidos, candidatos e pessoas físicas e/ou jurídicas para os parlamentares
#' @examples
#' parlamentares_doadores <- processa_doacoes_parlamentares_tse(2018)
processa_doacoes_parlamentares_tse <- function(ano = 2018) {
  library(tidyverse)
  
  deputados_doacoes <- filtra_doacoes_parlamentares_exercicio(ano, casa_origem = "camara")
  
  senadores_doacoes <- filtra_doacoes_parlamentares_exercicio(ano, casa_origem = "senado")
  
  parlamentares_doacoes <- deputados_doacoes %>% 
    rbind(senadores_doacoes)
  
  return(parlamentares_doacoes)
}
