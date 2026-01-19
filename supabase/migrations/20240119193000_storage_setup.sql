-- Add Storage Bucket for Attachments

-- 1. Create a bucket
INSERT INTO storage.buckets (id, name, public) VALUES ('attachments', 'attachments', true);

-- 2. Storage Policies
CREATE POLICY "Public Access" ON storage.objects FOR SELECT USING (bucket_id = 'attachments');
CREATE POLICY "Anyone can upload" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'attachments');

-- 3. Add helper columns to attachments if not already present
-- (Already handled in initial schema: file_path, file_name, content_type, size)
