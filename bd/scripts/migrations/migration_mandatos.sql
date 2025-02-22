-- MANDATOS
BEGIN;
CREATE TEMP TABLE temp_mandatos AS SELECT * FROM mandatos LIMIT 0;

\copy temp_mandatos FROM './data/mandatos.csv' WITH NULL AS 'NA' DELIMITER ',' CSV HEADER;

INSERT INTO mandatos (id_mandato_voz, id_parlamentar_voz, id_legislatura, data_inicio, 
  data_fim, situacao, cod_causa_fim_exercicio, desc_causa_fim_exercicio)

SELECT id_mandato_voz, id_parlamentar_voz, id_legislatura, data_inicio, 
data_fim, situacao, cod_causa_fim_exercicio, desc_causa_fim_exercicio
FROM temp_mandatos
ON CONFLICT (id_mandato_voz) 
DO
  UPDATE
    SET 
      data_inicio = EXCLUDED.data_inicio,
      data_fim = EXCLUDED.data_fim,
      situacao = EXCLUDED.situacao,
      cod_causa_fim_exercicio = EXCLUDED.cod_causa_fim_exercicio,
      desc_causa_fim_exercicio = EXCLUDED.desc_causa_fim_exercicio;
      
DELETE FROM mandatos
WHERE (id_mandato_voz) NOT IN
  (SELECT id_mandato_voz
   FROM temp_mandatos);

DROP TABLE temp_mandatos; 
COMMIT;