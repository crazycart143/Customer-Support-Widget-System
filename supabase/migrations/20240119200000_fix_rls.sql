-- Fix missing RLS policies

-- Enable RLS (already enabled but making sure)
ALTER TABLE attachments ENABLE ROW LEVEL SECURITY;

-- 1. Policies for attachments table
CREATE POLICY "Anyone can view attachments" ON attachments
    FOR SELECT USING (true);

CREATE POLICY "Anyone can insert attachments" ON attachments
    FOR INSERT WITH CHECK (true);

-- 2. Policy for updating tickets (needed for updated_at)
CREATE POLICY "Anyone can update tickets" ON tickets
    FOR UPDATE USING (true) WITH CHECK (true);
