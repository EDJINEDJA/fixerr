import subprocess
from typing import Optional

def analyze_error(language: str, error: str, code: str, model: str = "phi") -> str:
    """
    Analyze code errors using local LLM
    
    Args:
        language: Programming language (python, js, etc.)
        error: Error message output
        code: Source code content
        model: Ollama model to use
    
    Returns:
        Formatted analysis with suggested fixes
    """
    prompt = f"""
    [TASK]
    Analyze this {language} code error and suggest fixes.

    [CODE]
    {code}

    [ERROR]
    {error}

    [INSTRUCTIONS]
    1. Explain root cause in simple terms
    2. Provide 1-3 solutions (mark best option)
    3. Show corrected code example
    4. List common pitfalls to avoid
    
    [RESPONSE FORMAT]
    ### Error Analysis
    {{analysis}}
    
    ### Recommended Solutions
    1. {{solution_1}} (⭐ Best)
    2. {{solution_2}}
    3. {{solution_3}}
    
    ### Corrected Code
    ```{language}
    {{fixed_code}}
    ```
    """
    
    try:
        result = subprocess.run(
            ["ollama", "run", model, prompt],
            check=True,
            capture_output=True,
            text=True,
            timeout=120  # 2 minute timeout
        )
        return result.stdout
    except subprocess.TimeoutExpired:
        return "⚠️ Analysis timed out. Try simplifying your code."
    except subprocess.CalledProcessError as e:
        return f"❌ LLM Error: {e.stderr}"
    except Exception as e:
        return f"⚠️ Unexpected error: {str(e)}"