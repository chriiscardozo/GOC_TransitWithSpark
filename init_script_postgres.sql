create table data_load (
	indice text,
	datahora text,
	lat text,
	lon text,
	velocidade text
);

CREATE TABLE logradouro
(
  lid bigint,
  osm_id bigint,
  nome text,
  tipo text,
  lat_src double precision,
  lon_src double precision,
  lat_dst double precision,
  lon_dst double precision,
  limite integer,
  ordem integer
);
alter table logradouro add column the_geom geography;
update logradouro
	set the_geom = st_makeline(st_point(lon_src,lat_src), st_point(lon_dst,lat_dst))::geography;
create index idx_logradouro_geom on logradouro using gist(the_geom);
create index idx_logradoro_lid on logradouro(lid);

create table velocidade_vias (
	lid bigint,
	velocidade_media double precision
);
create index idx_velocidade_vias_lid on velocidade_vias(lid);

create or replace function gc_calcular_velocidades()
 returns text as
$BODY$
BEGIN
	drop table if exists temp_gps_data_load;
	create temp table temp_gps_data_load as (
		select st_point(cast(d.lon as double precision), cast(d.lat as double precision))::geography p, cast(d.velocidade as double precision) from data_load d
	);
	create index idx_load_data_p on temp_gps_data_load using gist(p);

	truncate table velocidade_vias;
	insert into velocidade_vias(
		select l.lid, avg(d.velocidade) from logradouro l
		left join temp_gps_data_load d on 
			ST_DWithin(l.the_geom,d.p,20)
		where d.velocidade is not null
		group by l.lid
	);
			
	return (select count(*)::text from velocidade_vias);
END;
$BODY$
language plpgsql volatile
cost 1000;

create or replace function gc_obter_velocidades()
 returns json as
$BODY$
BEGIN
	return (select array_to_json(array_agg(to_json(row(z)))) from(
		select v.lid, v.velocidade_media, l.nome, l.limite,
			(select array_to_json(array_agg(to_json(row(j.*)))) from (select st_x(geom), st_y(geom) from (select (st_dumppoints(the_geom::geometry)).geom from logradouro where lid = l.lid) t) j) pontos
			from velocidade_vias v
		left join logradouro l on l.lid = v.lid
		) as z);
END;
$BODY$
language plpgsql stable
cost 100;
