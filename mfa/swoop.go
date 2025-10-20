package mfa

import (
	"context"
	"encoding/json"
	"net/http"
	"time"

	"github.com/cirruscomms/go-workos/v5"
	"github.com/cirruscomms/go11y"
)

// SwoopClient creates and returns a WorkOS Client with the provided tenant, authToken, and authServiceHost
// The authServiceHost should be the URL of the Swoop Auth Service
// Example: https://auth.swoop.com.au
func SwoopClient(ctx context.Context, tenant, authServiceHost, oAuthAddress, oAuthClientID, oAuthClientSecret string, oAuthScopes []string) (authServiceClient *Client) {
	httpClient := workos.NewClient(ctx, oAuthAddress, oAuthClientID, oAuthClientSecret, oAuthScopes, 10*time.Second)
	httpClient.Transport = http.DefaultTransport

	go11y.AddDBStoreToHTTPClient(httpClient)

	// Return workos-client with added fields and updated values
	return &Client{
		TenantID:   tenant,
		Endpoint:   authServiceHost,
		HTTPClient: httpClient,
		JSONEncode: json.Marshal,
	}
}
