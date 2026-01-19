package ai

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

// Client represents the OpenRouter API client
type Client struct {
	apiKey     string
	baseURL    string
	httpClient *http.Client
}

// NewClient creates a new OpenRouter API client
func NewClient(apiKey string) *Client {
	return &Client{
		apiKey:  apiKey,
		baseURL: "https://openrouter.ai/api/v1",
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// Message represents a chat message
type Message struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

// ChatRequest represents a chat completion request
type ChatRequest struct {
	Model    string    `json:"model"`
	Messages []Message `json:"messages"`
}

// ChatResponse represents a chat completion response
type ChatResponse struct {
	Choices []struct {
		Message Message `json:"message"`
	} `json:"choices"`
}

// GenerateAdvice generates Biblical advice for a problem using relevant verses
func (c *Client) GenerateAdvice(ctx context.Context, problemDescription string, verses []string) (string, error) {
	// Build prompt
	prompt := c.buildAdvicePrompt(problemDescription, verses)

	req := ChatRequest{
		Model: "openai/gpt-oss-20b", // Large open-source model (405B parameters)
		Messages: []Message{
			{
				Role:    "user",
				Content: prompt,
			},
		},
	}

	jsonData, err := json.Marshal(req)
	if err != nil {
		return "", fmt.Errorf("failed to marshal request: %w", err)
	}

	httpReq, err := http.NewRequestWithContext(ctx, "POST", c.baseURL+"/chat/completions", bytes.NewBuffer(jsonData))
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}

	httpReq.Header.Set("Authorization", "Bearer "+c.apiKey)
	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("HTTP-Referer", "https://solace.app") // Required by OpenRouter
	httpReq.Header.Set("X-Title", "Solace")                  // Required by OpenRouter

	resp, err := c.httpClient.Do(httpReq)
	if err != nil {
		return "", fmt.Errorf("failed to make request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return "", fmt.Errorf("API request failed with status %d: %s", resp.StatusCode, string(body))
	}

	var chatResp ChatResponse
	if err := json.NewDecoder(resp.Body).Decode(&chatResp); err != nil {
		return "", fmt.Errorf("failed to decode response: %w", err)
	}

	if len(chatResp.Choices) == 0 {
		return "", fmt.Errorf("no response choices returned")
	}

	return chatResp.Choices[0].Message.Content, nil
}

// buildAdvicePrompt constructs the prompt for advice generation
func (c *Client) buildAdvicePrompt(problemDescription string, verses []string) string {
	versesText := ""
	for i, verse := range verses {
		versesText += fmt.Sprintf("%d. %s\n", i+1, verse)
	}

	return fmt.Sprintf(`You are a compassionate Christian counselor providing Biblical guidance.

Problem: %s

Relevant Bible verses:
%s

Please provide concise, Biblical advice (under 200 words) that:
1. Shows empathy for the person's situation
2. Applies the provided Bible verses directly to their problem
3. Offers practical, Christ-centered guidance
4. Encourages spiritual growth and hope

Focus on hope, love, and God's promises rather than condemnation.`, problemDescription, versesText)
}
