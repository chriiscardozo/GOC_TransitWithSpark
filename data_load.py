from pyspark.sql import SparkSession
from pyspark.sql.types import *
from pyspark.sql.functions import *
from pyspark import SparkContext

DATASET_GPS='result'

spark = SparkSession.builder.appName("gocoletivo_load").getOrCreate()
sc = spark.sparkContext
schema = StructType().add("datahora", "string").add("lat", "string").add("lon", "string").add("velocidade", "string")
df = spark.read.csv(DATASET_GPS, header=False, sep=",", schema=schema)
print(str(df.count()) + " registros recuperados")
ultimas = df.filter("to_timestamp(datahora, 'MM-dd-yyyy HH:mm:ss') >= current_timestamp()-interval 20 minutes")
print(str(ultimas.count()) + " registros (ultimos 20 min)")

ultimas.toPandas().to_csv('mycsv.csv',header=False)