#!/bin/bash

start=`date +%s`

if [[ ! -e 'crawler_data/' ]]; then
        mkdir crawler_data/
        if [[ ! -e 'crawler_data/' ]]; then
        	echo "Erro ao criar diretório crawler_data"
        	exit;
        fi
fi

if [[ ! -e 'tmp/' ]]; then
        mkdir tmp/
        if [[ ! -e 'tmp/' ]]; then
        	echo "Erro ao criar diretório tmp"
        	exit;
        fi
fi

current_file=posicoes_`date +%y%m%d%H%M%S`

cd tmp

wget -T 20 -t 1 -O $current_file http://dadosabertos.rio.rj.gov.br/apiTransporte/apresentacao/rest/index.cfm/obterTodasPosicoes

sed -i '1s/^/datahora,ordem,linha,lat,lon,velocidade\n/' $current_file
sed -r 's/\{"COLUMNS":\["DATAHORA","ORDEM","LINHA","LATITUDE","LONGITUDE","VELOCIDADE"\],"DATA":\[//g' $current_file | sed -r 's/\]\}/,/g' | sed -r 's/\[//g' | sed -r 's/\],/\n/g' > $current_file.csv

rm $current_file
mv $current_file.csv ../crawler_data/

end=`date +%s`
runtime=$((end-start))
echo "["`date +%y-%m-%d_%H:%M:%S`"] Crawler rodou em "$runtime" segundos"