#!/bin/bash

set -e

ORIGINAL_DIR=$(pwd)

echo "1a. Creating temporary directory in which the update work will be performed"
mkdir -p /tmp/go-workos
cd /tmp/go-workos
rm -rf ./* ./.git*
echo "1b. Created and switched to temp directory: /tmp/go-workos"

echo "2a. Cloning the our go-workos repo into the temp directory"
git clone git@github.com:cirruscomms/go-workos.git . > /dev/null 2>&1
echo "2b. Cloned the repo"

echo "3a. Adding the latest upstream changes and resetting our temp copy to match"
git remote add upstream git@github.com:workos/workos-go.git > /dev/null 2>&1
git fetch upstream main > /dev/null 2>&1
git switch main > /dev/null 2>&1
git reset --hard upstream/main > /dev/null 2>&1
echo "3b. Updated temp copy to match latest upstream version"

echo "4a. Applying our changes over the top of the new upstream version"
cp -rf $ORIGINAL_DIR/update.sh $ORIGINAL_DIR/swoop.tmpl $ORIGINAL_DIR/go.mod $ORIGINAL_DIR/tenants .
rm -rf .github devbox.json devbox.lock makefile
echo -E "test:" > Makefile && echo "	go vet ./..." >> Makefile && echo "	go test ./..." >> Makefile
mv internal/workos/workos.go ./workos.go
rm -rf internal
mv pkg/{mfa,usermanagement,passwordless,common,retryablehttp,roles,webhooks,workos_errors} ./
mv README.md README_UPSTREAM.md
echo "# Swoop version of the WorkOS Go SDK\nTo update this to a newer upstream version, run the \`update.sh\` script\n\n$(cat README_UPSTREAM.md)" > README.md
rm -rf pkg README_UPSTREAM.md
sed -E -i '' 's|workos/workos-go/(v[0-9])|cirruscomms/go-workos/\1|g' ./go.mod
echo "4b. Updated the basic code base structure"
echo "4c. Now applying the Swoop specific changes"
#
# This is where the bulk of the changes will need to be made as we expand coverage of the WorkOS API
#

# Update all the import paths to point to our repo
find . -type f -name '*.go'  -exec sed -E -i '' 's|workos/workos-go/(v[0-9])/internal/workos|cirruscomms/go-workos/\1|g; s|workos/workos-go/(v[0-9])/pkg/(.*)|cirruscomms/go-workos/\1/\2|g' {} \;
# Add swoop.go file to each package that has a Client struct, except webhooks
grep -R -l "type Client struct" * | grep ".go" | sed -E 's|/[a-z]+\.go||' | grep -v "webhooks" | xargs -I {} bash -c 'WORKOS_PACKAGE=$(echo {}); echo "package ${WORKOS_PACKAGE}$(cat swoop.tmpl)" > {}"/swoop.go";'
# Add TenantID field to each Client struct, except webhooks
grep -R -l "type Client struct" *  | grep ".go" | grep -v "webhooks" | xargs -I {} sed -i '' "s|type Client struct {|type Client struct {\n\tTenantID string // the internal tenant id that tells the auth-service which API/client-creds to use when talking to WorkOS|g;" {}
# Add a comment to the APIKey field in each Client struct, except webhooks
grep -R -l "type Client struct" * | grep ".go" | grep ".go" | grep -v "webhooks" | xargs -I {} sed -i '' "s|	APIKey string$|	APIKey string // Used as the auth-token when talking to auth-service|" {}
# Add the x-tenant-id header to every request (webhooks doesn't make requests so is excluded)
grep -R -l "req\.Header\.Set.*User-Agent" *  | grep ".go" | grep -v "webhooks" | sort | uniq | xargs -I {} sed -i '' 's|req.Header.Set("User-Agent", "workos-go/"+workos.Version)|req.Header.Set("User-Agent", "workos-go/"+workos.Version)\n\treq.Header.Set("X-Tenant-ID", c.TenantID)|g' {}

#
# Back to the boring stuff
#
echo "4d. Updated with the Swoop specific changes"

echo "5a. Clean up and run tests"
go mod tidy || exit 1
make test || exit 1
echo "5b. Cleaned up and tests passed"

echo "6a. Committing and pushing the updated code to our remote repo"
git add . > /dev/null 2>&1
git commit -m "chore: update to latest upstream version" > /dev/null
git push origin main --force > /dev/null 2>&1
echo "6b. Pushed the updated code to the repo"

echo "7a. Cleaning up and resetting local repo copy"
cd $ORIGINAL_DIR
git fetch --all > /dev/null 2>&1
git switch main > /dev/null 2>&1
git reset --hard origin/main > /dev/null 2>&1
echo "7b. Updated the local repo copy"

echo "You now need to tag the new version and push the tag to the origin remote"
