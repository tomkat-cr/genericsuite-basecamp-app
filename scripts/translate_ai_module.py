"""
AI Translation module using OpenAI
"""
import os
from openai import OpenAI

from utilities import log_debug, get_default_resultset

DEBUG = os.environ.get("AI_TRANSLATOR_DEBUG", "0") == "1"


def translate(
    text: str,
    dest: str = "es",
    src: str = "en",
    model: str = "gpt-4o-mini",
    temperature: str = "0.3"
) -> dict:
    """
    Translates texts using the OpenAI API, specifically optimized for Markdown.

    Args:
        text (str): The text to translate.
        dest (str, optional): The language to translate the text to.
          Defaults to "es" (Spanish).
        src (str, optional): The language of the text to translate.
          Defaults to "en" (English).
        model (str, optional): The OpenAI model to use.
          Defaults to "gpt-4o-mini".

    Returns:
        dict: a resultset with an "text" attribute containing
        the translated input text, or "error" and "error_message"
        attributes if there's something wrong.
    """
    response = get_default_resultset()

    api_key = os.environ.get("OPENAI_API_KEY")
    model = os.environ.get("OPENAI_MODEL", model)
    temperature = float(os.environ.get("OPENAI_TEMPERATURE", temperature))

    if not api_key:
        response["error"] = True
        response["error_message"] = "OPENAI_API_KEY env variable not set."
        return response

    try:
        client = OpenAI(api_key=api_key)

        system_prompt = (
            f"You are a professional translator specializing in Markdown "
            f"documentation. Translate the content from {src} to {dest}.\n\n"
            "CRITICAL RULES:\n"
            "1. PRESERVE MARKDOWN STRUCTURE: Do not change headers (#), "
            "lists (-/1.), bold (**), italics (*), etc.\n"
            "2. CODE BLOCKS: Do not translate content inside triple backtick "
            "code blocks (```lang ... ```). Preserve the language "
            "identifier.\n"
            "3. LINKS: In [text](url), only translate the 'text' part. "
            "DO NOT change the 'url'.\n"
            "4. IMAGES: Keep ![alt text](image_url) intact, only translate "
            "'alt text' if necessary, but keep image_url exactly as is.\n"
            "5. FRONTMATTER: If there is YAML frontmatter (between ---), "
            "preserve the keys and translate only the values.\n"
            "6. CONSISTENCY: Maintain technical terms if commonly used in the "
            "target language (e.g., 'API', 'Backend', 'Endpoint').\n"
            "7. NO EXPLANATIONS: Return ONLY the translated content."
        )

        log_debug(f"Translating {len(text)} chars to {dest} using {model}...")

        completion = client.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": text}
            ],
            temperature=temperature,
        )

        translated_text = completion.choices[0].message.content
        response["text"] = translated_text

    except Exception as err:
        response['error'] = True
        response['error_message'] = f"ERROR [OAI-010]: {str(err)}"
        log_debug(f"Translation Error: {str(err)}")

    if DEBUG:
        log_debug(">> OPENAI TRANSLATE()" +
                  f"\n | text snippet: {text[:50]}..."
                  f"\n | dest: {dest}"
                  f"\n | model: {model}"
                  f"\n | response_error: {response['error']}")

    return response


def lang_translate(
    input_text: str,
    target_lang: str = 'es',
    source_lang: str = 'en',
) -> dict:
    """
    Middleware function for translation.
    """
    return translate(text=input_text, dest=target_lang, src=source_lang)


if __name__ == "__main__":
    # Test script
    import sys
    test_md = """
# Welcome to the AI Translator
This is a **test** of the [Markdown](https://example.com) translation.

```python
def hello():
    print("Hello World")
```

![Sample Image](images/sample.png)
"""
    if len(sys.argv) > 1:
        test_md = sys.argv[1]

    result = translate(test_md)
    if result["error"]:
        print(f"Error: {result['error_message']}")
    else:
        print("--- Original ---")
        print(test_md)
        print("--- Translated ---")
        print(result["text"])
