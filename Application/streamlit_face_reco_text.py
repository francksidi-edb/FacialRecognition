import streamlit as st
import psycopg2
from PIL import Image
import cv2
import numpy as np
import io
import time

# Custom Header Section
logo_path = "logo.svg"
primary_color = "#FF4B33"
background_color = "#FFFFFF"

header_css = f"""
<style>
.header {{
    background-color: {background_color};
    padding: 10px;
    color: white;
}}
a {{
    color: {primary_color};
    padding: 0 16px;
    text-decoration: none;
    font-size: 16px;
}}
</style>
"""

st.markdown(header_css, unsafe_allow_html=True)

col1, col2 = st.columns([1, 4])

with col1:
    st.image(logo_path, width=150)

with col2:
    st.markdown(f"""
    <div class="header">
        <a href="#" target="_blank">Products</a>
        <a href="#" target="_blank">Solutions</a>
        <a href="#" target="_blank">Resources</a>
        <a href="#" target="_blank">Company</a>
    </div>
    """, unsafe_allow_html=True)

# Streamlit UI for Image Similarity Search
st.title('Face Similarity Search')
st.markdown("## Powered by EDB Postgresql and Pgvector")


def create_db_connection():
    return psycopg2.connect(
        dbname="postgres",
        user="postgres",
        password="admin",
        host="localhost"
    )

def search_images(text_query):
    conn = st.session_state.db_conn
    cur = conn.cursor()

    try:
        start_time = time.time()
        cur.execute("SELECT public.generate_embeddings_clip_text(%s)::vector;", (text_query,))
        vector_result = cur.fetchone()[0]
        vector_time = time.time() - start_time
        st.write(f"Fetching vector took {vector_time:.4f} seconds.")

        start_time = time.time()
        query = """
        SELECT id, imagepath, 1 - (embeddings <=> %s) as similarity
        FROM pictures_2
        ORDER BY (embeddings <=> %s)
        LIMIT 5;
        """
# Note the removal of single quotes around the second placeholder and passing vector_result for both placeholders.
        cur.execute(query, (vector_result, vector_result))

        results = cur.fetchall()

        query_filled = cur.mogrify(query, (vector_result, vector_result)).decode('utf-8')
        print(query_filled)

        query_time = time.time() - start_time
        st.write(f"Querying similar images took {query_time:.4f} seconds.")

        if results is not None:
          st.write(f"Number of elements retrieved: {len(results)}")
          for result in results:
            id, imagepath, similarity = result
            st.write(f"ID: {id}, ImagePath: {imagepath}, Similarity: {similarity}")
            image = Image.open(imagepath)
            st.image(image, caption=f"Similarity: {similarity}", width=300)
        else:
          print("No results found.") 

    except Exception as e:
        st.error("An error occurred: " + str(e))
    finally:
        cur.close()

if 'db_conn' not in st.session_state or st.session_state.db_conn.closed:
    st.session_state.db_conn = create_db_connection()


def run_queries(bytes_data):
    conn = st.session_state.db_conn
    cur = conn.cursor()

    try:
        start_time = time.time()
        cur.execute("SELECT public.generate_embeddings_clip_bytea(%s::bytea, 'person'::text);", (bytes_data,))
        vector_result = cur.fetchone()[0]
        vector_time = time.time() - start_time
        st.write(f"Fetching vector took {vector_time:.4f} seconds.")

        start_time = time.time()
        query = """
        SELECT id, imagepath, 1 - (embeddings <=> %s) as similarity
        FROM pictures_2
        ORDER BY (embeddings <=> %s) 
        LIMIT 5;
        """
# Note the removal of single quotes around the second placeholder and passing vector_result for both placeholders.
        cur.execute(query, (vector_result, vector_result))

        results = cur.fetchall()

        query_filled = cur.mogrify(query, (vector_result, vector_result)).decode('utf-8')
        print(query_filled)

        query_time = time.time() - start_time
        st.write(f"Querying similar images took {query_time:.4f} seconds.")

        for result in results:
            id, imagepath, similarity = result
            st.write(f"ID: {id}, ImagePath: {imagepath}, Similarity: {similarity}")
            image = Image.open(imagepath)
            st.image(image, caption=f"Similarity: {similarity}", width=300)

    except Exception as e:
        st.error("An error occurred: " + str(e))
    finally:
        cur.close()

if 'db_conn' not in st.session_state or st.session_state.db_conn.closed:
    st.session_state.db_conn = create_db_connection()



def capture_webcam():
    cap = cv2.VideoCapture(-0)
    
    # Set capture resolution (example: 640x480)
    # Note: Make sure your webcam supports the resolution you set here
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)

    ret, frame = cap.read()
    if not ret:
        st.error("Failed to grab frame from webcam.")
        cap.release()
        return None
    
    cap.release()
    # Convert the color from BGR to RGB
    frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    
    return frame


def reset_camera():
    # Example function to reset camera-related session state or variables
    if 'camera_initialized' in st.session_state:
        del st.session_state['camera_initialized']  # Resetting the state
    # Additional logic to reset or reinitialize the camera can be added here

reset_button = st.button('Reset Application')

if reset_button:
    reset_camera()
    st.rerun()  # This reruns the script, effectively refreshing the page


text_query = st.text_input("Enter a description of the image you're looking for:")


if st.button('Search'):
    if text_query:
        # Call the search function
        results = search_images(text_query)
    else:
        st.write("Please enter a query to search for images.")


uploaded_file = st.file_uploader("Choose an image or capture one from your webcam...", type=['jpg', 'png'])
if st.button('Capture Image from Webcam'):
    captured_frame = capture_webcam()
    if captured_frame is not None:
        st.image(captured_frame, caption='Captured Image', width=600)
        time.sleep(1.5)
        pil_img = Image.fromarray(captured_frame)
        buf = io.BytesIO()
        pil_img.save(buf, format="JPEG")
        bytes_data = buf.getvalue()
        run_queries(bytes_data)
elif uploaded_file is not None:
    bytes_data = uploaded_file.getvalue()
    uploaded_image = Image.open(io.BytesIO(bytes_data))
    st.image(uploaded_image, caption='Uploaded Image', width=600)
    run_queries(bytes_data)

