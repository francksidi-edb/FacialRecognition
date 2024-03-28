CREATE OR REPLACE FUNCTION public.generate_embeddings_clip_from_url(
	img_path text,
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

# Define the model and processor outside the loop to avoid reloading them for each image
	model_name = "openai/clip-vit-base-patch32"
	if 'model' not in SD:
		SD['model'] =  CLIPModel.from_pretrained(model_name)
		SD['processor'] = CLIPProcessor.from_pretrained(model_name)
		plpy.notice("Model & Processor Loaded")
	else:
		plpy.notice("Model & Processor Reused")
	model = SD['model']
	processor = SD['processor']
	
  
  # Access the directory (this part needs to be adapted based on how you access files on your server)
	
          # Load the image
	img = Image.open(img_path)

          # Process the image and calculate embeddings
	inputs = processor(text=[tag], images=img, return_tensors="pt")
	outputs = model(**inputs)
	embedding = outputs.image_embeds
	
          # Convert embeddings to a list to store in the database
	embeddings_list = embedding.tolist()

	return embeddings_list

$BODY$;
