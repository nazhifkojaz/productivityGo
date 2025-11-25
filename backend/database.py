import os
from dotenv import load_dotenv
from supabase import create_client, Client
import time
from functools import wraps

load_dotenv()

url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_SERVICE_KEY")
database_url: str = os.environ.get("SUPABASE_URI")  # PostgreSQL connection string

if not url or not key:
    raise ValueError("Missing SUPABASE_URL or SUPABASE_SERVICE_KEY environment variables")

# Create Supabase client (still needed for auth)
supabase: Client = create_client(url, key)

# Direct PostgreSQL connection pool (more stable than REST API)
db_pool = None
if database_url:
    try:
        from psycopg2 import pool
        db_pool = pool.SimpleConnectionPool(
            1,  # min connections
            10,  # max connections
            database_url
        )
        print("✓ Direct PostgreSQL connection pool initialized")
    except ImportError:
        print("⚠ psycopg2 not installed. Install with: pip install psycopg2-binary")
        print("  Falling back to Supabase REST API")
    except Exception as e:
        print(f"⚠ Failed to create DB pool: {e}")
        print("  Falling back to Supabase REST API")

def get_db_connection():
    """Get a connection from the pool"""
    if db_pool:
        return db_pool.getconn()
    return None

def return_db_connection(conn):
    """Return a connection to the pool"""
    if db_pool and conn:
        db_pool.putconn(conn)

def retry_on_connection_error(max_retries=3, delay=0.5):
    """
    Decorator to retry Supabase operations on connection errors.
    
    Args:
        max_retries: Maximum number of retry attempts
        delay: Initial delay between retries (exponential backoff)
    """
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            last_exception = None
            for attempt in range(max_retries):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    last_exception = e
                    error_msg = str(e).lower()
                    
                    # Only retry on connection-related errors
                    if any(keyword in error_msg for keyword in ['disconnect', 'connection', 'timeout', 'network']):
                        if attempt < max_retries - 1:
                            wait_time = delay * (2 ** attempt)  # Exponential backoff
                            print(f"Connection error on attempt {attempt + 1}/{max_retries}, retrying in {wait_time}s: {e}")
                            time.sleep(wait_time)
                            continue
                    # For non-connection errors, raise immediately
                    raise
            
            # All retries exhausted
            raise last_exception
        return wrapper
    return decorator

