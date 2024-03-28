import psycopg2
from PIL import Image
import io
import sys
import time

def run_queries(filepath):
    # Connect to your postgres database
    conn = psycopg2.connect(
        dbname="postgres", 
        user="postgres", 
        password="admin", 
        host="localhost"
    )
    cur = conn.cursor()

    try:
        start_time = time.time()  # Start timing for fetching vector
        # First Query: Get the vector
        cur.execute("SELECT public.generate_embeddings_clip_from_url(%s, 'person');", (filepath,))
        vector_result = cur.fetchone()[0]  # Assuming the function returns the vector directly
        vector_time = time.time() - start_time  # End timing for fetching vector
        print(f"Fetching vector took {vector_time:.4f} seconds.")

        start_time = time.time()  # Start timing for querying similar images

        # Second Query: Use the vector to find similar images
        query = """
        SELECT id, imagepath, 1 - (embeddings <-> %s) as similarity 
        FROM pictures_2
        ORDER BY similarity DESC
        LIMIT 5;
        """
        cur.execute(query, (vector_result,))
        results = cur.fetchall()

        query_time = time.time() - start_time  # End timing for querying similar images
        print(f"Querying similar images took {query_time:.4f} seconds.")

        # Display the images
        for result in results:
            id, imagepath, similarity = result
            print(f"ID: {id}, ImagePath: {imagepath}, Similarity: {similarity}")
            # Assuming you have access to the filesystem where images are stored,
            # and PIL installed (`pip install Pillow` for the Image module)
            image = Image.open(imagepath)
            image.show()

    except Exception as e:
        print("An error occurred:", e)
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python script.py <image_file_path>")
    else:
        run_queries(sys.argv[1])


