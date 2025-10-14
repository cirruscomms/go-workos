package mfa

import (
	"encoding/json"
	"net/http"
	"time"
)

// SwoopClient creates and returns a WorkOS Client with the provided tenant, authToken, and authServiceHost
// The authServiceHost should be the URL of the Swoop Auth Service
// Example: https://auth.swoop.com.au
func SwoopClient(tenant, authToken, authServiceHost string) (authServiceClient *Client) {
	// Create a new HTTP client with a timeout and default transport
	httpClient := http.Client{
		Timeout:   time.Second * 10,
		Transport: http.DefaultTransport,
	}

	// Return workos-client with added fields and updated values
	return &Client{
		TenantID:   tenant,
		APIKey:     authToken,
		Endpoint:   authServiceHost,
		HTTPClient: &httpClient,
		JSONEncode: json.Marshal,
	}
}
