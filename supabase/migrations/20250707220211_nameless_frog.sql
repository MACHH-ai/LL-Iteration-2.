/*
  # Complete Luminara Learning App Database Schema
  
  This migration creates a comprehensive database structure for the Luminara learning app,
  including the crucial prompts system that provides guided educational responses.
  
  ## Key Features:
  1. **Prompts System**: Core educational prompts that guide AI responses
  2. **User Management**: Extended user profiles with learning preferences  
  3. **Problem Submissions**: Enhanced with prompt-guided solutions
  4. **Learning Analytics**: Comprehensive progress tracking
  5. **Gamification**: Achievement and progression systems
  6. **Personalization**: Custom goals and preferences
  
  ## Security:
  - Row Level Security (RLS) enabled on all tables
  - Users can only access their own data
  - Secure function execution
  
  ## Performance:
  - Strategic indexing on frequently queried columns
  - Full-text search capabilities
  - Optimized views for dashboard queries
*/

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- =============================================
-- CORE TABLES
-- =============================================

-- Users table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.users (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  first_name TEXT,
  last_name TEXT,
  username TEXT UNIQUE,
  avatar_url TEXT,
  is_guest BOOLEAN DEFAULT FALSE,
  grade_level TEXT,
  preferred_language TEXT DEFAULT 'en',
  timezone TEXT DEFAULT 'UTC',
  learning_preferences JSONB DEFAULT '{}',
  notification_preferences JSONB DEFAULT '{
    "email_notifications": true,
    "push_notifications": true,
    "achievement_alerts": true,
    "daily_reminders": true,
    "weekly_summaries": true
  }',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- PROMPTS SYSTEM - THE CORE OF EDUCATIONAL GUIDANCE
-- =============================================

-- Subjects for organizing prompts
CREATE TABLE IF NOT EXISTS public.subjects (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  icon TEXT,
  color TEXT DEFAULT '#8A2BE2',
  grade_levels TEXT[] DEFAULT '{}',
  difficulty_levels TEXT[] DEFAULT ARRAY['easy', 'medium', 'hard'],
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Educational prompts - the heart of guided learning
CREATE TABLE IF NOT EXISTS public.prompts (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  subject_id UUID REFERENCES public.subjects(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  
  -- The actual prompt template that guides AI responses
  prompt_template TEXT NOT NULL,
  
  -- Input type this prompt is designed for
  input_type TEXT CHECK (input_type IN ('text', 'image', 'voice', 'any')) DEFAULT 'any',
  
  -- Educational metadata
  difficulty_level TEXT CHECK (difficulty_level IN ('easy', 'medium', 'hard')) DEFAULT 'medium',
  grade_levels TEXT[] DEFAULT '{}',
  learning_objectives TEXT[],
  keywords TEXT[],
  
  -- Prompt behavior settings
  max_tokens INTEGER DEFAULT 2048,
  temperature DECIMAL(3,2) DEFAULT 0.7,
  requires_step_by_step BOOLEAN DEFAULT TRUE,
  includes_examples BOOLEAN DEFAULT TRUE,
  encourages_exploration BOOLEAN DEFAULT TRUE,
  
  -- Usage and effectiveness tracking
  usage_count INTEGER DEFAULT 0,
  average_rating DECIMAL(3,2) DEFAULT 0,
  effectiveness_score DECIMAL(3,2) DEFAULT 0,
  
  -- Administrative
  is_active BOOLEAN DEFAULT TRUE,
  created_by UUID REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Prompt variations for A/B testing and optimization
CREATE TABLE IF NOT EXISTS public.prompt_variations (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  prompt_id UUID REFERENCES public.prompts(id) ON DELETE CASCADE,
  variation_name TEXT NOT NULL,
  prompt_template TEXT NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  usage_count INTEGER DEFAULT 0,
  success_rate DECIMAL(3,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- PROBLEM SUBMISSIONS WITH PROMPT INTEGRATION
-- =============================================

CREATE TABLE IF NOT EXISTS public.problem_submissions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  
  -- Basic problem information
  title TEXT NOT NULL,
  description TEXT,
  input_type TEXT CHECK (input_type IN ('text', 'image', 'voice')) NOT NULL,
  
  -- Input content
  text_content TEXT,
  image_url TEXT,
  voice_url TEXT,
  
  -- PROMPT INTEGRATION - This is key!
  prompt_id UUID REFERENCES public.prompts(id),
  prompt_variation_id UUID REFERENCES public.prompt_variations(id),
  final_prompt_used TEXT, -- The actual prompt sent to AI after template processing
  
  -- AI Response and Analysis
  solution TEXT,
  explanation TEXT,
  step_by_step_solution JSONB,
  ai_response JSONB,
  ai_model_used TEXT DEFAULT 'gemini-pro',
  
  -- Educational Classification
  subject_id UUID REFERENCES public.subjects(id),
  difficulty TEXT CHECK (difficulty IN ('easy', 'medium', 'hard')),
  topics TEXT[],
  tags TEXT[],
  learning_objectives_met TEXT[],
  
  -- Processing Information
  status TEXT CHECK (status IN ('pending', 'processing', 'completed', 'error')) DEFAULT 'pending',
  error_message TEXT,
  processing_time_ms INTEGER,
  
  -- User Interaction
  user_rating INTEGER CHECK (user_rating >= 1 AND user_rating <= 5),
  user_feedback TEXT,
  time_spent_minutes INTEGER,
  confidence_score INTEGER CHECK (confidence_score >= 1 AND confidence_score <= 10),
  
  -- Metadata
  device_info JSONB,
  session_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- LEARNING ANALYTICS AND PROGRESS
-- =============================================

-- User progress tracking
CREATE TABLE IF NOT EXISTS public.user_progress (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE UNIQUE,
  
  -- Basic Statistics
  problems_solved INTEGER DEFAULT 0,
  total_study_time_minutes INTEGER DEFAULT 0,
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  
  -- Gamification
  total_points INTEGER DEFAULT 0,
  level INTEGER DEFAULT 1,
  experience_points INTEGER DEFAULT 0,
  
  -- Subject-specific progress
  subjects_studied TEXT[] DEFAULT '{}',
  favorite_subjects TEXT[] DEFAULT '{}',
  
  -- Learning Analytics
  average_session_duration INTEGER DEFAULT 0,
  preferred_difficulty TEXT DEFAULT 'medium',
  learning_velocity DECIMAL(5,2) DEFAULT 0, -- problems per hour
  accuracy_rate DECIMAL(3,2) DEFAULT 0,
  
  -- Timestamps
  last_activity_date DATE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Learning sessions for detailed analytics
CREATE TABLE IF NOT EXISTS public.learning_sessions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  
  -- Session Information
  session_start TIMESTAMPTZ DEFAULT NOW(),
  session_end TIMESTAMPTZ,
  duration_minutes INTEGER,
  
  -- Session Content
  problems_attempted INTEGER DEFAULT 0,
  problems_completed INTEGER DEFAULT 0,
  subjects_covered TEXT[],
  difficulty_levels TEXT[],
  
  -- Session Quality Metrics
  focus_score INTEGER CHECK (focus_score >= 1 AND focus_score <= 10),
  engagement_score INTEGER CHECK (engagement_score >= 1 AND engagement_score <= 10),
  satisfaction_rating INTEGER CHECK (satisfaction_rating >= 1 AND satisfaction_rating <= 5),
  
  -- Technical Information
  device_type TEXT,
  platform TEXT,
  app_version TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Flexible analytics for storing various learning metrics
CREATE TABLE IF NOT EXISTS public.learning_analytics (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  metric_name TEXT NOT NULL,
  metric_value DECIMAL(10,2),
  metric_data JSONB,
  date_recorded DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- GAMIFICATION SYSTEM
-- =============================================

-- Achievement definitions
CREATE TABLE IF NOT EXISTS public.achievements (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  description TEXT NOT NULL,
  icon TEXT,
  category TEXT,
  rarity TEXT CHECK (rarity IN ('common', 'rare', 'epic', 'legendary')) DEFAULT 'common',
  
  -- Achievement Criteria
  criteria JSONB NOT NULL, -- Flexible criteria definition
  points_reward INTEGER DEFAULT 0,
  
  -- Requirements
  required_level INTEGER DEFAULT 1,
  prerequisite_achievements UUID[],
  
  -- Metadata
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User achievements (unlocked achievements)
CREATE TABLE IF NOT EXISTS public.user_achievements (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  achievement_id UUID REFERENCES public.achievements(id) ON DELETE CASCADE,
  
  -- Progress tracking
  progress INTEGER DEFAULT 0,
  max_progress INTEGER DEFAULT 1,
  is_completed BOOLEAN DEFAULT FALSE,
  
  -- Unlock information
  unlocked_at TIMESTAMPTZ,
  points_earned INTEGER DEFAULT 0,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id, achievement_id)
);

-- =============================================
-- PERSONALIZATION
-- =============================================

-- Learning goals
CREATE TABLE IF NOT EXISTS public.learning_goals (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  
  -- Goal Information
  title TEXT NOT NULL,
  description TEXT,
  goal_type TEXT CHECK (goal_type IN ('daily', 'weekly', 'monthly', 'custom')) NOT NULL,
  
  -- Target and Progress
  target_value INTEGER NOT NULL,
  current_progress INTEGER DEFAULT 0,
  metric_type TEXT NOT NULL, -- 'problems_solved', 'study_time', 'subjects_covered', etc.
  
  -- Timeline
  start_date DATE DEFAULT CURRENT_DATE,
  end_date DATE,
  
  -- Status
  is_active BOOLEAN DEFAULT TRUE,
  is_completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User feedback on AI solutions for continuous improvement
CREATE TABLE IF NOT EXISTS public.solution_feedback (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  problem_submission_id UUID REFERENCES public.problem_submissions(id) ON DELETE CASCADE,
  prompt_id UUID REFERENCES public.prompts(id),
  
  -- Feedback Details
  rating INTEGER CHECK (rating >= 1 AND rating <= 5) NOT NULL,
  feedback_type TEXT CHECK (feedback_type IN ('helpful', 'confusing', 'incorrect', 'incomplete', 'excellent')),
  feedback_text TEXT,
  
  -- Specific Feedback Categories
  clarity_rating INTEGER CHECK (clarity_rating >= 1 AND clarity_rating <= 5),
  accuracy_rating INTEGER CHECK (accuracy_rating >= 1 AND accuracy_rating <= 5),
  completeness_rating INTEGER CHECK (completeness_rating >= 1 AND completeness_rating <= 5),
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- ENABLE ROW LEVEL SECURITY
-- =============================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prompts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prompt_variations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.problem_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learning_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learning_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learning_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.solution_feedback ENABLE ROW LEVEL SECURITY;

-- =============================================
-- ROW LEVEL SECURITY POLICIES
-- =============================================

-- Users policies
CREATE POLICY "Users can view own profile" ON public.users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Subjects are publicly readable
CREATE POLICY "Subjects are publicly readable" ON public.subjects
  FOR SELECT USING (true);

-- Prompts are publicly readable (for educational content)
CREATE POLICY "Prompts are publicly readable" ON public.prompts
  FOR SELECT USING (is_active = true);

CREATE POLICY "Prompt variations are publicly readable" ON public.prompt_variations
  FOR SELECT USING (is_active = true);

-- Problem submissions - users can only access their own
CREATE POLICY "Users can view own submissions" ON public.problem_submissions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own submissions" ON public.problem_submissions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own submissions" ON public.problem_submissions
  FOR UPDATE USING (auth.uid() = user_id);

-- User progress - users can only access their own
CREATE POLICY "Users can view own progress" ON public.user_progress
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own progress" ON public.user_progress
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own progress" ON public.user_progress
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Learning sessions - users can only access their own
CREATE POLICY "Users can view own sessions" ON public.learning_sessions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own sessions" ON public.learning_sessions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own sessions" ON public.learning_sessions
  FOR UPDATE USING (auth.uid() = user_id);

-- Learning analytics - users can only access their own
CREATE POLICY "Users can view own analytics" ON public.learning_analytics
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own analytics" ON public.learning_analytics
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Achievements are publicly readable
CREATE POLICY "Achievements are publicly readable" ON public.achievements
  FOR SELECT USING (is_active = true);

-- User achievements - users can only access their own
CREATE POLICY "Users can view own achievements" ON public.user_achievements
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own achievements" ON public.user_achievements
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own achievements" ON public.user_achievements
  FOR UPDATE USING (auth.uid() = user_id);

-- Learning goals - users can only access their own
CREATE POLICY "Users can view own goals" ON public.learning_goals
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own goals" ON public.learning_goals
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own goals" ON public.learning_goals
  FOR UPDATE USING (auth.uid() = user_id);

-- Solution feedback - users can only access their own
CREATE POLICY "Users can view own feedback" ON public.solution_feedback
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own feedback" ON public.solution_feedback
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- =============================================
-- FUNCTIONS AND TRIGGERS
-- =============================================

-- Function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, first_name, last_name, username)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'first_name',
    NEW.raw_user_meta_data->>'last_name',
    NEW.raw_user_meta_data->>'username'
  );
  
  INSERT INTO public.user_progress (user_id)
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

-- Function to calculate user level based on experience points
CREATE OR REPLACE FUNCTION public.calculate_user_level(experience_points INTEGER)
RETURNS INTEGER AS $$
BEGIN
  -- Simple level calculation: level = sqrt(experience_points / 100) + 1
  RETURN FLOOR(SQRT(experience_points / 100.0)) + 1;
END;
$$ LANGUAGE plpgsql;

-- Function to update user progress when a problem is completed
CREATE OR REPLACE FUNCTION public.update_user_progress_on_completion()
RETURNS TRIGGER AS $$
DECLARE
  points_earned INTEGER := 0;
  time_spent INTEGER := 0;
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
    
    -- Add bonus points for high user rating
    IF NEW.user_rating >= 4 THEN
      points_earned := points_earned + 5;
    END IF;
    
    -- Get time spent (convert from milliseconds to minutes)
    time_spent := COALESCE(NEW.processing_time_ms / 60000, 0);
    
    -- Update user progress
    INSERT INTO public.user_progress (
      user_id, problems_solved, total_study_time_minutes, total_points, experience_points
    ) VALUES (
      NEW.user_id, 1, time_spent, points_earned, points_earned
    )
    ON CONFLICT (user_id) DO UPDATE SET
      problems_solved = user_progress.problems_solved + 1,
      total_study_time_minutes = user_progress.total_study_time_minutes + time_spent,
      total_points = user_progress.total_points + points_earned,
      experience_points = user_progress.experience_points + points_earned,
      level = public.calculate_user_level(user_progress.experience_points + points_earned),
      last_activity_date = CURRENT_DATE,
      updated_at = NOW();
    
    -- Update prompt usage statistics
    IF NEW.prompt_id IS NOT NULL THEN
      UPDATE public.prompts 
      SET usage_count = usage_count + 1,
          average_rating = (
            SELECT AVG(user_rating::DECIMAL) 
            FROM public.problem_submissions 
            WHERE prompt_id = NEW.prompt_id AND user_rating IS NOT NULL
          )
      WHERE id = NEW.prompt_id;
    END IF;
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- TRIGGERS
-- =============================================

-- Trigger for new user creation
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Updated_at triggers
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_subjects_updated_at
  BEFORE UPDATE ON public.subjects
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_prompts_updated_at
  BEFORE UPDATE ON public.prompts
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

-- Progress update trigger
CREATE TRIGGER on_problem_completion
  AFTER UPDATE ON public.problem_submissions
  FOR EACH ROW EXECUTE FUNCTION public.update_user_progress_on_completion();

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================

-- Users indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON public.users(username);
CREATE INDEX IF NOT EXISTS idx_users_is_guest ON public.users(is_guest);

-- Prompts indexes
CREATE INDEX IF NOT EXISTS idx_prompts_subject_id ON public.prompts(subject_id);
CREATE INDEX IF NOT EXISTS idx_prompts_input_type ON public.prompts(input_type);
CREATE INDEX IF NOT EXISTS idx_prompts_difficulty ON public.prompts(difficulty_level);
CREATE INDEX IF NOT EXISTS idx_prompts_active ON public.prompts(is_active);
CREATE INDEX IF NOT EXISTS idx_prompts_keywords ON public.prompts USING GIN(keywords);
CREATE INDEX IF NOT EXISTS idx_prompts_grade_levels ON public.prompts USING GIN(grade_levels);

-- Problem submissions indexes
CREATE INDEX IF NOT EXISTS idx_problem_submissions_user_id ON public.problem_submissions(user_id);
CREATE INDEX IF NOT EXISTS idx_problem_submissions_status ON public.problem_submissions(status);
CREATE INDEX IF NOT EXISTS idx_problem_submissions_subject_id ON public.problem_submissions(subject_id);
CREATE INDEX IF NOT EXISTS idx_problem_submissions_prompt_id ON public.problem_submissions(prompt_id);
CREATE INDEX IF NOT EXISTS idx_problem_submissions_created_at ON public.problem_submissions(created_at);
CREATE INDEX IF NOT EXISTS idx_problem_submissions_difficulty ON public.problem_submissions(difficulty);

-- Full-text search index for problem titles
CREATE INDEX IF NOT EXISTS idx_problem_submissions_title_search 
  ON public.problem_submissions USING GIN(to_tsvector('english', title));

-- Learning analytics indexes
CREATE INDEX IF NOT EXISTS idx_learning_analytics_user_id ON public.learning_analytics(user_id);
CREATE INDEX IF NOT EXISTS idx_learning_analytics_metric_name ON public.learning_analytics(metric_name);
CREATE INDEX IF NOT EXISTS idx_learning_analytics_date ON public.learning_analytics(date_recorded);

-- User achievements indexes
CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id ON public.user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_completed ON public.user_achievements(is_completed);

-- =============================================
-- SAMPLE DATA INSERTION
-- =============================================

-- Insert default subjects
INSERT INTO public.subjects (name, description, icon, color, grade_levels) VALUES
  ('Mathematics', 'Numbers, algebra, geometry, and problem-solving', 'calculator', '#FF6B6B', ARRAY['elementary', 'middle', 'high', 'college']),
  ('Science', 'Physics, chemistry, biology, and earth sciences', 'atom', '#4ECDC4', ARRAY['elementary', 'middle', 'high', 'college']),
  ('English', 'Reading, writing, grammar, and literature', 'book-open', '#45B7D1', ARRAY['elementary', 'middle', 'high', 'college']),
  ('History', 'World history, civics, and social studies', 'scroll', '#96CEB4', ARRAY['elementary', 'middle', 'high', 'college']),
  ('Computer Science', 'Programming, algorithms, and technology', 'monitor', '#FFEAA7', ARRAY['middle', 'high', 'college']),
  ('Art', 'Visual arts, music, and creative expression', 'palette', '#DDA0DD', ARRAY['elementary', 'middle', 'high', 'college'])
ON CONFLICT (name) DO NOTHING;

-- Insert sample educational prompts
INSERT INTO public.prompts (subject_id, title, description, prompt_template, input_type, difficulty_level, grade_levels, learning_objectives, keywords) VALUES
  (
    (SELECT id FROM public.subjects WHERE name = 'Mathematics'),
    'Step-by-Step Math Problem Solver',
    'Guides students through mathematical problems with detailed explanations',
    'You are a patient and encouraging math tutor. The student has submitted this problem: {user_input}

Please provide:
1. A clear, step-by-step solution
2. Explanation of each mathematical concept used
3. Tips for solving similar problems
4. A practice problem for reinforcement

Make your explanation appropriate for a {grade_level} student. Use encouraging language and check for understanding at each step.',
    'any',
    'medium',
    ARRAY['elementary', 'middle', 'high'],
    ARRAY['problem-solving', 'mathematical reasoning', 'step-by-step thinking'],
    ARRAY['math', 'algebra', 'geometry', 'arithmetic', 'problem-solving']
  ),
  (
    (SELECT id FROM public.subjects WHERE name = 'Science'),
    'Science Concept Explorer',
    'Helps students understand scientific concepts through inquiry-based learning',
    'You are an enthusiastic science teacher. The student is asking about: {user_input}

Please provide:
1. A clear explanation of the scientific concept
2. Real-world examples and applications
3. Simple experiments or observations they can try
4. Connection to other scientific principles
5. Questions to encourage further exploration

Use age-appropriate language for a {grade_level} student and encourage scientific curiosity.',
    'any',
    'medium',
    ARRAY['elementary', 'middle', 'high'],
    ARRAY['scientific inquiry', 'conceptual understanding', 'real-world connections'],
    ARRAY['science', 'physics', 'chemistry', 'biology', 'experiments']
  ),
  (
    (SELECT id FROM public.subjects WHERE name = 'English'),
    'Writing and Reading Comprehension Guide',
    'Supports students in developing reading and writing skills',
    'You are a supportive English teacher. The student needs help with: {user_input}

Please provide:
1. Clear guidance on the topic
2. Examples and models when appropriate
3. Specific strategies for improvement
4. Encouragement and positive feedback
5. Next steps for continued learning

Adapt your language and examples for a {grade_level} student. Focus on building confidence in communication skills.',
    'any',
    'medium',
    ARRAY['elementary', 'middle', 'high'],
    ARRAY['reading comprehension', 'writing skills', 'communication'],
    ARRAY['english', 'writing', 'reading', 'grammar', 'literature']
  )
ON CONFLICT DO NOTHING;

-- Insert sample achievements
INSERT INTO public.achievements (name, description, icon, category, rarity, criteria, points_reward) VALUES
  ('First Steps', 'Complete your first problem', 'star', 'getting_started', 'common', '{"problems_solved": 1}', 10),
  ('Problem Solver', 'Solve 10 problems', 'target', 'progress', 'common', '{"problems_solved": 10}', 50),
  ('Dedicated Learner', 'Solve 50 problems', 'trophy', 'progress', 'rare', '{"problems_solved": 50}', 200),
  ('Math Whiz', 'Solve 25 math problems', 'calculator', 'subject', 'rare', '{"subject": "Mathematics", "problems_solved": 25}', 150),
  ('Science Explorer', 'Solve 25 science problems', 'atom', 'subject', 'rare', '{"subject": "Science", "problems_solved": 25}', 150),
  ('Streak Master', 'Maintain a 7-day learning streak', 'flame', 'consistency', 'epic', '{"streak_days": 7}', 300),
  ('Speed Demon', 'Solve 5 problems in one session', 'zap', 'performance', 'rare', '{"problems_per_session": 5}', 100),
  ('Perfectionist', 'Get 10 problems rated 5 stars', 'award', 'quality', 'epic', '{"five_star_ratings": 10}', 250),
  ('Learning Legend', 'Reach level 10', 'crown', 'milestone', 'legendary', '{"level": 10}', 500),
  ('Knowledge Seeker', 'Study for 10 hours total', 'clock', 'dedication', 'rare', '{"study_hours": 10}', 200),
  ('Subject Master', 'Complete problems in 5 different subjects', 'book-open', 'exploration', 'epic', '{"subjects_count": 5}', 400)
ON CONFLICT (name) DO NOTHING;

-- =============================================
-- VIEWS FOR COMMON QUERIES
-- =============================================

-- User dashboard statistics view
CREATE OR REPLACE VIEW public.user_dashboard_stats AS
SELECT 
  u.id as user_id,
  u.first_name,
  u.last_name,
  up.level,
  up.total_points,
  up.problems_solved,
  up.total_study_time_minutes,
  up.current_streak,
  up.longest_streak,
  COUNT(DISTINCT ps.subject_id) as subjects_studied_count,
  COUNT(DISTINCT ua.achievement_id) as achievements_unlocked,
  AVG(ps.user_rating) as average_rating
FROM public.users u
LEFT JOIN public.user_progress up ON u.id = up.user_id
LEFT JOIN public.problem_submissions ps ON u.id = ps.user_id AND ps.status = 'completed'
LEFT JOIN public.user_achievements ua ON u.id = ua.user_id AND ua.is_completed = true
GROUP BY u.id, u.first_name, u.last_name, up.level, up.total_points, up.problems_solved, 
         up.total_study_time_minutes, up.current_streak, up.longest_streak;

-- Recent activity view
CREATE OR REPLACE VIEW public.user_recent_activity AS
SELECT 
  ps.user_id,
  ps.id as submission_id,
  ps.title,
  s.name as subject_name,
  s.color as subject_color,
  ps.difficulty,
  ps.user_rating,
  ps.time_spent_minutes,
  ps.created_at
FROM public.problem_submissions ps
LEFT JOIN public.subjects s ON ps.subject_id = s.id
WHERE ps.status = 'completed'
ORDER BY ps.created_at DESC;

-- Prompt effectiveness view
CREATE OR REPLACE VIEW public.prompt_effectiveness AS
SELECT 
  p.id,
  p.title,
  p.subject_id,
  s.name as subject_name,
  p.usage_count,
  p.average_rating,
  COUNT(ps.id) as total_submissions,
  COUNT(CASE WHEN ps.status = 'completed' THEN 1 END) as successful_submissions,
  ROUND(
    COUNT(CASE WHEN ps.status = 'completed' THEN 1 END)::DECIMAL / 
    NULLIF(COUNT(ps.id), 0) * 100, 2
  ) as success_rate,
  AVG(ps.user_rating) as user_satisfaction
FROM public.prompts p
LEFT JOIN public.subjects s ON p.subject_id = s.id
LEFT JOIN public.problem_submissions ps ON p.id = ps.prompt_id
WHERE p.is_active = true
GROUP BY p.id, p.title, p.subject_id, s.name, p.usage_count, p.average_rating
ORDER BY success_rate DESC, user_satisfaction DESC;

-- =============================================
-- COMPLETION MESSAGE
-- =============================================

-- Log successful completion
DO $$
BEGIN
  RAISE NOTICE 'Luminara database schema created successfully!';
  RAISE NOTICE 'Key features implemented:';
  RAISE NOTICE '- ✅ Prompts system for guided learning';
  RAISE NOTICE '- ✅ User management with learning preferences';
  RAISE NOTICE '- ✅ Problem submissions with prompt integration';
  RAISE NOTICE '- ✅ Comprehensive learning analytics';
  RAISE NOTICE '- ✅ Gamification with achievements and levels';
  RAISE NOTICE '- ✅ Personalization with goals and feedback';
  RAISE NOTICE '- ✅ Row Level Security enabled';
  RAISE NOTICE '- ✅ Performance indexes created';
  RAISE NOTICE '- ✅ Sample data inserted';
  RAISE NOTICE '';
  RAISE NOTICE 'Next steps:';
  RAISE NOTICE '1. Update your Edge Functions to use the prompts system';
  RAISE NOTICE '2. Test the authentication flow';
  RAISE NOTICE '3. Verify the sample prompts work correctly';
  RAISE NOTICE '4. Customize prompts for your specific curriculum';
END $$;