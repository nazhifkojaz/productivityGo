-- Create follows table
CREATE TABLE IF NOT EXISTS follows (
    follower_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    following_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (follower_id, following_id)
);

-- Enable RLS
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;

-- Policies
-- 1. Everyone can read follows (public)
-- Drop if exists to avoid errors on re-run
DROP POLICY IF EXISTS "Public follows access" ON follows;
CREATE POLICY "Public follows access" ON follows FOR SELECT USING (true);

-- 2. Users can follow others (insert)
DROP POLICY IF EXISTS "Users can follow" ON follows;
CREATE POLICY "Users can follow" ON follows FOR INSERT WITH CHECK (auth.uid() = follower_id);

-- 3. Users can unfollow (delete)
DROP POLICY IF EXISTS "Users can unfollow" ON follows;
CREATE POLICY "Users can unfollow" ON follows FOR DELETE USING (auth.uid() = follower_id);
