{
  commit-smart = ''
    ---
    allowed-tools: Bash(git*), Bash(nix fmt), Read, Grep
    argument-hint: [--interactive][--scope=module|feature|fix][--dry-run]
    description: Enhanced atomic commits grouping and conventional messages
    ---

    You are an expert software developer with a deep understanding of version control best practices. Your task is to write a Git commit message for a given set of code changes. Your primary goal is to create a message that is clear, concise, and perfectly adheres to the specific commit message conventions of the project you are working in.

    1. CONVENTION RULES:
    JSON

    {
      "source": "",
      "convention": "",
      "rules": {
        "structure": "[e.g., '<type>(<scope>): <description>']",
        "types": ["[e.g., 'feat', 'fix', 'docs', 'style', 'refactor', 'test', 'chore']"],
        "scope": "[e.g., 'Optional, must be a noun describing a section of the codebase']",
        "subject": {
          "case": "[e.g., 'lowercase']",
          "punctuation": "[e.g., 'No trailing period']",
          "imperative": "[true/false]",
          "maxLength": "[e.g., 50 or 100]"
        },
        "body": {
          "required": "[true/false]",
          "wrapLength": "[e.g., 72]"
        },
        "breaking_changes": ""
      }
    }

    2. STAGED CODE CHANGES:
    Here are the staged code changes (git diff --staged) that need to be committed. Analyze this diff carefully to understand the purpose, scope, and impact of the changes.
    Diff

    [Insert full 'git diff --staged' output here]

    3. YOUR TASK:
    Based on the provided convention rules and the code diff, generate a complete and conforming commit message.

    First, determine the primary purpose of the change (e.g., is it a new feature, a bug fix, a documentation update, or a refactoring?). Then, draft a message that follows all structural, stylistic, and content rules defined in the JSON profile above. If the convention requires a type, select the most appropriate one. If it allows for a scope, identify the primary component or area of the codebase affected by the changes.

    Provide only the complete commit message as your response. Do not include any additional explanation, preamble, or markdown formatting.

    Example 1: Repository with Explicit "Conventional Commits" Guidelines

    This is the prompt you would generate if your script found and parsed a CONTRIBUTING.md file that specified the Conventional Commits standard.

    You are an expert software developer with a deep understanding of version control best practices. Your task is to write a Git commit message for a given set of code changes. Your primary goal is to create a message that is clear, concise, and perfectly adheres to the specific commit message conventions of the project you are working in.

    1. CONVENTION RULES:
    JSON

    {
      "source": "CONTRIBUTING.md",
      "convention": "Conventional Commits",
      "rules": {
        "structure": "<type>(<scope>): <description>",
        "types": ["feat", "fix", "build", "chore", "ci", "docs", "perf", "refactor", "revert", "style", "test"],
        "scope": "Optional, must be a noun describing a section of the codebase in parentheses.",
        "subject": {
          "case": "lowercase",
          "punctuation": "No trailing period.",
          "imperative": true,
          "maxLength": 100
        },
        "body": {
          "required": false,
          "wrapLength": 72
        },
        "breaking_changes": "Indicated by `!` after scope or a `BREAKING CHANGE:` footer."
      }
    }

    2. STAGED CODE CHANGES:
    Diff

    --- a/src/api/auth.js
    +++ b/src/api/auth.js
    @@ -10,7 +10,7 @@

     export const login = (credentials) => {
       // TODO: Add proper validation
    -  if (!credentials.email ||!credentials.password) {
    +  if (!credentials.email ||!credentials.password |

    | credentials.password.length < 8) {
         return Promise.reject('Invalid credentials');
       }
       return api.post('/login', credentials);

    3. YOUR TASK:
    Based on the provided convention rules and the code diff, generate a complete and conforming commit message.

    First, determine the primary purpose of the change (e.g., is it a new feature, a bug fix, a documentation update, or a refactoring?). Then, draft a message that follows all structural, stylistic, and content rules defined in the JSON profile above. If the convention requires a type, select the most appropriate one. If it allows for a scope, identify the primary component or area of the codebase affected by the changes.

    Provide only the complete commit message as your response. Do not include any additional explanation, preamble, or markdown formatting.

    Example 2: Repository with an Inferred "Tim Pope" Style

    This is the prompt you would generate if no contribution file was found, but analysis of the git log showed a strong adherence to classic, human-readable best practices.

    You are an expert software developer with a deep understanding of version control best practices. Your task is to write a Git commit message for a given set of code changes. Your primary goal is to create a message that is clear, concise, and perfectly adheres to the specific commit message conventions of the project you are working in.

    1. CONVENTION RULES:
    JSON

    {
      "source": "Inferred from git log",
      "convention": "Tim Pope Style",
      "rules": {
        "structure": "Subject and body separated by a blank line.",
        "types": null,
        "scope": null,
        "subject": {
          "case": "Capitalized",
          "punctuation": "No trailing period.",
          "imperative": true,
          "maxLength": 50
        },
        "body": {
          "required": false,
          "wrapLength": 72
        },
        "breaking_changes": "Explained in the body."
      }
    }

    2. STAGED CODE CHANGES:
    Diff

    --- a/docs/INSTALL.md
    +++ b/docs/INSTALL.md
    @@ -5,7 +5,7 @@

     ## Installation

    -Run `npm install my-app` to install the required dependencies.
    +Run `npm install` to install the required dependencies.

     Then, run `npm start` to launch the application.

    3. YOUR TASK:
    Based on the provided convention rules and the code diff, generate a complete and conforming commit message.

    First, determine the primary purpose of the change (e.g., is it a new feature, a bug fix, a documentation update, or a refactoring?). Then, draft a message that follows all structural, stylistic, and content rules defined in the JSON profile above. If the convention requires a type, select the most appropriate one. If it allows for a scope, identify the primary component or area of the codebase affected by the changes.

    Provide only the complete commit message as your response. Do not include any additional explanation, preamble, or markdown formatting.

    Example 3: No Convention Detected (Fallback to Best Practices)

    This is the prompt you would generate if no contribution file was found and the git log was inconsistent.

    You are an expert software developer with a deep understanding of version control best practices. Your task is to write a Git commit message for a given set of code changes. Your primary goal is to create a message that is clear, concise, and perfectly adheres to the specific commit message conventions of the project you are working in.

    1. CONVENTION RULES:
    JSON

    {
      "source": "Default Best Practices",
      "convention": "General Best Practices (Tim Pope Style)",
      "rules": {
        "structure": "Subject and body separated by a blank line.",
        "types": null,
        "scope": null,
        "subject": {
          "case": "Capitalized",
          "punctuation": "No trailing period.",
          "imperative": true,
          "maxLength": 50
        },
        "body": {
          "required": false,
          "wrapLength": 72
        },
        "breaking_changes": "Explained in the body."
      }
    }

    2. STAGED CODE CHANGES:
    Diff

    --- a/src/utils/calculator.js
    +++ b/src/utils/calculator.js
    @@ -1,3 +1,3 @@
     export function add(a, b) {
    -  return a - b; // Whoops!
    +  return a + b;
     }

    3. YOUR TASK:
    Based on the provided convention rules and the code diff, generate a complete and conforming commit message.

    First, determine the primary purpose of the change (e.g., is it a new feature, a bug fix, a documentation update, or a refactoring?). Then, draft a message that follows all structural, stylistic, and content rules defined in the JSON profile above. If the convention requires a type, select the most appropriate one. If it allows for a scope, identify the primary component or area of the codebase affected by the changes.

    Provide only the complete commit message as your response. Do not include any additional explanation, preamble, or markdown formatting.
  '';
}
