CREATE OR REPLACE FUNCTION generate_embeddings_clip_text(text_query text)
RETURNS float[] AS
$$
    import torch
    from transformers import CLIPProcessor, CLIPModel

    # Attempt to cache model and processor using SD, but be aware this might not persist as expected
    if 'model' not in SD:
        SD['model'] = CLIPModel.from_pretrained("openai/clip-vit-base-patch32").to("cuda" if torch.cuda.is_available() else "cpu")
        SD['processor'] = CLIPProcessor.from_pretrained("openai/clip-vit-base-patch32")

    model = SD['model']
    processor = SD['processor']

    inputs = processor(text=[text_query], return_tensors="pt")
    inputs = {k: v.to("cuda" if torch.cuda.is_available() else "cpu") for k, v in inputs.items()}

    with torch.no_grad():
        text_embeddings = model.get_text_features(**inputs).cpu().numpy().tolist()

    return text_embeddings[0]
$$ LANGUAGE plpython3u;
