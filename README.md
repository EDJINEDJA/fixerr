<p align="center">
    <a href="https://github.com/EDJINEDJA//fixerr/blob/main/LICENSE" alt="Licence">
        <img src="https://img.shields.io/badge/license-MIT-yellow.svg" />
    </a>
    <a href="https://github.com/EDJINEDJA//fixerr/commits/main" alt="Commits">
        <img src="https://img.shields.io/github/last-commit/EDJINEDJA/fixerr/main" />
    </a>
    <a href="https://github.com/EDJINEDJA/fixerr" alt="Activity">
        <img src="https://img.shields.io/badge/contributions-welcome-orange.svg" />
    </a>
    <a href="http://matthaythornthwaite.pythonanywhere.com/" alt="Web Status">
        <img src="https://img.shields.io/website?down_color=red&down_message=down&up_color=success&up_message=up&url=http%3A%2F%2Fmatthaythornthwaite.pythonanywhere.com%2F" />
    </a>
</p>


## FixErr - AI-Powered Code Error Fixer

Automatically detect and fix errors in your code with a local AI model. Just run your script with fixerr, and get instant explanations and solutions when something breaks.

## Download & Install

#### macOS & Linux

```bash
$ curl -fsSL https://raw.githubusercontent.com/oblo/fixerr/main/install.sh | sh
```
#### Windows (WSL2 Recommended)

```bash
$ curl -fsSL https://raw.githubusercontent.com/oblo/fixerr/main/install.sh | sh
```

## How It Works

- Run your script with fixerr instead of the normal command:

```bash
$ fixerr my_script.py
```

- If an error occurs, FixErr analyzes it locally using an LLM (like Llama 3 or CodeLlama).

- Get clear explanations and fixes without sending your code to the cloud.

## Dependencies

- Ollama (installs automatically)

- Python (installs automatically if missing)

## Feedback & Contributions

Found a bug? Want a new feature? Open an issue or submit a PR!

🌟 Star the project on GitHub! → github.com/your-repo/fixerr

## Example

```bash
$ fixerr my_script.py
```
Output:

fixerr broken_script.py
❌ Error: IndexError: list index out of range  

💡 Fix:  
1. Check list length before access (⭐ Best)  
2. Use try-except block  
3. Initialize with default values  

🔧 Corrected Code:  
if len(my_list) > 0:
    print(my_list[0])