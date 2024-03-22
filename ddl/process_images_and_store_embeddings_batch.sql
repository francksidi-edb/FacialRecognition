CREATE OR REPLACE FUNCTION public.process_images_and_store_embeddings_batch(
	source_dir text,
	tag text,
	batch integer)
    RETURNS integer
    LANGUAGE 'plpython3u'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
import os
import time
from PIL import Image
from transformers import CLIPModel, CLIPProcessor
import numpy as np

def load_images_batch(image_paths, processor, tag):
    images, valid_paths = [], []
    for img_path in image_paths:
        try:
            img = Image.open(img_path)
            img.verify()  # Verify the image integrity
            img = Image.open(img_path)  # Reopen to reset file pointer
            images.append(img)
            valid_paths.append(img_path)
        except OSError as e:
            plpy.error(f"Failed to process image {img_path}: {e}")
            continue  # Skip problematic images
    if images:
        return processor(text=[tag] * len(images), images=images, return_tensors="pt", padding=True), valid_paths
    else:
        return None, []

start_time = time.time()
if 'model' not in SD:
    SD['model'] = CLIPModel.from_pretrained("openai/clip-vit-base-patch32")
    SD['processor'] = CLIPProcessor.from_pretrained("openai/clip-vit-base-patch32")
model = SD['model']
processor = SD['processor']

batch_size = batch
image_paths = [os.path.join(source_dir, f) for f in os.listdir(source_dir) if os.path.isfile(os.path.join(source_dir, f))]
image_count = 0
total_image_processing_time = 0
total_insertion_time = 0

for i in range(0, len(image_paths), batch_size):
    batch_paths = image_paths[i:i+batch_size]
    inputs, valid_paths = load_images_batch(batch_paths, processor, tag)
    if inputs is not None:
        image_processing_start_time = time.time()
        outputs = model(**inputs)
        image_processing_end_time = time.time()
        embeddings = outputs.image_embeds
        image_processing_time = image_processing_end_time - image_processing_start_time
        total_image_processing_time += image_processing_time

        # Assuming embeddings are processed as a batch; adapt as needed
        embeddings_list = embeddings.detach().cpu().tolist()
        for idx, embedding in enumerate(embeddings_list):
            # Insert each embedding into the database
            insertion_start_time = time.time()
            plan = plpy.prepare("INSERT INTO pictures (imagepath, tag, embeddings) VALUES ($1, $2, $3)", ["text", "text", "vector"])
            plpy.execute(plan, [valid_paths[idx], tag, embedding])
            insertion_end_time = time.time()
            total_insertion_time += insertion_end_time - insertion_start_time

        image_count += len(valid_paths)

total_time = time.time() - start_time
plpy.notice(f"Total processing time: {total_time:.2f} seconds")
plpy.notice(f"Total image processing time: {total_image_processing_time:.2f} seconds")
plpy.notice(f"Total database insertion time: {total_insertion_time:.2f} seconds")
plpy.notice(f"Total number of images processed: {image_count}")

return image_count
$BODY$;
