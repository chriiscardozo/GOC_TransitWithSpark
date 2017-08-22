from pyspark.sql import SparkSession
from pyspark.sql.types import *
from pyspark.sql.functions import *
from pyspark import SparkContext

GPS_URL="crawler_data/"
DATASET_LOGRADOUROS="logradouros/dataset_ruas.csv"

def init_stream(spark):
	# schema
	schema = StructType().add("datahora", "string").add("ordem", "string") \
				.add("linha", "string").add("lat", "string").add("lon", "string") \
				.add("velocidade", "string")

	# start a streaming
	streamInput = spark.readStream.format("csv").option("maxFilesPerTrigger", 1) \
					.option("header", True) \
					.option("sep", ",").schema(schema).load(GPS_URL)

	return streamInput

def init_logradouros(spark):
	schema = StructType().add("lid", "string").add("osm_id", "string").add("nome", "string") \
				.add("tipo", "string").add("lat_src", "double").add("lon_src", "double") \
				.add("lat_dst", "double").add("lon_dst", "double").add("limite", "integer") \
				.add("ordem", "integer")
	df_logradouros = spark.read.csv(DATASET_LOGRADOUROS, header=True, schema=schema, sep=";")

	return df_logradouros

def main():
	spark = SparkSession.builder.appName("gocoletivo_stream").getOrCreate()
	sc = spark.sparkContext

	df_gps = init_stream(spark)
	df_logradouros = init_logradouros(spark)

	print("\nSchema do CSV de RUAS:")
	df_logradouros.printSchema()
	print("\nSchema do CSV de GPS:")
	df_gps.printSchema()
	
	df_logradouros.createOrReplaceTempView("logradouro")
	df_gps.createOrReplaceTempView("gps")
	
	print("\nTransmitindo:", df_gps.isStreaming)

	query = spark.sql("select datahora,lat,lon,velocidade from gps where to_timestamp(datahora, 'MM-dd-yyyy HH:mm:ss') >= current_timestamp()-interval 20 minutes and cast(velocidade as integer) > 0 and cast(velocidade as integer) < 100")

	# outStream = query.writeStream.outputMode("Complete").format("console").start()
	outStream = query.writeStream.outputMode("append").format("csv").option("path", "result").option("checkpointLocation", "checkpoint").start()
	outStream.awaitTermination()

if __name__ == '__main__':
	main()