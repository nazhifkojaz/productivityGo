-- SQL Functions for battle scoring system

-- Function to calculate daily XP and determine daily winner
CREATE OR REPLACE FUNCTION calculate_daily_round(
    battle_uuid UUID,
    round_date DATE
)
RETURNS TABLE(user1_xp INT, user2_xp INT, winner_id UUID)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user1_id UUID;
    v_user2_id UUID;
    v_quota INT;
    v_user1_xp INT;
    v_user2_xp INT;
    v_winner_id UUID;
BEGIN
    -- Get battle users
    SELECT user1_id, user2_id INTO v_user1_id, v_user2_id
    FROM battles WHERE id = battle_uuid;
    
    -- Calculate quota for this date
    v_quota := (('x' || substring(md5(round_date::text), 1, 8))::bit(32)::int % 3) + 3;
    
    -- Calculate XP for both users
    SELECT COALESCE(
        (COUNT(*) FILTER (WHERE NOT is_optional AND is_completed)::DECIMAL / v_quota * 100)
        + (COUNT(*) FILTER (WHERE is_optional AND is_completed) * 10),
        0
    )::INT INTO v_user1_xp
    FROM tasks t
    JOIN daily_entries de ON de.id = t.daily_entry_id
    WHERE de.user_id = v_user1_id AND de.date = round_date;
    
    SELECT COALESCE(
        (COUNT(*) FILTER (WHERE NOT is_optional AND is_completed)::DECIMAL / v_quota * 100)
        + (COUNT(*) FILTER (WHERE is_optional AND is_completed) * 10),
        0
    )::INT INTO v_user2_xp
    FROM tasks t
    JOIN daily_entries de ON de.id = t.daily_entry_id
    WHERE de.user_id = v_user2_id AND de.date = round_date;
    
    -- Determine winner
    IF v_user1_xp > v_user2_xp THEN
        v_winner_id := v_user1_id;
    ELSIF v_user2_xp > v_user1_xp THEN
        v_winner_id := v_user2_id;
    ELSE
        v_winner_id := NULL; -- Draw
    END IF;
    
    -- Update daily_entries with XP
    UPDATE daily_entries SET daily_xp = v_user1_xp WHERE user_id = v_user1_id AND date = round_date;
    UPDATE daily_entries SET daily_xp = v_user2_xp WHERE user_id = v_user2_id AND date = round_date;
    
    -- Update stats
    UPDATE profiles SET 
        completed_tasks = completed_tasks + (SELECT COUNT(*) FROM tasks t JOIN daily_entries de ON de.id = t.daily_entry_id WHERE de.user_id = v_user1_id AND de.date = round_date AND t.is_completed = true)
    WHERE id = v_user1_id;
    
    UPDATE profiles SET 
        completed_tasks = completed_tasks + (SELECT COUNT(*) FROM tasks t JOIN daily_entries de ON de.id = t.daily_entry_id WHERE de.user_id = v_user2_id AND de.date = round_date AND t.is_completed = true)
    WHERE id = v_user2_id;
    
    -- Update daily_win_count
    IF v_winner_id IS NOT NULL THEN
        UPDATE profiles SET daily_win_count = daily_win_count + 1 WHERE id = v_winner_id;
    END IF;
    
    RETURN QUERY SELECT v_user1_xp, v_user2_xp, v_winner_id;
END;
$$;

-- Function to complete battle and determine overall winner
CREATE OR REPLACE FUNCTION complete_battle(
    battle_uuid UUID
)
RETURNS TABLE(winner_id UUID, user1_total_xp INT, user2_total_xp INT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user1_id UUID;
    v_user2_id UUID;
    v_user1_total_xp INT;
    v_user2_total_xp INT;
    v_winner_id UUID;
    v_start_date DATE;
    v_end_date DATE;
BEGIN
    -- Get battle details
    SELECT user1_id, user2_id, start_date, end_date 
    INTO v_user1_id, v_user2_id, v_start_date, v_end_date
    FROM battles WHERE id = battle_uuid;
    
    -- Sum total XP across all days
    SELECT COALESCE(SUM(daily_xp), 0)::INT INTO v_user1_total_xp
    FROM daily_entries
    WHERE user_id = v_user1_id AND date BETWEEN v_start_date AND v_end_date;
    
    SELECT COALESCE(SUM(daily_xp), 0)::INT INTO v_user2_total_xp
    FROM daily_entries
    WHERE user_id = v_user2_id AND date BETWEEN v_start_date AND v_end_date;
    
    -- Determine overall winner
    IF v_user1_total_xp > v_user2_total_xp THEN
        v_winner_id := v_user1_id;
    ELSIF v_user2_total_xp > v_user1_total_xp THEN
        v_winner_id := v_user2_id;
    ELSE
        v_winner_id := NULL; -- Draw
    END IF;
    
    -- Update overall_win_count
    IF v_winner_id IS NOT NULL THEN
        UPDATE profiles SET overall_win_count = overall_win_count + 1 WHERE id = v_winner_id;
    END IF;
    
    -- Update total_xp_earned for both
    UPDATE profiles SET total_xp_earned = total_xp_earned + v_user1_total_xp WHERE id = v_user1_id;
    UPDATE profiles SET total_xp_earned = total_xp_earned + v_user2_total_xp WHERE id = v_user2_id;
    
    -- Increment battle_count for both
    UPDATE profiles SET battle_count = battle_count + 1 WHERE id IN (v_user1_id, v_user2_id);
    
    -- Calculate and update win rates
    UPDATE profiles 
    SET 
        overall_win_rate = CASE WHEN battle_count > 0 THEN (overall_win_count::DECIMAL / battle_count * 100) ELSE 0 END,
        daily_win_rate = CASE WHEN battle_count > 0 THEN (daily_win_count::DECIMAL / (battle_count * 5) * 100) ELSE 0 END
    WHERE id IN (v_user1_id, v_user2_id);
    
    -- Update level (every 1000 XP = 1 level)
    UPDATE profiles SET level = FLOOR(total_xp_earned / 1000) + 1 WHERE id = v_user1_id;
    UPDATE profiles SET level = FLOOR(total_xp_earned / 1000) + 1 WHERE id = v_user2_id;
    
    -- Mark battle complete
    UPDATE battles SET status = 'completed', winner_id = v_winner_id WHERE id = battle_uuid;
    
    RETURN QUERY SELECT v_winner_id, v_user1_total_xp, v_user2_total_xp;
END;
$$;
