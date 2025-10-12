-- ============================================
-- FINAL FIX: Rename paid_at to paid_date
-- Run this in Supabase SQL Editor
-- Project: xumzpeenrfgyznlmzuva
-- ============================================

-- This is the ONLY change needed!
ALTER TABLE penalties 
RENAME COLUMN paid_at TO paid_date;

-- Verify the change
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'penalties' 
  AND column_name IN ('paid_at', 'paid_date');

-- If you see 'paid_date' and NOT 'paid_at', it worked! ✅

