-- ACADIA Database Schema

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Profiles table (extends auth.users)
CREATE TABLE profiles (
    id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    full_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone_number TEXT NOT NULL,
    avatar_url TEXT,
    academic_level TEXT NOT NULL CHECK (academic_level IN ('high_school', 'university')),
    grade TEXT,
    stream TEXT,
    generation TEXT,
    university TEXT,
    year TEXT,
    semester TEXT,
    track TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Admin users table
CREATE TABLE admin_users (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    is_super_admin BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Subjects table
CREATE TABLE subjects (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    color TEXT NOT NULL,
    icon_url TEXT,
    academic_level TEXT NOT NULL,
    grade TEXT,
    stream TEXT,
    university_year TEXT,
    semester TEXT,
    track TEXT,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Chapters table
CREATE TABLE chapters (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    subject_id UUID REFERENCES subjects ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    unit_number INTEGER NOT NULL,
    order_index INTEGER DEFAULT 0,
    prerequisite_chapter_id UUID REFERENCES chapters,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Content table
CREATE TABLE content (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    chapter_id UUID REFERENCES chapters ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('video', 'shortNote', 'quiz', 'exam', 'flashcard', 'pastPaper')),
    cloud_storage_url TEXT,
    description TEXT,
    duration INTEGER,
    page_count INTEGER,
    question_count INTEGER,
    is_free BOOLEAN DEFAULT false,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    created_by UUID REFERENCES admin_users,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Payments table
CREATE TABLE payments (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles ON DELETE CASCADE NOT NULL,
    package_name TEXT NOT NULL,
    amount INTEGER NOT NULL,
    method TEXT NOT NULL CHECK (method IN ('telebirr', 'mpesa', 'cbe', 'cbo', 'awashBank')),
    user_account_number TEXT NOT NULL,
    transaction_reference TEXT NOT NULL,
    receipt_image_url TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    rejection_reason TEXT,
    approved_at TIMESTAMPTZ,
    approved_by UUID REFERENCES admin_users,
    validity_days INTEGER DEFAULT 365,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Purchases table (tracks unlocked packages)
CREATE TABLE purchases (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles ON DELETE CASCADE NOT NULL,
    package_name TEXT NOT NULL,
    payment_id UUID REFERENCES payments,
    valid_until TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- User progress table
CREATE TABLE user_progress (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles ON DELETE CASCADE NOT NULL,
    content_id UUID REFERENCES content ON DELETE CASCADE NOT NULL,
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMPTZ,
    progress_percentage INTEGER DEFAULT 0,
    time_spent_seconds INTEGER DEFAULT 0,
    UNIQUE(user_id, content_id)
);

-- Quiz results table
CREATE TABLE quiz_results (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles ON DELETE CASCADE NOT NULL,
    content_id UUID REFERENCES content ON DELETE CASCADE NOT NULL,
    score INTEGER NOT NULL,
    total_questions INTEGER NOT NULL,
    correct_answers INTEGER NOT NULL,
    wrong_answers INTEGER NOT NULL,
    time_taken_seconds INTEGER,
    answers JSONB,
    completed_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, content_id)
);

-- Exam results table
CREATE TABLE exam_results (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles ON DELETE CASCADE NOT NULL,
    content_id UUID REFERENCES content ON DELETE CASCADE NOT NULL,
    score INTEGER NOT NULL,
    total_questions INTEGER NOT NULL,
    correct_answers INTEGER NOT NULL,
    wrong_answers INTEGER NOT NULL,
    time_taken_seconds INTEGER,
    answers JSONB,
    is_passed BOOLEAN NOT NULL,
    completed_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, content_id)
);

-- Notifications table
CREATE TABLE notifications (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('payment', 'content', 'quiz', 'exam', 'achievement', 'system')),
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Flashcards table
CREATE TABLE flashcards (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    content_id UUID REFERENCES content ON DELETE CASCADE NOT NULL,
    front_text TEXT NOT NULL,
    back_text TEXT NOT NULL,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Quiz questions table
CREATE TABLE quiz_questions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    content_id UUID REFERENCES content ON DELETE CASCADE NOT NULL,
    question_text TEXT NOT NULL,
    options JSONB NOT NULL,
    correct_option_index INTEGER NOT NULL,
    explanation TEXT,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Study sessions table (for tracking study time)
CREATE TABLE study_sessions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles ON DELETE CASCADE NOT NULL,
    subject_id UUID REFERENCES subjects,
    chapter_id UUID REFERENCES chapters,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    duration_seconds INTEGER DEFAULT 0
);

-- Create indexes for performance
CREATE INDEX idx_profiles_academic ON profiles(academic_level, grade, stream);
CREATE INDEX idx_payments_user ON payments(user_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_content_chapter ON content(chapter_id);
CREATE INDEX idx_content_status ON content(status);
CREATE INDEX idx_notifications_user ON notifications(user_id, is_read);
CREATE INDEX idx_purchases_user ON purchases(user_id);
CREATE INDEX idx_progress_user ON user_progress(user_id);

-- Enable Row Level Security (RLS)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_sessions ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Profiles: Users can view/edit their own profile
CREATE POLICY "Users can view own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Payments: Users can view their own payments
CREATE POLICY "Users can view own payments" ON payments FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own payments" ON payments FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Purchases: Users can view their own purchases
CREATE POLICY "Users can view own purchases" ON purchases FOR SELECT USING (auth.uid() = user_id);

-- User progress: Users can view/update their own progress
CREATE POLICY "Users can view own progress" ON user_progress FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own progress" ON user_progress FOR ALL USING (auth.uid() = user_id);

-- Quiz results: Users can view their own results
CREATE POLICY "Users can view own quiz results" ON quiz_results FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own quiz results" ON quiz_results FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Exam results: Users can view their own results
CREATE POLICY "Users can view own exam results" ON exam_results FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own exam results" ON exam_results FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Notifications: Users can view their own notifications
CREATE POLICY "Users can view own notifications" ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own notifications" ON notifications FOR UPDATE USING (auth.uid() = user_id);

-- Study sessions: Users can view/update their own sessions
CREATE POLICY "Users can view own study sessions" ON study_sessions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own study sessions" ON study_sessions FOR ALL USING (auth.uid() = user_id);

-- Admin policies (admin users can view all)
CREATE POLICY "Admins can view all profiles" ON profiles FOR SELECT USING (EXISTS (SELECT 1 FROM admin_users WHERE email = auth.email()));
CREATE POLICY "Admins can view all payments" ON payments FOR SELECT USING (EXISTS (SELECT 1 FROM admin_users WHERE email = auth.email()));
CREATE POLICY "Admins can update payments" ON payments FOR UPDATE USING (EXISTS (SELECT 1 FROM admin_users WHERE email = auth.email()));

-- Public read access for approved content
CREATE POLICY "Public can view approved content" ON content FOR SELECT USING (status = 'approved');
CREATE POLICY "Public can view subjects" ON subjects FOR SELECT TO anon USING (true);
CREATE POLICY "Public can view chapters" ON chapters FOR SELECT TO anon USING (true);
CREATE POLICY "Public can view flashcards" ON flashcards FOR SELECT TO anon USING (true);
CREATE POLICY "Public can view quiz questions" ON quiz_questions FOR SELECT TO anon USING (true);

-- Functions

-- Function to check if user has access to content
CREATE OR REPLACE FUNCTION check_content_access(p_content_id UUID, p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_is_free BOOLEAN;
    v_has_purchase BOOLEAN;
    v_content_chapter_id UUID;
    v_subject_grade TEXT;
    v_user_grade TEXT;
BEGIN
    -- Get content details
    SELECT c.is_free, c.chapter_id INTO v_is_free, v_content_chapter_id
    FROM content c WHERE c.id = p_content_id;
    
    -- Free content is accessible
    IF v_is_free THEN
        RETURN true;
    END IF;
    
    -- Check if user has purchased the relevant package
    -- This is simplified; actual logic depends on content structure
    SELECT EXISTS(
        SELECT 1 FROM purchases p 
        WHERE p.user_id = p_user_id 
        AND p.valid_until > now()
    ) INTO v_has_purchase;
    
    RETURN v_has_purchase;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to handle new user signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO profiles (id, full_name, email, phone_number, academic_level)
    VALUES (
        NEW.id,
        NEW.raw_user_meta_data->>'full_name',
        NEW.email,
        NEW.raw_user_meta_data->>'phone_number',
        COALESCE(NEW.raw_user_meta_data->>'academic_level', 'high_school')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();
