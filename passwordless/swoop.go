package passwordless

import (
	"context"
	"encoding/json"
	"net/http"
	"time"

	"github.com/cirruscomms/go-common/pkg/auth"
)

// SwoopClient creates and returns a WorkOS Client with the provided tenant, authToken, and authServiceHost
// The authServiceHost should be the URL of the Swoop Auth Service
// Example: https://auth.swoop.com.au
func SwoopClient(ctx context.Context, tenant, authServiceHost, oAuthAddress, oAuthClientID, oAuthClientSecret string, oAuthScopes []string) (authServiceClient *Client) {
	httpClient := auth.NewClient(ctx, oAuthAddress, oAuthClientID, oAuthClientSecret, oAuthScopes, 10*time.Second)
	httpClient.Transport = http.DefaultTransport
	
	go11y.AddDBStoreRoundTripper(&httpClient)

	// Return workos-client with added fields and updated values
	return &Client{
		TenantID:   tenant,
		Endpoint:   authServiceHost,
		HTTPClient: &httpClient,
		JSONEncode: json.Marshal,
	}
}
