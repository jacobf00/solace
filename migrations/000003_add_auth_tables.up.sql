-- Migration: 000003_add_auth_tables.up.sql
-- Description: Add authentication and session management tables
-- Created: 2024-01-01
-- Author: System

-- Create sessions table for JWT session tracking
CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    user_agent TEXT,
    ip_address INET
);

-- Create refresh_tokens table for JWT refresh token management
CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    revoked_at TIMESTAMP WITH TIME ZONE,
    replaced_by_token_id UUID REFERENCES refresh_tokens(id)
);

-- Create password_resets table for password reset functionality
CREATE TABLE password_resets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    used_at TIMESTAMP WITH TIME ZONE
);

-- Create email_verifications table for email verification
CREATE TABLE email_verifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    verified_at TIMESTAMP WITH TIME ZONE
);

-- Create indexes for performance
CREATE INDEX idx_sessions_user_id ON sessions(user_id);
CREATE INDEX idx_sessions_expires_at ON sessions(expires_at);
CREATE INDEX idx_sessions_token_hash ON sessions(token_hash);

CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_expires_at ON refresh_tokens(expires_at);
CREATE INDEX idx_refresh_tokens_token_hash ON refresh_tokens(token_hash);
CREATE INDEX idx_refresh_tokens_revoked_at ON refresh_tokens(revoked_at);

CREATE INDEX idx_password_resets_user_id ON password_resets(user_id);
CREATE INDEX idx_password_resets_expires_at ON password_resets(expires_at);
CREATE INDEX idx_password_resets_token_hash ON password_resets(token_hash);

CREATE INDEX idx_email_verifications_user_id ON email_verifications(user_id);
CREATE INDEX idx_email_verifications_expires_at ON email_verifications(expires_at);
CREATE INDEX idx_email_verifications_token_hash ON email_verifications(token_hash);

-- Add comments for documentation
COMMENT ON TABLE sessions IS 'Active user sessions for JWT token tracking';
COMMENT ON TABLE refresh_tokens IS 'Refresh tokens for JWT authentication with rotation support';
COMMENT ON TABLE password_resets IS 'Password reset tokens for secure password recovery';
COMMENT ON TABLE email_verifications IS 'Email verification tokens for account activation';

COMMENT ON COLUMN sessions.token_hash IS 'Hashed JWT access token for session tracking';
COMMENT ON COLUMN refresh_tokens.token_hash IS 'Hashed refresh token for JWT rotation';
COMMENT ON COLUMN refresh_tokens.replaced_by_token_id IS 'Token that replaced this one during rotation';
COMMENT ON COLUMN password_resets.token_hash IS 'Hashed password reset token';
COMMENT ON COLUMN email_verifications.token_hash IS 'Hashed email verification token';
