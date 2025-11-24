-- Add avatar_emoji column to profiles table
-- This allows users to select an emoji as their profile avatar

ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS avatar_emoji TEXT DEFAULT '😀';

-- Set default emoji for existing users who don't have one
UPDATE profiles 
SET avatar_emoji = '😀' 
WHERE avatar_emoji IS NULL;

-- Create index for faster queries (optional but recommended)
CREATE INDEX IF NOT EXISTS idx_profiles_avatar_emoji ON profiles(avatar_emoji);
