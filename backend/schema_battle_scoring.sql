-- Complete database schema update for battle scoring system
-- Run this in your Supabase SQL Editor

-- 1. Add stats columns to profiles table
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS completed_tasks INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS daily_win_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS overall_win_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS battle_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS daily_win_rate DECIMAL(5,2) DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS overall_win_rate DECIMAL(5,2) DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS total_xp_earned INTEGER DEFAULT 0;

-- 2. Add daily_xp to daily_entries table
ALTER TABLE daily_entries
ADD COLUMN IF NOT EXISTS daily_xp INTEGER DEFAULT 0;

-- 3. Add daily_winner_id to daily_entries table (optional, for tracking)
ALTER TABLE daily_entries
ADD COLUMN IF NOT EXISTS is_daily_winner BOOLEAN DEFAULT false;

-- 4. Ensure winner_id exists in battles table
ALTER TABLE battles 
ADD COLUMN IF NOT EXISTS winner_id UUID REFERENCES profiles(id);

-- 5. Drop old columns if they exist (cleanup)
ALTER TABLE profiles
DROP COLUMN IF EXISTS wins,
DROP COLUMN IF EXISTS xp;
