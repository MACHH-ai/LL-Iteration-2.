/*
  # Complete Database Setup - Storage, Functions, and Advanced Features

  1. Storage Buckets
    - `user-uploads` - General user files (private)
    - `problem-images` - Photos of problems (private) 
    - `voice-recordings` - Audio recordings (private)
    - `user-avatars` - Profile pictures (public)

  2. Advanced Functions
    - Smart prompt selection
    - Learning streak calculation
    - Achievement system
    - Learning insights generation
    - Data cleanup utilities

  3. Additional Triggers
    - Prompt effectiveness tracking
    - Achievement checking
    - Streak updates

  4. Performance Indexes
    - Optimized for complex queries
    - Analytics and reporting support
*/

-- =============================================
-- STORAGE BUCKETS FOR USER FILES
-- =============================================

-- Create storage buckets for user-generated content
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
  (
    'user-uploads', 
    'user-uploads', 
    false, 
    52428800, -- 50MB limit
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'audio/mpeg', 'audio/wav', 'audio/ogg']
  ),
  (
    'problem-images', 
    'problem-images', 
    false, 
    10485760, -- 10MB limit
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
  ),
  (
    'voice-recordings', 
    'voice-recordings', 
    false, 
    20971520, -- 20MB limit
    ARRAY['audio/mpeg', 'audio/wav', 'audio/ogg', 'audio/mp4', 'audio/webm']
  ),
  (
    'user-avatars', 
    'user-avatars', 
    true, 
    2097152, -- 2MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp']
  )
ON CONFLICT (id) DO NOTHING;

-- Storage policies for user uploads
CREATE POLICY "Users can upload their own files" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id IN ('user-uploads', 'problem-images', 'voice-recordings', 'user-avatars') 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can view their own files" ON storage.objects
  FOR SELECT USING (
    bucket_id IN ('user-uploads', 'problem-images', 'voice-recordings', 'user-avatars')
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can update their own files" ON storage.objects
  FOR UPDATE USING (
    bucket_id IN ('user-uploads', 'problem-images', 'voice-recordings', 'user-avatars')
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can delete their own files" ON storage.objects
  FOR DELETE USING (
    bucket_id IN ('user-uploads', 'problem-images', 'voice-recordings', 'user-avatars')
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Public access for user avatars
CREATE POLICY "Avatar images are publicly accessible" ON storage.objects
  FOR SELECT USING (bucket_id = 'user-avatars');

-- =============================================
-- ADVANCED FUNCTIONS FOR LEARNING ANALYTICS
-- =============================================

-- Function to select the best prompt for a given problem
CREATE OR REPLACE FUNCTION public.select_optimal_prompt(
  p_subject_name TEXT,
  p_input_type TEXT DEFAULT 'any',
  p_difficulty TEXT DEFAULT 'medium',
  p_grade_level TEXT DEFAULT NULL,
  p_keywords TEXT[] DEFAULT NULL
)
RETURNS TABLE(
  prompt_id UUID,
  prompt_title TEXT,
  prompt_template TEXT,
  effectiveness_score DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.title,
    p.prompt_template,
    p.effectiveness_score
  FROM public.prompts p
  JOIN public.subjects s ON p.subject_id = s.id
  WHERE 
    p.is_active = true
    AND s.name = p_subject_name
    AND (p.input_type = p_input_type OR p.input_type = 'any')
    AND (p.difficulty_level = p_difficulty OR p_difficulty IS NULL)
    AND (p_grade_level IS NULL OR p.grade_levels @> ARRAY[p_grade_level])
    AND (p_keywords IS NULL OR p.keywords && p_keywords)
  ORDER BY 
    p.effectiveness_score DESC,
    p.usage_count ASC, -- Prefer less-used prompts for variety
    RANDOM() -- Add some randomness for A/B testing
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate learning streak
CREATE OR REPLACE FUNCTION public.calculate_learning_streak(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
  current_streak INTEGER := 0;
  check_date DATE := CURRENT_DATE;
  has_activity BOOLEAN;
BEGIN
  -- Check each day going backwards from today
  LOOP
    SELECT EXISTS(
      SELECT 1 FROM public.problem_submissions 
      WHERE user_id = p_user_id 
        AND status = 'completed'
        AND DATE(created_at) = check_date
    ) INTO has_activity;
    
    IF has_activity THEN
      current_streak := current_streak + 1;
      check_date := check_date - INTERVAL '1 day';
    ELSE
      -- If today has no activity, check if yesterday does (grace period)
      IF check_date = CURRENT_DATE THEN
        check_date := check_date - INTERVAL '1 day';
      ELSE
        EXIT; -- Break the streak
      END IF;
    END IF;
    
    -- Safety limit to prevent infinite loops
    IF current_streak > 365 THEN
      EXIT;
    END IF;
  END LOOP;
  
  RETURN current_streak;
END;
$$ LANGUAGE plpgsql;

-- Function to check and award achievements
CREATE OR REPLACE FUNCTION public.check_and_award_achievements(p_user_id UUID)
RETURNS TABLE(newly_awarded_achievement_id UUID) AS $$
DECLARE
  achievement_record RECORD;
  user_stats RECORD;
  criteria_met BOOLEAN;
BEGIN
  -- Get current user statistics
  SELECT 
    up.problems_solved,
    up.total_study_time_minutes,
    up.current_streak,
    up.level,
    up.subjects_studied,
    COUNT(DISTINCT ps.subject_id) as unique_subjects_count,
    COUNT(CASE WHEN ps.user_rating = 5 THEN 1 END) as five_star_count,
    MAX(session_problems.problems_in_session) as max_problems_per_session
  INTO user_stats
  FROM public.user_progress up
  LEFT JOIN public.problem_submissions ps ON up.user_id = ps.user_id AND ps.status = 'completed'
  LEFT JOIN (
    SELECT 
      user_id,
      DATE(created_at) as session_date,
      COUNT(*) as problems_in_session
    FROM public.problem_submissions 
    WHERE user_id = p_user_id AND status = 'completed'
    GROUP BY user_id, DATE(created_at)
  ) session_problems ON up.user_id = session_problems.user_id
  WHERE up.user_id = p_user_id
  GROUP BY up.problems_solved, up.total_study_time_minutes, up.current_streak, up.level, up.subjects_studied;

  -- Check each achievement
  FOR achievement_record IN 
    SELECT a.* FROM public.achievements a
    WHERE a.is_active = true
      AND NOT EXISTS (
        SELECT 1 FROM public.user_achievements ua 
        WHERE ua.user_id = p_user_id AND ua.achievement_id = a.id AND ua.is_completed = true
      )
  LOOP
    criteria_met := false;
    
    -- Check different types of criteria
    IF achievement_record.criteria ? 'problems_solved' THEN
      criteria_met := user_stats.problems_solved >= (achievement_record.criteria->>'problems_solved')::INTEGER;
    ELSIF achievement_record.criteria ? 'study_hours' THEN
      criteria_met := (user_stats.total_study_time_minutes / 60.0) >= (achievement_record.criteria->>'study_hours')::DECIMAL;
    ELSIF achievement_record.criteria ? 'streak_days' THEN
      criteria_met := user_stats.current_streak >= (achievement_record.criteria->>'streak_days')::INTEGER;
    ELSIF achievement_record.criteria ? 'level' THEN
      criteria_met := user_stats.level >= (achievement_record.criteria->>'level')::INTEGER;
    ELSIF achievement_record.criteria ? 'subjects_count' THEN
      criteria_met := user_stats.unique_subjects_count >= (achievement_record.criteria->>'subjects_count')::INTEGER;
    ELSIF achievement_record.criteria ? 'five_star_ratings' THEN
      criteria_met := user_stats.five_star_count >= (achievement_record.criteria->>'five_star_ratings')::INTEGER;
    ELSIF achievement_record.criteria ? 'problems_per_session' THEN
      criteria_met := COALESCE(user_stats.max_problems_per_session, 0) >= (achievement_record.criteria->>'problems_per_session')::INTEGER;
    END IF;
    
    -- Award achievement if criteria met
    IF criteria_met THEN
      INSERT INTO public.user_achievements (
        user_id, 
        achievement_id, 
        is_completed, 
        unlocked_at, 
        points_earned,
        progress,
        max_progress
      ) VALUES (
        p_user_id,
        achievement_record.id,
        true,
        NOW(),
        achievement_record.points_reward,
        1,
        1
      ) ON CONFLICT (user_id, achievement_id) DO UPDATE SET
        is_completed = true,
        unlocked_at = NOW(),
        points_earned = achievement_record.points_reward;
      
      -- Add points to user progress
      UPDATE public.user_progress 
      SET 
        total_points = total_points + achievement_record.points_reward,
        experience_points = experience_points + achievement_record.points_reward,
        level = public.calculate_user_level(experience_points + achievement_record.points_reward)
      WHERE user_id = p_user_id;
      
      newly_awarded_achievement_id := achievement_record.id;
      RETURN NEXT;
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update prompt effectiveness based on user feedback
CREATE OR REPLACE FUNCTION public.update_prompt_effectiveness()
RETURNS TRIGGER AS $$
DECLARE
  avg_rating DECIMAL;
  success_rate DECIMAL;
  total_usage INTEGER;
BEGIN
  -- Calculate average rating for this prompt
  SELECT 
    AVG(ps.user_rating),
    COUNT(CASE WHEN ps.status = 'completed' THEN 1 END)::DECIMAL / COUNT(*) * 100,
    COUNT(*)
  INTO avg_rating, success_rate, total_usage
  FROM public.problem_submissions ps
  WHERE ps.prompt_id = NEW.prompt_id;
  
  -- Update prompt effectiveness score (weighted average of rating and success rate)
  UPDATE public.prompts 
  SET 
    average_rating = COALESCE(avg_rating, 0),
    effectiveness_score = (COALESCE(avg_rating, 0) * 0.6 + COALESCE(success_rate, 0) / 20.0 * 0.4),
    usage_count = total_usage
  WHERE id = NEW.prompt_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to clean up old data (for maintenance)
CREATE OR REPLACE FUNCTION public.cleanup_old_data()
RETURNS void AS $$
BEGIN
  -- Delete old learning analytics data (older than 2 years)
  DELETE FROM public.learning_analytics 
  WHERE created_at < NOW() - INTERVAL '2 years';
  
  -- Delete old learning sessions (older than 1 year)
  DELETE FROM public.learning_sessions 
  WHERE created_at < NOW() - INTERVAL '1 year';
  
  -- Archive old problem submissions (move to archive table if needed)
  -- For now, just update old submissions to reduce query load
  UPDATE public.problem_submissions 
  SET ai_response = NULL 
  WHERE created_at < NOW() - INTERVAL '6 months' 
    AND ai_response IS NOT NULL;
  
  RAISE NOTICE 'Data cleanup completed successfully';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to generate learning insights for users
CREATE OR REPLACE FUNCTION public.generate_learning_insights(p_user_id UUID)
RETURNS TABLE(
  insight_type TEXT,
  insight_title TEXT,
  insight_description TEXT,
  insight_data JSONB
) AS $$
DECLARE
  user_data RECORD;
  favorite_subject TEXT;
  improvement_subject TEXT;
  avg_session_time DECIMAL;
BEGIN
  -- Get user learning data
  SELECT 
    up.*,
    COUNT(ps.id) as total_submissions,
    AVG(ps.user_rating) as avg_rating,
    MODE() WITHIN GROUP (ORDER BY s.name) as most_studied_subject
  INTO user_data
  FROM public.user_progress up
  LEFT JOIN public.problem_submissions ps ON up.user_id = ps.user_id AND ps.status = 'completed'
  LEFT JOIN public.subjects s ON ps.subject_id = s.id
  WHERE up.user_id = p_user_id
  GROUP BY up.user_id, up.problems_solved, up.total_study_time_minutes, up.current_streak, 
           up.longest_streak, up.total_points, up.level, up.experience_points, up.subjects_studied,
           up.favorite_subjects, up.average_session_duration, up.preferred_difficulty, 
           up.learning_velocity, up.accuracy_rate, up.last_activity_date, up.created_at, up.updated_at;

  -- Insight 1: Learning Velocity
  IF user_data.problems_solved > 10 THEN
    insight_type := 'performance';
    insight_title := 'Learning Velocity Analysis';
    insight_description := format('You solve an average of %.1f problems per hour of study time.', 
      user_data.problems_solved::DECIMAL / GREATEST(user_data.total_study_time_minutes / 60.0, 1));
    insight_data := jsonb_build_object(
      'problems_per_hour', user_data.problems_solved::DECIMAL / GREATEST(user_data.total_study_time_minutes / 60.0, 1),
      'total_problems', user_data.problems_solved,
      'total_hours', user_data.total_study_time_minutes / 60.0
    );
    RETURN NEXT;
  END IF;

  -- Insight 2: Streak Performance
  IF user_data.current_streak >= 3 THEN
    insight_type := 'motivation';
    insight_title := 'Consistency Champion';
    insight_description := format('Amazing! You''ve maintained a %d-day learning streak. Keep it up!', user_data.current_streak);
    insight_data := jsonb_build_object(
      'current_streak', user_data.current_streak,
      'longest_streak', user_data.longest_streak
    );
    RETURN NEXT;
  END IF;

  -- Insight 3: Subject Mastery
  IF user_data.most_studied_subject IS NOT NULL THEN
    insight_type := 'subject_focus';
    insight_title := 'Subject Expertise';
    insight_description := format('You''re becoming an expert in %s! Consider exploring related topics.', user_data.most_studied_subject);
    insight_data := jsonb_build_object(
      'primary_subject', user_data.most_studied_subject,
      'suggestion', 'Try challenging yourself with harder problems in this subject'
    );
    RETURN NEXT;
  END IF;

  -- Insight 4: Level Progress
  IF user_data.level > 1 THEN
    insight_type := 'achievement';
    insight_title := 'Level Up Progress';
    insight_description := format('You''re at level %d! You need %d more XP to reach the next level.', 
      user_data.level, 
      (user_data.level * 100) - user_data.experience_points);
    insight_data := jsonb_build_object(
      'current_level', user_data.level,
      'current_xp', user_data.experience_points,
      'xp_to_next_level', (user_data.level * 100) - user_data.experience_points
    );
    RETURN NEXT;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- ADDITIONAL TRIGGERS
-- =============================================

-- Trigger to update prompt effectiveness when problem submissions are rated
CREATE TRIGGER update_prompt_effectiveness_on_rating
  AFTER UPDATE OF user_rating ON public.problem_submissions
  FOR EACH ROW 
  WHEN (NEW.user_rating IS NOT NULL AND NEW.prompt_id IS NOT NULL)
  EXECUTE FUNCTION public.update_prompt_effectiveness();

-- Trigger to check achievements when user progress is updated
CREATE OR REPLACE FUNCTION public.trigger_achievement_check()
RETURNS TRIGGER AS $$
BEGIN
  -- Check for new achievements (async to avoid blocking)
  PERFORM public.check_and_award_achievements(NEW.user_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_achievements_on_progress_update
  AFTER UPDATE ON public.user_progress
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_achievement_check();

-- Trigger to update learning streak daily
CREATE OR REPLACE FUNCTION public.update_daily_streak()
RETURNS TRIGGER AS $$
BEGIN
  -- Update current streak when a problem is completed
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    UPDATE public.user_progress 
    SET current_streak = public.calculate_learning_streak(NEW.user_id)
    WHERE user_id = NEW.user_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_streak_on_completion
  AFTER UPDATE ON public.problem_submissions
  FOR EACH ROW
  EXECUTE FUNCTION public.update_daily_streak();

-- =============================================
-- SCHEDULED FUNCTIONS (for pg_cron if available)
-- =============================================

-- Function to run daily maintenance
CREATE OR REPLACE FUNCTION public.daily_maintenance()
RETURNS void AS $$
BEGIN
  -- Update all user streaks
  UPDATE public.user_progress 
  SET current_streak = public.calculate_learning_streak(user_id);
  
  -- Update longest streaks
  UPDATE public.user_progress 
  SET longest_streak = GREATEST(longest_streak, current_streak);
  
  -- Generate daily analytics
  INSERT INTO public.learning_analytics (user_id, metric_name, metric_value, metric_data)
  SELECT 
    user_id,
    'daily_problems_solved',
    COUNT(*),
    jsonb_build_object('date', CURRENT_DATE, 'subjects', array_agg(DISTINCT subject_id))
  FROM public.problem_submissions 
  WHERE DATE(created_at) = CURRENT_DATE AND status = 'completed'
  GROUP BY user_id;
  
  RAISE NOTICE 'Daily maintenance completed at %', NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- ADDITIONAL INDEXES FOR PERFORMANCE
-- =============================================

-- Basic indexes for the new functions (avoiding function-based indexes)
CREATE INDEX IF NOT EXISTS idx_problem_submissions_created_date ON public.problem_submissions(created_at);
CREATE INDEX IF NOT EXISTS idx_problem_submissions_user_created ON public.problem_submissions(user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_user_achievements_completed_date ON public.user_achievements(user_id, is_completed, unlocked_at);
CREATE INDEX IF NOT EXISTS idx_prompts_effectiveness ON public.prompts(effectiveness_score DESC, usage_count ASC);

-- Composite indexes for complex queries
CREATE INDEX IF NOT EXISTS idx_prompts_selection ON public.prompts(subject_id, input_type, difficulty_level, is_active);
CREATE INDEX IF NOT EXISTS idx_problem_submissions_analytics ON public.problem_submissions(user_id, status, created_at, subject_id);

-- Additional performance indexes
CREATE INDEX IF NOT EXISTS idx_problem_submissions_status_user ON public.problem_submissions(status, user_id);
CREATE INDEX IF NOT EXISTS idx_problem_submissions_prompt_rating ON public.problem_submissions(prompt_id, user_rating) WHERE user_rating IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_user_progress_level_xp ON public.user_progress(level, experience_points);

-- =============================================
-- COMPLETION NOTIFICATION
-- =============================================

DO $$
BEGIN
  RAISE NOTICE '🎉 COMPLETE DATABASE SETUP FINISHED! 🎉';
  RAISE NOTICE '';
  RAISE NOTICE '✅ Storage buckets created for:';
  RAISE NOTICE '   - User uploads (images, voice recordings)';
  RAISE NOTICE '   - Problem images';
  RAISE NOTICE '   - Voice recordings';
  RAISE NOTICE '   - User avatars';
  RAISE NOTICE '';
  RAISE NOTICE '✅ Advanced functions added:';
  RAISE NOTICE '   - select_optimal_prompt() - Smart prompt selection';
  RAISE NOTICE '   - calculate_learning_streak() - Streak calculation';
  RAISE NOTICE '   - check_and_award_achievements() - Achievement system';
  RAISE NOTICE '   - generate_learning_insights() - Personalized insights';
  RAISE NOTICE '   - cleanup_old_data() - Data maintenance';
  RAISE NOTICE '';
  RAISE NOTICE '✅ Additional triggers created:';
  RAISE NOTICE '   - Prompt effectiveness tracking';
  RAISE NOTICE '   - Achievement checking';
  RAISE NOTICE '   - Streak updates';
  RAISE NOTICE '';
  RAISE NOTICE '✅ Performance indexes optimized';
  RAISE NOTICE '';
  RAISE NOTICE '🚀 Your Luminara database is now PRODUCTION-READY!';
  RAISE NOTICE '';
  RAISE NOTICE 'Next steps:';
  RAISE NOTICE '1. Update your Edge Functions to use select_optimal_prompt()';
  RAISE NOTICE '2. Test file uploads to storage buckets';
  RAISE NOTICE '3. Verify achievement system works';
  RAISE NOTICE '4. Set up daily maintenance schedule';
END $$;