package workos

import (
	"context"
	"net/http"
	"time"

	"golang.org/x/oauth2"
	"golang.org/x/oauth2/clientcredentials"
)

func NewClient(ctx context.Context, host, clientId, clientSecret string, scopes []string, timeout time.Duration) *http.Client {
	cfg := &clientcredentials.Config{
		ClientID:     clientId,
		ClientSecret: clientSecret,
		Scopes:       scopes,
		AuthStyle:    oauth2.AuthStyleInParams,
		TokenURL:     host,
	}

	client := cfg.Client(ctx)
	client.Timeout = timeout
	return client
}
