-- Initial Schema for Customer Support Widget System

-- 1. Create Tickets Table
CREATE TABLE IF NOT EXISTS tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL,
    subject TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'pending', 'resolved', 'closed')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create Messages Table
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
    sender_type TEXT NOT NULL CHECK (sender_type IN ('customer', 'admin')),
    content TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Create Attachments Table
CREATE TABLE IF NOT EXISTS attachments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    file_path TEXT NOT NULL,
    file_name TEXT NOT NULL,
    content_type TEXT,
    size INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Enable Row Level Security (RLS)
ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE attachments ENABLE ROW LEVEL SECURITY;

-- 5. Policies (Simplified for demo - in production these would be more strict)
-- For the widget (customer_id search)
CREATE POLICY "Customers can view their own tickets" ON tickets
    FOR SELECT USING (true); -- In a real app, we'd filter by customer_id provided in header/JWT

CREATE POLICY "Customers can create tickets" ON tickets
    FOR INSERT WITH CHECK (true);

-- For messages
CREATE POLICY "Anyone can view messages" ON messages
    FOR SELECT USING (true);

CREATE POLICY "Anyone can insert messages" ON messages
    FOR INSERT WITH CHECK (true);

-- 6. RPC: Close Ticket
CREATE OR REPLACE FUNCTION close_ticket(ticket_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE tickets SET status = 'closed', updated_at = NOW() WHERE id = ticket_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. RPC: Mark as Resolved
CREATE OR REPLACE FUNCTION resolve_ticket(ticket_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE tickets SET status = 'resolved', updated_at = NOW() WHERE id = ticket_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Realtime Enablement
ALTER PUBLICATION supabase_realtime ADD TABLE tickets;
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
