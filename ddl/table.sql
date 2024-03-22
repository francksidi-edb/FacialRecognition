drop table if exists public.pictures;

CREATE TABLE IF NOT EXISTS public.pictures ( id serial, imagepath text, tag text, embeddings vector(512) ) TABLESPACE pg_default;

