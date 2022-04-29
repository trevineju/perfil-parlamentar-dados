library(tidyverse)
source(here::here("crawler/proposicoes/fetcher_proposicoes_senado.R"))

if(!require(optparse)){
  install.packages("optparse")
  suppressWarnings(suppressMessages(library(optparse)))
}

args = commandArgs(trailingOnly=TRUE)

message("LEIA O README deste diretório")
message("Use --help para mais informações\n")

option_list = list(
  make_option(c("-o", "--output"), type="character", default=here::here("crawler/raw_data/votacoes_nominais_senado_final2019.csv"),
              help="nome do arquivo de saída para as informações das proposições apresentadas [default= %default]", metavar="character")
);

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);

output_path = opt$output

message("Iniciando processamento...")

hoje <- Sys.Date()
proposicoes_senado <- fetch_all_proposicoes_votadas_em_intervalo_senado("10/10/2019", "31/12/2019")

message(paste0("Salvando o resultado dos metadados das proposições do senado em: ", output_path))

readr::write_csv(proposicoes_senado, output_path)

message("Concluído!")
