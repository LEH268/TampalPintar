create extension if not exists cube;
create extension if not exists earthdistance;

create type user_role as enum ('citizen','jkr_malaysia','jkr_selangor','local_council','highway_concessionaire');
create type pothole_status as enum ('not_assigned','assigned','fixed');
create type road_type as enum ('highway_expressway','federal_route','state_route','municipal_local');
