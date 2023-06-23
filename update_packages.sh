# GitHub API credentials and repository information
GITHUB_USERNAME="CodePrakhar"
GITHUB_TOKEN=$token
REPO_LINK="https://github.com/CodePrakhar/auto-dependency-update"

# Path to the text file
TEXT_FILE=updates.txt
PACKAGE_JSON_FILE=package.json

# Extract owner and repository name from the GitHub repository link
REPO_OWNER=$(echo "$REPO_LINK" | awk -F'/' '{print $(NF-1)}')
REPO_NAME=$(echo "$REPO_LINK" | awk -F'/' '{print $NF}' | sed 's/.git$//')
echo "$REPO_OWNER"
echo "$REPO_NAME"

# Initialize an empty JSON object to store all the changes
json_changes=$PACKAGE_JSON_FILE

# Loop through each line in the text file
while IFS= read -r line; do
  # Extract package name and latest version using string manipulation or other methods
  package_name=$(echo "$line" | awk -F '[... ]' '{print $4}')
  latest_version=$(echo "$line" | awk '{print $(NF-1)}')
  echo "$package_name"
  echo "$latest_version"

  # Update the JSON object with the package and version changes
  json_changes=$(jq --arg package "$package_name" --arg version "$latest_version" '.dependencies[$package] = $version' "$json_changes")

# Wait for a few seconds to avoid rate limiting (if necessary)
sleep 3
done < "$TEXT_FILE"

# Encode the JSON payload using base64
encoded_payload=$(echo "$json_changes" | base64 -w 0)

# Get the current SHA of the package.json file
current_sha=$(curl -s -u "$GITHUB_USERNAME:$GITHUB_TOKEN" "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/contents/$PACKAGE_JSON_FILE" | jq -r '.sha')

# Make a PUT request to the GitHub API to update the package.json file
curl -X PUT -u "$GITHUB_USERNAME:$GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -d '{
    "message": "Update package.json",
    "content": "'"$encoded_payload"'",
    "sha": "'"$current_sha"'"
  }' "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/contents/$PACKAGE_JSON_FILE"
