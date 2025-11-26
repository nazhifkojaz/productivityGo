"""
Environment configuration and feature flags
"""
import os
from dotenv import load_dotenv

load_dotenv()

# Debug Mode (enables test endpoints and debug UI)
# Checks both DEBUG_MODE and DEBUG for backwards compatibility
DEBUG_MODE = (
    os.getenv("DEBUG_MODE", "false").lower() == "true" or 
    os.getenv("DEBUG", "0") == "1"
)

# Supabase Configuration
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_URI = os.getenv("SUPABASE_URI")
SUPABASE_KEY = os.getenv("SUPABASE_ANON_KEY")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

# Database Configuration
DATABASE_URL = os.getenv("DATABASE_URL")
