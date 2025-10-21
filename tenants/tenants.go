package tenants

import (
	"encoding/json"
	"fmt"
	"net/http"
)

const (
	TenantSwoop   = "swoop"
	TenantMoose   = "moose"
	TenantNodeOne = "nodeone"
)

func ValidTenants() []string {
	return []string{
		TenantSwoop,
		TenantMoose,
		TenantNodeOne,
	}
}

type Client struct {
	TenantID   string
	APIKey     string
	Endpoint   string
	HTTPClient *http.Client
}

type clientIDResponse struct {
	ClientID string `json:"client_id"`
}

func (c *Client) GetClientID() (clientID string, fault error) {
	req, err := http.NewRequest("GET", c.Endpoint, nil)
	if err != nil {
		return "", err
	}

	req.Header.Set("Authorization", "Bearer "+c.APIKey)
	req.Header.Set("X-Tenant-ID", c.TenantID)

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("failed to get client ID: status code %d", resp.StatusCode)
	}

	res := clientIDResponse{}

	err = json.NewDecoder(resp.Body).Decode(&res)
	if err != nil {
		return "", err
	}

	return res.ClientID, nil
}
