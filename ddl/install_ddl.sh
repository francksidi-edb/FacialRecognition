#!/bin/bash

psql -f "generate_embeddings_clip_bytea.sql"
psql -f "generate_embeddings_clip_text.sql"
psql -f "plpython_check.sql"
psql -f "process_images_and_store_embeddings_batch.sql"
psql -f "scan_specific_path_and_load.sql"
psql -f "table.sql"
psql -f "createindex.sql"
psql -f "utilities.sql"
