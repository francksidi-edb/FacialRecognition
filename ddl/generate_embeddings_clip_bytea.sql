CREATE OR REPLACE FUNCTION public.generate_embeddings_clip_bytea(
	img_bytea bytea,
	tag text)
    RETURNS SETOF vector 
    LANGUAGE 'plpython3u'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
import os
from PIL import Image
from transformers import CLIPModel, CLIPProcessor
import numpy as np
from io import BytesIO  # Import BytesIO to handle bytea input

# Define the model and processor outside the loop to avoid reloading them for each image
model_name = "openai/clip-vit-base-patch32"
if 'model' not in SD:
    SD['model'] = CLIPModel.from_pretrained(model_name)
    SD['processor'] = CLIPProcessor.from_pretrained(model_name)
    plpy.notice("Model & Processor Loaded")
else:
    plpy.notice("Model & Processor Reused")
model = SD['model']
processor = SD['processor']

# Convert the bytea data to a bytes-like object and load the image
img_bytes = BytesIO(img_bytea)
img = Image.open(img_bytes)

# Process the image and calculate embeddings
inputs = processor(text=[tag], images=img, return_tensors="pt")
outputs = model(**inputs)
embedding = outputs.image_embeds

# Convert embeddings to a list to store in the database
embeddings_list = embedding.tolist()

return embeddings_list
$BODY$;
