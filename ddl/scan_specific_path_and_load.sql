CREATE OR REPLACE FUNCTION public.scan_specific_path_and_load(
	search_path text,
	tag text,
	batch integer)
    RETURNS void
    LANGUAGE 'plpython3u'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
import glob
import os  # Make sure to import the os module
import time

# Ensure the search pattern is properly defined to include directories
pattern = search_path
if not pattern.endswith('/'):
    pattern += '*/'

matches = glob.glob(pattern)

# Filter out files, keeping only directories
directories = [match for match in matches if os.path.isdir(match)]

start_time = time.time()
total_images_processed = 0  # Initialize total count of processed images

# Yield each directory found
for directory in directories:
     #yield directory
     plpy.info(f"Processing directory: {directory}")
     try:
        query2 = "SELECT public.process_images_and_store_embeddings_batch('{}', '{}', '{}')".format(directory.replace("'", "''"), tag.replace("'", "''"),batch )
        result = plpy.execute(query2)
        if result.nrows() > 0:  # Check if the function returned a count
           total_images_processed += result[0]["process_images_and_store_embeddings_batch"]
     except Exception as e:
        plpy.notice(f"Failed to process directory {directory}: {e}")
total_time = time.time() - start_time
plpy.info(f"Total traversal and processing time: {total_time:.2f} seconds")
plpy.info(f"Total number of images processed: {total_images_processed}")
if total_time > 0:
    avg_images_per_sec = total_images_processed / total_time
    plpy.info(f"Average images processed per second: {avg_images_per_sec:.2f}")
else:
    plpy.info("No images were processed or processing time was negligible.")
$BODY$;
