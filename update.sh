#!/bin/bash

set -e

ORIGINAL_DIR=$(pwd)

echo "Creating temporary directory in which the update work will be performed"
mkdir -p /tmp/go-workos
cd /tmp/go-workos
rm -rf ./* ./.git*
echo "Cloning the our go-workos repo into the temp directory"
git clone git@github.com:cirruscomms/go-workos.git . > /dev/null 2>&1
echo "Adding the latest upstream changes and resetting our local copy to match"
git remote add upstream git@github.com:workos/workos-go.git > /dev/null 2>&1
git fetch upstream main > /dev/null 2>&1
git switch main > /dev/null 2>&1
git reset --hard upstream/main > /dev/null 2>&1
echo "Applying out changes over the top of the new upstream version"

cp $ORIGINAL_DIR/update.sh $ORIGINAL_DIR/swoop.tmpl .
rm -rf .github devbox.json devbox.lock makefile
echo -E "test:" > Makefile && echo "	go vet ./..." >> Makefile && echo "	go test ./..." >> Makefile
mv internal/workos/workos.go ./workos.go
rm -rf internal
mv pkg/{mfa,usermanagement,passwordless,common,retryablehttp,roles,webhooks,workos_errors} ./
mv README.md README_UPSTREAM.md
echo "# Swoop version of the WorkOS Go SDK\nTo update this to a newer upstream version, run the \`update.sh\` script\n\n$(cat README_UPSTREAM.md)" > README.md
rm -rf pkg README_UPSTREAM.md
sed -E -i '' 's|workos/workos-go/(v[0-9])|cirruscomms/go-workos/\1|g' ./go.mod
find . -type f -name '*.go'  -exec sed -E -i '' 's|workos/workos-go/(v[0-9])/internal/workos|cirruscomms/go-workos/\1|g;s|workos/workos-go/(v[0-9])/pkg/(.*)|cirruscomms/go-workos/\1/\2|g' {} \;
grep -R "type Client struct" * | sed -E 's|/[a-z]+\.go:.*||' | grep -v "webhooks" | xargs -I {} bash -c 'WORKOS_PACKAGE=$(echo {}); echo "package ${WORKOS_PACKAGE}$(cat swoop.tmpl)" > {}"/swoop.go";'
grep -R "type Client struct" * | sed -E 's|:.*||' | grep -v "webhooks" | xargs -I {} sed -i '' "s|type Client struct {
	TenantID string // the internal tenant id that tells the auth-service which API/client-creds to use when talking to WorkOS
	TenantID string // the internal tenant id that tells the auth-service which API/client-creds to use when talking to WorkOS|type Client struct {
	TenantID string // the internal tenant id that tells the auth-service which API/client-creds to use when talking to WorkOS
	TenantID string // the internal tenant id that tells the auth-service which API/client-creds to use when talking to WorkOS\n\tTenantID string // the internal tenant id that tells the auth-service which API/client-creds to use when talking to WorkOS|g; s|||; s|||; s|||; s|	APIKey string$|	APIKey string // Used as the auth-token when talking to auth-service|" {}
grep -R "req\.Header\.Set.*User-Agent" * | sed -E 's|:.*||' | grep -v "webhooks" | sort | uniq | xargs -I {} sed -i '' 's|req.Header.Set("User-Agent", "workos-go/"+workos.Version)
	req.Header.Set("X-Tenant-ID", c.TenantID)|req.Header.Set("User-Agent", "workos-go/"+workos.Version)
	req.Header.Set("X-Tenant-ID", c.TenantID)\n\treq.Header.Set("X-Tenant-ID", c.TenantID)|g' {}
go mod tidy > /dev/null 2>&1
echo "Finished updating the code base, now running tests"
make test || exit 1
git add . > /dev/null 2>&1
git commit -m "chore: update to latest upstream version" > /dev/null
git push origin main --force > /dev/null 2>&1
echo "Pushed the updated code to the repo"
cd $ORIGINAL_DIR
git fetch --all > /dev/null 2>&1
git switch main > /dev/null 2>&1
git reset --hard origin/main > /dev/null 2>&1
echo "Updated the local repo copy"
echo "You now need to tag the new version and push the tag to the origin remote"
