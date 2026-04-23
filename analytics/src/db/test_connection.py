import os
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

load_dotenv()

user = os.getenv("PG_USER")
password = os.getenv("PG_PASSWORD")
host = os.getenv("PG_HOST")
port = os.getenv("PG_PORT")
db = os.getenv("PG_DB")

engine = create_engine(f"postgresql+psycopg2://{user}:{password}@{host}:{port}/{db}")

with engine.connect() as conn:
    result = conn.execute(text("SELECT current_database(), current_user, now()"))
    print(result.fetchone())
