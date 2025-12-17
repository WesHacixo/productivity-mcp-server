-- Clean Supabase Schema for Productivity Tool
-- Uses INTEGER user_id (MySQL user.id) from the start - no migrations needed
-- SECURE: Internal database IDs, not external OAuth identifiers

-- Enable UUID extension (for task/goal IDs)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Tasks table
CREATE TABLE IF NOT EXISTS public.tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id INTEGER NOT NULL,  -- MySQL user.id (internal integer, not PII)
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  priority INTEGER DEFAULT 2,
  due_date TIMESTAMP WITH TIME ZONE NOT NULL,
  estimated_duration INTEGER DEFAULT 0,
  category TEXT DEFAULT 'work',
  completed BOOLEAN DEFAULT false,
  completed_at TIMESTAMP WITH TIME ZONE,
  recurring_frequency TEXT,
  recurring_interval INTEGER,
  recurring_end_date TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Subtasks table
CREATE TABLE IF NOT EXISTS public.subtasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  task_id UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  completed BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Goals table
CREATE TABLE IF NOT EXISTS public.goals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id INTEGER NOT NULL,  -- MySQL user.id (internal integer, not PII)
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  target_date TIMESTAMP WITH TIME ZONE NOT NULL,
  progress INTEGER DEFAULT 0,
  archived BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Milestones table
CREATE TABLE IF NOT EXISTS public.milestones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  goal_id UUID NOT NULL REFERENCES public.goals(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  target_date TIMESTAMP WITH TIME ZONE NOT NULL,
  completed BOOLEAN DEFAULT false,
  completed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Goal-Task relationships
CREATE TABLE IF NOT EXISTS public.goal_tasks (
  goal_id UUID NOT NULL REFERENCES public.goals(id) ON DELETE CASCADE,
  task_id UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
  PRIMARY KEY (goal_id, task_id)
);

-- Time blocks table
CREATE TABLE IF NOT EXISTS public.time_blocks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id INTEGER NOT NULL,  -- MySQL user.id
  task_id UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE NOT NULL,
  category TEXT DEFAULT 'work',
  actual_duration INTEGER,
  completed BOOLEAN DEFAULT false,
  completed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- File attachments table
CREATE TABLE IF NOT EXISTS public.file_attachments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  task_id UUID REFERENCES public.tasks(id) ON DELETE CASCADE,
  goal_id UUID REFERENCES public.goals(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  file_type TEXT NOT NULL,
  file_size INTEGER NOT NULL,
  file_url TEXT NOT NULL,
  parsed_data JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Inbox files table (for share sheet)
CREATE TABLE IF NOT EXISTS public.inbox_files (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id INTEGER NOT NULL,  -- MySQL user.id
  file_name TEXT NOT NULL,
  file_type TEXT NOT NULL,
  file_size INTEGER NOT NULL,
  file_url TEXT NOT NULL,
  processing_status TEXT DEFAULT 'pending',
  error_message TEXT,
  preview_data TEXT,
  received_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_tasks_user_id ON public.tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON public.tasks(due_date);
CREATE INDEX IF NOT EXISTS idx_tasks_completed ON public.tasks(completed);
CREATE INDEX IF NOT EXISTS idx_goals_user_id ON public.goals(user_id);
CREATE INDEX IF NOT EXISTS idx_goals_archived ON public.goals(archived);
CREATE INDEX IF NOT EXISTS idx_time_blocks_user_id ON public.time_blocks(user_id);
CREATE INDEX IF NOT EXISTS idx_time_blocks_start_time ON public.time_blocks(start_time);
CREATE INDEX IF NOT EXISTS idx_inbox_files_user_id ON public.inbox_files(user_id);

-- Enable Row Level Security (RLS)
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subtasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goal_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.time_blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.file_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inbox_files ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- For now, allow all operations for authenticated requests
-- You can tighten these later based on your auth setup

-- Tasks policies
CREATE POLICY "Allow all for authenticated users" ON public.tasks
  FOR ALL USING (true) WITH CHECK (true);

-- Goals policies
CREATE POLICY "Allow all for authenticated users" ON public.goals
  FOR ALL USING (true) WITH CHECK (true);

-- Subtasks policies
CREATE POLICY "Allow all for authenticated users" ON public.subtasks
  FOR ALL USING (true) WITH CHECK (true);

-- Milestones policies
CREATE POLICY "Allow all for authenticated users" ON public.milestones
  FOR ALL USING (true) WITH CHECK (true);

-- Time blocks policies
CREATE POLICY "Allow all for authenticated users" ON public.time_blocks
  FOR ALL USING (true) WITH CHECK (true);

-- Inbox files policies
CREATE POLICY "Allow all for authenticated users" ON public.inbox_files
  FOR ALL USING (true) WITH CHECK (true);

-- File attachments policies
CREATE POLICY "Allow all for authenticated users" ON public.file_attachments
  FOR ALL USING (true) WITH CHECK (true);
