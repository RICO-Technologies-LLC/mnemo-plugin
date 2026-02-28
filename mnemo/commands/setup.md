Run the MMRY AI setup flow. This configures the plugin or reconfigures it for a new account.

Do NOT show the user bash commands or ask them to run anything in a terminal. You handle everything conversationally.

## Setup Flow

1. Ask the user: "Are you creating a new organization, or joining one that already exists?"

2. **If creating a new organization**, collect these fields one at a time in natural conversation:
   - Organization name (e.g., their company or team name)
   - First name
   - Last name
   - Email address
   - Password (tell them: must be 8+ characters with uppercase, lowercase, digit, and special character)

3. **If joining an existing organization**, collect:
   - Email address (the one their admin created for them)
   - Password

4. **Validate the password** before calling the API: 8-128 characters, must contain at least one uppercase letter, one lowercase letter, one digit, and one special character. If it fails, explain what is missing and ask them to choose a different one.

5. **Call the API directly** using the Bash tool with curl.

   For new organization (register):
   ```
   curl -s -w '\n%{http_code}' -X POST "https://mmryai.com/api/auth/register" -H "Content-Type: application/json" --data-raw '{"subscriberName":"ORG_NAME","firstName":"FIRST","lastName":"LAST","email":"EMAIL","password":"PASSWORD"}'
   ```

   For joining (login):
   ```
   curl -s -w '\n%{http_code}' -X POST "https://mmryai.com/api/auth/login" -H "Content-Type: application/json" --data-raw '{"email":"EMAIL","password":"PASSWORD"}'
   ```

   The last line of output is the HTTP status code. Everything before it is the JSON response body. Properly JSON-escape any special characters in user input (quotes, backslashes).

6. **Handle errors** based on HTTP status code:
   - 409 on register: "That email is already registered." Ask if they meant to join instead, or want to use a different email.
   - 401 on login: "Invalid email or password." Ask them to double-check their credentials.
   - 400: Validation error. Show the error details from the response and help them fix it.
   - 000 or connection error: "The API is temporarily unavailable. Try again in a moment."

7. **On success** (201 for register, 200 for login), extract the `token` field from the JSON response. Then generate an API key:
   ```
   curl -s -w '\n%{http_code}' -X POST "https://mmryai.com/api/auth/apikey" -H "Authorization: Bearer TOKEN" -H "Content-Type: application/json" --data-raw '{"label":"MACHINE_HOSTNAME"}'
   ```
   Get the machine hostname by running `hostname`. Extract the `apiKey` field from the response (HTTP 201).

8. **Write the config file.** Use the Write tool to create `~/.claude/mnemo-config.json`:
   ```json
   {
     "apiUrl": "https://mmryai.com",
     "authMethod": "apikey",
     "apiKey": "THE_API_KEY"
   }
   ```

9. **Auto-approve permissions.** Read `~/.claude/settings.json`. Add these entries to the `permissions.allow` array if not already present:
   - `Bash(*save-memory.sh*)`
   - `Bash(*reinforce-memory.sh*)`
   - `Bash(*deactivate-memory.sh*)`
   - `Bash(*link-memories.sh*)`
   - `Bash(*search-memories.sh*)`
   - `Bash(*mnemo-client.sh*)`
   Write the updated file back with the Edit or Write tool. Preserve all existing settings.

10. **Tell the user:** "You're all set. Restart Claude Code and your memories will start loading automatically. Type /mnemo:help anytime for a quick reference."
