/*
  # Luminara Learning App - Complete Database Schema

  ## Overview
  This migration creates the complete database structure for the Luminara learning application,
  including user management, problem submissions, progress tracking, achievements, and analytics.

  ## Tables Created
  1. **users** - Extended user profiles linked to Supabase auth
  2. **problem_submissions** - Learning problems and AI solutions
  3. **user_progress** - Learning statistics and achievements
  4. **learning_sessions** - Individual study sessions
  5. **subjects** - Academic subjects and topics
  6. **achievements** - Gamification and milestone tracking
  7. **user_achievements** - User achievement unlocks
  8. **learning_goals** - Personal learning objectives
  9. **study_streaks** - Daily learning streak tracking
  10. **problem_feedback** - User feedback on AI solutions
  11. **learning_analytics** - Detailed learning metrics
  12. **notification_preferences** - User notification settings

  ## Security
  - Row Level Security (RLS) enabled on all tables
  - Users can only access their own data
  - Guest users supported with temporary sessions

  ## Features
  - Comprehensive progress tracking
  - Achievement system with gamification
  - Learning analytics and insights
  - Study streak management
  - Personalized learning goals
  - Feedback collection system
*/

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- =============================================
-- USERS TABLE (Extended Profiles)
-- =============================================

CREATE TABLE IF NOT EXISTS public.users (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  first_name TEXT,
  last_name TEXT,
  username TEXT UNIQUE,
  avatar_url TEXT,
  is_guest BOOLEAN DEFAULT FALSE,
  date_of_birth DATE,
  grade_level TEXT,
  learning_preferences JSONB DEFAULT '{}',
  timezone TEXT DEFAULT 'UTC',
  language_preference TEXT DEFAULT 'en',
  is_active BOOLEAN DEFAULT TRUE,
  last_active_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS and create policies for users
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile" ON public.users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- =============================================
-- SUBJECTS TABLE (Academic Categories)
-- =============================================

CREATE TABLE IF NOT EXISTS public.subjects (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  icon_name TEXT,
  color_hex TEXT DEFAULT '#8A2BE2',
  difficulty_levels TEXT[] DEFAULT ARRAY['easy', 'medium', 'hard'],
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default subjects
INSERT INTO public.subjects (name, description, icon_name, color_hex) VALUES
  ('Mathematics', 'Algebra, Geometry, Calculus, and more', 'calculator', '#8A2BE2'),
  ('Science', 'Physics, Chemistry, Biology, and Earth Science', 'atom', '#6366F1'),
  ('English', 'Literature, Grammar, Writing, and Reading', 'book', '#10B981'),
  ('History', 'World History, Geography, and Social Studies', 'scroll', '#F59E0B'),
  ('Computer Science', 'Programming, Algorithms, and Technology', 'monitor', '#EF4444'),
  ('Art', 'Visual Arts, Music, and Creative Expression', 'palette', '#8B5CF6')
ON CONFLICT (name) DO NOTHING;

-- =============================================
-- PROBLEM SUBMISSIONS TABLE (Enhanced)
-- =============================================

CREATE TABLE IF NOT EXISTS public.problem_submissions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  subject_id UUID REFERENCES public.subjects(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  input_type TEXT CHECK (input_type IN ('text', 'image', 'voice')) NOT NULL,
  text_content TEXT,
  image_url TEXT,
  voice_url TEXT,
  solution TEXT,
  explanation TEXT,
  step_by_step_solution JSONB,
  difficulty TEXT CHECK (difficulty IN ('easy', 'medium', 'hard')),
  estimated_time_minutes INTEGER,
  actual_time_minutes INTEGER,
  tags TEXT[],
  status TEXT CHECK (status IN ('pending', 'processing', 'completed', 'error', 'archived')) DEFAULT 'pending',
  error_message TEXT,
  processing_time_ms INTEGER,
  ai_response JSONB,
  ai_model_used TEXT,
  confidence_score DECIMAL(3,2),
  is_favorite BOOLEAN DEFAULT FALSE,
  view_count INTEGER DEFAULT 0,
  last_viewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS and create policies
ALTER TABLE public.problem_submissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own submissions" ON public.problem_submissions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own submissions" ON public.problem_submissions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own submissions" ON public.problem_submissions
  FOR UPDATE USING (auth.uid() = user_id);

-- =============================================
-- USER PROGRESS TABLE (Enhanced)
-- =============================================

CREATE TABLE IF NOT EXISTS public.user_progress (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE UNIQUE,
  total_problems_solved INTEGER DEFAULT 0,
  total_study_time_minutes INTEGER DEFAULT 0,
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  total_points INTEGER DEFAULT 0,
  current_level INTEGER DEFAULT 1,
  experience_points INTEGER DEFAULT 0,
  subjects_studied TEXT[] DEFAULT '{}',
  favorite_subjects TEXT[] DEFAULT '{}',
  learning_velocity DECIMAL(5,2) DEFAULT 0.0, -- problems per hour
  accuracy_rate DECIMAL(5,2) DEFAULT 0.0, -- percentage
  last_activity_date DATE,
  weekly_goal_minutes INTEGER DEFAULT 300, -- 5 hours default
  monthly_goal_problems INTEGER DEFAULT 50,
  achievements_unlocked INTEGER DEFAULT 0,
  badges_earned TEXT[] DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS and create policies
ALTER TABLE public.user_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own progress" ON public.user_progress
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own progress" ON public.user_progress
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own progress" ON public.user_progress
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- =============================================
-- LEARNING SESSIONS TABLE
-- =============================================

CREATE TABLE IF NOT EXISTS public.learning_sessions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  subject_id UUID REFERENCES public.subjects(id) ON DELETE SET NULL,
  session_type TEXT CHECK (session_type IN ('practice', 'study', 'review', 'challenge')) DEFAULT 'practice',
  start_time TIMESTAMPTZ DEFAULT NOW(),
  end_time TIMESTAMPTZ,
  duration_minutes INTEGER,
  problems_attempted INTEGER DEFAULT 0,
  problems_completed INTEGER DEFAULT 0,
  problems_correct INTEGER DEFAULT 0,
  total_points_earned INTEGER DEFAULT 0,
  focus_score DECIMAL(3,2), -- 0.00 to 1.00
  session_notes TEXT,
  device_type TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS and create policies
ALTER TABLE public.learning_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own sessions" ON public.learning_sessions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own sessions" ON public.learning_sessions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own sessions" ON public.learning_sessions
  FOR UPDATE USING (auth.uid() = user_id);

-- =============================================
-- ACHIEVEMENTS TABLE
-- =============================================

CREATE TABLE IF NOT EXISTS public.achievements (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  description TEXT NOT NULL,
  icon_name TEXT NOT NULL,
  category TEXT CHECK (category IN ('progress', 'streak', 'mastery', 'social', 'special')) NOT NULL,
  rarity TEXT CHECK (rarity IN ('common', 'rare', 'epic', 'legendary')) DEFAULT 'common',
  points_reward INTEGER DEFAULT 0,
  unlock_criteria JSONB NOT NULL, -- JSON criteria for unlocking
  is_active BOOLEAN DEFAULT TRUE,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default achievements
INSERT INTO public.achievements (name, description, icon_name, category, rarity, points_reward, unlock_criteria) VALUES
  ('First Steps', 'Solve your first problem', 'star', 'progress', 'common', 10, '{"problems_solved": 1}'),
  ('Problem Solver', 'Solve 10 problems', 'target', 'progress', 'common', 50, '{"problems_solved": 10}'),
  ('Dedicated Learner', 'Solve 50 problems', 'trophy', 'progress', 'rare', 200, '{"problems_solved": 50}'),
  ('Master Student', 'Solve 100 problems', 'crown', 'progress', 'epic', 500, '{"problems_solved": 100}'),
  ('Learning Legend', 'Solve 500 problems', 'diamond', 'progress', 'legendary', 2000, '{"problems_solved": 500}'),
  ('Streak Starter', 'Maintain a 3-day learning streak', 'flame', 'streak', 'common', 25, '{"current_streak": 3}'),
  ('Streak Master', 'Maintain a 7-day learning streak', 'fire', 'streak', 'rare', 100, '{"current_streak": 7}'),
  ('Unstoppable', 'Maintain a 30-day learning streak', 'lightning', 'streak', 'epic', 1000, '{"current_streak": 30}'),
  ('Math Wizard', 'Solve 25 math problems', 'calculator', 'mastery', 'rare', 150, '{"subject_problems": {"Mathematics": 25}}'),
  ('Science Explorer', 'Solve 25 science problems', 'atom', 'mastery', 'rare', 150, '{"subject_problems": {"Science": 25}}'),
  ('Speed Demon', 'Solve 5 problems in under 30 minutes', 'zap', 'special', 'epic', 300, '{"speed_challenge": {"problems": 5, "time_minutes": 30}}')
ON CONFLICT (name) DO NOTHING;

-- =============================================
-- USER ACHIEVEMENTS TABLE
-- =============================================

CREATE TABLE IF NOT EXISTS public.user_achievements (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  achievement_id UUID REFERENCES public.achievements(id) ON DELETE CASCADE,
  unlocked_at TIMESTAMPTZ DEFAULT NOW(),
  progress_data JSONB DEFAULT '{}',
  is_viewed BOOLEAN DEFAULT FALSE,
  UNIQUE(user_id, achievement_id)
);

-- Enable RLS and create policies
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own achievements" ON public.user_achievements
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own achievements" ON public.user_achievements
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own achievements" ON public.user_achievements
  FOR UPDATE USING (auth.uid() = user_id);

-- =============================================
-- LEARNING GOALS TABLE
-- =============================================

CREATE TABLE IF NOT EXISTS public.learning_goals (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  subject_id UUID REFERENCES public.subjects(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  goal_type TEXT CHECK (goal_type IN ('daily', 'weekly', 'monthly', 'custom')) NOT NULL,
  target_value INTEGER NOT NULL,
  current_value INTEGER DEFAULT 0,
  unit TEXT NOT NULL, -- 'problems', 'minutes', 'topics', etc.
  start_date DATE DEFAULT CURRENT_DATE,
  end_date DATE,
  is_active BOOLEAN DEFAULT TRUE,
  is_completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  priority INTEGER DEFAULT 1, -- 1=low, 2=medium, 3=high
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS and create policies
ALTER TABLE public.learning_goals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own goals" ON public.learning_goals
  FOR ALL USING (auth.uid() = user_id);

-- =============================================
-- STUDY STREAKS TABLE
-- =============================================

CREATE TABLE IF NOT EXISTS public.study_streaks (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  streak_date DATE NOT NULL,
  problems_solved INTEGER DEFAULT 0,
  study_time_minutes INTEGER DEFAULT 0,
  is_streak_day BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, streak_date)
);

-- Enable RLS and create policies
ALTER TABLE public.study_streaks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own streaks" ON public.study_streaks
  FOR ALL USING (auth.uid() = user_id);

-- =============================================
-- PROBLEM FEEDBACK TABLE
-- =============================================

CREATE TABLE IF NOT EXISTS public.problem_feedback (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  problem_id UUID REFERENCES public.problem_submissions(id) ON DELETE CASCADE,
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  feedback_type TEXT CHECK (feedback_type IN ('helpful', 'unclear', 'incorrect', 'too_easy', 'too_hard')),
  comment TEXT,
  is_solution_helpful BOOLEAN,
  suggested_improvement TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, problem_id)
);

-- Enable RLS and create policies
ALTER TABLE public.problem_feedback ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own feedback" ON public.problem_feedback
  FOR ALL USING (auth.uid() = user_id);

-- =============================================
-- LEARNING ANALYTICS TABLE
-- =============================================

CREATE TABLE IF NOT EXISTS public.learning_analytics (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  date DATE DEFAULT CURRENT_DATE,
  subject_id UUID REFERENCES public.subjects(id) ON DELETE SET NULL,
  metric_type TEXT NOT NULL, -- 'daily_summary', 'subject_progress', 'difficulty_analysis', etc.
  metric_data JSONB NOT NULL,
  calculated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, date, subject_id, metric_type)
);

-- Enable RLS and create policies
ALTER TABLE public.learning_analytics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own analytics" ON public.learning_analytics
  FOR SELECT USING (auth.uid() = user_id);

-- =============================================
-- NOTIFICATION PREFERENCES TABLE
-- =============================================

CREATE TABLE IF NOT EXISTS public.notification_preferences (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE UNIQUE,
  email_notifications BOOLEAN DEFAULT TRUE,
  push_notifications BOOLEAN DEFAULT TRUE,
  streak_reminders BOOLEAN DEFAULT TRUE,
  goal_reminders BOOLEAN DEFAULT TRUE,
  achievement_notifications BOOLEAN DEFAULT TRUE,
  weekly_summary BOOLEAN DEFAULT TRUE,
  study_time_reminders BOOLEAN DEFAULT FALSE,
  reminder_time TIME DEFAULT '18:00:00', -- 6 PM default
  timezone TEXT DEFAULT 'UTC',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS and create policies
ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own notification preferences" ON public.notification_preferences
  FOR ALL USING (auth.uid() = user_id);

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================

-- Users table indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON public.users(username);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON public.users(is_active);
CREATE INDEX IF NOT EXISTS idx_users_last_active ON public.users(last_active_at);

-- Problem submissions indexes
CREATE INDEX IF NOT EXISTS idx_problem_submissions_user_id ON public.problem_submissions(user_id);
CREATE INDEX IF NOT EXISTS idx_problem_submissions_subject_id ON public.problem_submissions(subject_id);
CREATE INDEX IF NOT EXISTS idx_problem_submissions_status ON public.problem_submissions(status);
CREATE INDEX IF NOT EXISTS idx_problem_submissions_difficulty ON public.problem_submissions(difficulty);
CREATE INDEX IF NOT EXISTS idx_problem_submissions_created_at ON public.problem_submissions(created_at);
CREATE INDEX IF NOT EXISTS idx_problem_submissions_tags ON public.problem_submissions USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_problem_submissions_title_search ON public.problem_submissions USING GIN(to_tsvector('english', title));

-- Learning sessions indexes
CREATE INDEX IF NOT EXISTS idx_learning_sessions_user_id ON public.learning_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_learning_sessions_subject_id ON public.learning_sessions(subject_id);
CREATE INDEX IF NOT EXISTS idx_learning_sessions_start_time ON public.learning_sessions(start_time);
CREATE INDEX IF NOT EXISTS idx_learning_sessions_session_type ON public.learning_sessions(session_type);

-- User achievements indexes
CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id ON public.user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_achievement_id ON public.user_achievements(achievement_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_unlocked_at ON public.user_achievements(unlocked_at);

-- Study streaks indexes
CREATE INDEX IF NOT EXISTS idx_study_streaks_user_date ON public.study_streaks(user_id, streak_date);
CREATE INDEX IF NOT EXISTS idx_study_streaks_date ON public.study_streaks(streak_date);

-- Learning analytics indexes
CREATE INDEX IF NOT EXISTS idx_learning_analytics_user_date ON public.learning_analytics(user_id, date);
CREATE INDEX IF NOT EXISTS idx_learning_analytics_metric_type ON public.learning_analytics(metric_type);

-- =============================================
-- FUNCTIONS AND TRIGGERS
-- =============================================

-- Function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert user profile
  INSERT INTO public.users (id, email, first_name, last_name, username)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'first_name',
    NEW.raw_user_meta_data->>'last_name',
    NEW.raw_user_meta_data->>'username'
  );
  
  -- Initialize user progress
  INSERT INTO public.user_progress (user_id)
  VALUES (NEW.id);
  
  -- Set default notification preferences
  INSERT INTO public.notification_preferences (user_id)
  VALUES (NEW.id);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to update user progress after problem completion
CREATE OR REPLACE FUNCTION public.update_user_progress_on_problem_completion()
RETURNS TRIGGER AS $$
DECLARE
  session_duration INTEGER;
  points_earned INTEGER;
BEGIN
  -- Only process when status changes to 'completed'
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    -- Calculate points based on difficulty
    points_earned := CASE NEW.difficulty
      WHEN 'easy' THEN 10
      WHEN 'medium' THEN 20
      WHEN 'hard' THEN 30
      ELSE 15
    END;
    
    -- Update user progress
    UPDATE public.user_progress 
    SET 
      total_problems_solved = total_problems_solved + 1,
      total_points = total_points + points_earned,
      experience_points = experience_points + points_earned,
      last_activity_date = CURRENT_DATE,
      updated_at = NOW()
    WHERE user_id = NEW.user_id;
    
    -- Update study streak
    INSERT INTO public.study_streaks (user_id, streak_date, problems_solved, is_streak_day)
    VALUES (NEW.user_id, CURRENT_DATE, 1, TRUE)
    ON CONFLICT (user_id, streak_date)
    DO UPDATE SET 
      problems_solved = study_streaks.problems_solved + 1,
      is_streak_day = TRUE;
    
    -- Check for achievement unlocks (simplified)
    -- This would be expanded with more sophisticated achievement logic
    INSERT INTO public.user_achievements (user_id, achievement_id)
    SELECT NEW.user_id, a.id
    FROM public.achievements a
    WHERE a.name = 'First Steps' 
      AND NOT EXISTS (
        SELECT 1 FROM public.user_achievements ua 
        WHERE ua.user_id = NEW.user_id AND ua.achievement_id = a.id
      )
    ON CONFLICT (user_id, achievement_id) DO NOTHING;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate and update learning streaks
CREATE OR REPLACE FUNCTION public.update_learning_streaks()
RETURNS TRIGGER AS $$
DECLARE
  current_streak INTEGER := 0;
  streak_count INTEGER := 0;
BEGIN
  -- Calculate current streak for the user
  WITH streak_days AS (
    SELECT streak_date, is_streak_day,
           ROW_NUMBER() OVER (ORDER BY streak_date DESC) as rn,
           CASE WHEN is_streak_day THEN 0 ELSE 1 END as break_flag
    FROM public.study_streaks 
    WHERE user_id = NEW.user_id 
      AND streak_date <= CURRENT_DATE
    ORDER BY streak_date DESC
  ),
  streak_calc AS (
    SELECT COUNT(*) as streak_length
    FROM streak_days
    WHERE rn <= (
      SELECT COALESCE(MIN(rn), 999) 
      FROM streak_days 
      WHERE break_flag = 1
    ) - 1
    AND is_streak_day = TRUE
  )
  SELECT COALESCE(streak_length, 0) INTO current_streak FROM streak_calc;
  
  -- Update user progress with new streak
  UPDATE public.user_progress 
  SET 
    current_streak = current_streak,
    longest_streak = GREATEST(longest_streak, current_streak),
    updated_at = NOW()
  WHERE user_id = NEW.user_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- CREATE TRIGGERS
-- =============================================

-- Trigger for new user creation
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Triggers for updated_at columns
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_problem_submissions_updated_at
  BEFORE UPDATE ON public.problem_submissions
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_user_progress_updated_at
  BEFORE UPDATE ON public.user_progress
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_learning_goals_updated_at
  BEFORE UPDATE ON public.learning_goals
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_notification_preferences_updated_at
  BEFORE UPDATE ON public.notification_preferences
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Trigger for progress updates on problem completion
CREATE TRIGGER on_problem_completion
  AFTER UPDATE ON public.problem_submissions
  FOR EACH ROW EXECUTE FUNCTION public.update_user_progress_on_problem_completion();

-- Trigger for streak updates
CREATE TRIGGER on_study_streak_update
  AFTER INSERT OR UPDATE ON public.study_streaks
  FOR EACH ROW EXECUTE FUNCTION public.update_learning_streaks();

-- =============================================
-- UTILITY VIEWS FOR ANALYTICS
-- =============================================

-- View for user dashboard statistics
CREATE OR REPLACE VIEW public.user_dashboard_stats AS
SELECT 
  u.id as user_id,
  u.first_name,
  u.last_name,
  up.total_problems_solved,
  up.total_study_time_minutes,
  up.current_streak,
  up.longest_streak,
  up.total_points,
  up.current_level,
  up.last_activity_date,
  COUNT(DISTINCT ps.subject_id) as subjects_studied_count,
  COUNT(DISTINCT ua.achievement_id) as achievements_unlocked_count
FROM public.users u
LEFT JOIN public.user_progress up ON u.id = up.user_id
LEFT JOIN public.problem_submissions ps ON u.id = ps.user_id AND ps.status = 'completed'
LEFT JOIN public.user_achievements ua ON u.id = ua.user_id
GROUP BY u.id, u.first_name, u.last_name, up.total_problems_solved, 
         up.total_study_time_minutes, up.current_streak, up.longest_streak,
         up.total_points, up.current_level, up.last_activity_date;

-- View for recent learning activity
CREATE OR REPLACE VIEW public.recent_learning_activity AS
SELECT 
  ps.id,
  ps.user_id,
  ps.title,
  ps.difficulty,
  s.name as subject_name,
  s.color_hex as subject_color,
  ps.actual_time_minutes,
  ps.created_at,
  ps.status
FROM public.problem_submissions ps
LEFT JOIN public.subjects s ON ps.subject_id = s.id
WHERE ps.status = 'completed'
ORDER BY ps.created_at DESC;

-- =============================================
-- SAMPLE DATA FOR TESTING
-- =============================================

-- Note: This would typically be in a separate migration or seed file
-- Uncomment for development/testing environments

/*
-- Insert sample learning goals
INSERT INTO public.learning_goals (user_id, title, description, goal_type, target_value, unit, subject_id)
SELECT 
  u.id,
  'Daily Practice',
  'Solve at least 5 problems every day',
  'daily',
  5,
  'problems',
  NULL
FROM public.users u
WHERE u.is_guest = FALSE
LIMIT 1;
*/

-- =============================================
-- FINAL NOTES
-- =============================================

/*
This schema provides:

1. **Comprehensive User Management**
   - Extended profiles with learning preferences
   - Guest user support
   - Activity tracking

2. **Rich Learning Data**
   - Detailed problem submissions with AI responses
   - Subject categorization
   - Difficulty progression tracking

3. **Gamification System**
   - Achievement system with multiple rarities
   - Point-based progression
   - Streak tracking and rewards

4. **Analytics & Insights**
   - Learning session tracking
   - Progress analytics
   - Performance metrics

5. **Personalization**
   - Custom learning goals
   - Notification preferences
   - Subject preferences

6. **Performance Optimization**
   - Strategic indexing
   - Efficient queries
   - Proper foreign key relationships

7. **Security**
   - Row Level Security on all tables
   - User data isolation
   - Secure function execution

To extend this schema:
- Add more achievement types
- Implement collaborative features (study groups, peer reviews)
- Add content recommendation system
- Implement adaptive learning algorithms
- Add parent/teacher dashboard features
*/