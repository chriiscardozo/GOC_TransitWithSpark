#!/bin/bash
conexao='-h localhost -d spark -U christian'

if [[ -e 'mycsv.csv' ]]; then
	rm mycsv.csv
fi

psql $conexao -c "truncate data_load;"
python3 data_load.py
psql $conexao -c "\copy data_load FROM mycsv.csv DELIMITER ',' CSV"
psql $conexao -c "select gc_calcular_velocidades();"
if [[ -e 'mycsv.csv' ]]; then
	rm mycsv.csv
fi