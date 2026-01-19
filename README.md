# ShipBee Fulfillment Developer Test Project - Customer Support Widget System

## Project Overview

A simple yet powerful customer support widget system featuring an embeddable customer interface and an admin dashboard.

## Tech Stack

- **Frontend**: SvelteKit
- **Styling**: Tailwind CSS
- **Backend/Database**: Supabase
- **Real-time**: Supabase Realtime
- **Storage**: Supabase Storage (for file attachments)
- **Deployment**: Vercel/Netlify

## Database Schema (ERD)

### `tickets`

- `id` (uuid, PK)
- `customer_id` (uuid) - Identification for the customer session
- `subject` (text)
- `status` (text) - 'open', 'pending', 'resolved', 'closed'
- `created_at` (timestamp)
- `updated_at` (timestamp)

### `messages`

- `id` (uuid, PK)
- `ticket_id` (uuid, FK)
- `sender_type` (text) - 'customer' or 'admin'
- `content` (text)
- `created_at` (timestamp)

### `attachments`

- `id` (uuid, PK)
- `message_id` (uuid, FK)
- `file_path` (text)
- `file_name` (text)
- `content_type` (text)
- `size` (int)

## Implementation Plan

1. **Part 1**: Project Setup & Database Schema Design (Initial README & Migration Folder)
2. **Part 2**: Database Implementation (SQL Migrations, RPCs, Edge Functions)
3. **Part 3**: Admin Dashboard - Ticket Listing & Management
4. **Part 4**: Admin Dashboard - Real-time Chat & Replies
5. **Part 5**: Customer Widget - UI & Ticket Submission
6. **Part 6**: Customer Widget - File Uploads & History
7. **Part 7**: Final Polish & Real-time Status Updates

## Setup Instructions

### Database & Storage

1. Run the migrations in the `supabase/migrations` folder in your Supabase SQL Editor.
2. Ensure the `attachments` storage bucket is created and public (the storage migration handles this).

### Edge Functions

1. Deploy the `handle-new-ticket` function using the Supabase CLI:
   ```bash
   supabase functions deploy handle-new-ticket
   ```
2. Set up a **Database Webhook** in Supabase:
   - **Table**: `tickets`
   - **Events**: `INSERT`
   - **Type**: `HTTP Request`
   - **Method**: `POST`
   - **URL**: Your edge function URL
   - **Headers**: Authorization bearer with your service role key (or use a secret)

### Environment Variables

Create a `.env` file with:

```
VITE_SUPABASE_URL=your_supabase_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
```
