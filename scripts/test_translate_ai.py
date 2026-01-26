import os
import unittest
from unittest.mock import MagicMock, patch

# Mock OpenAI before importing our module
mock_openai = MagicMock()
with patch.dict('sys.modules', {'openai': mock_openai}):
    from translate_ai_module import translate


class TestTranslateAI(unittest.TestCase):
    @patch.dict(os.environ, {"OPENAI_API_KEY": "fake-key"})
    def test_translate_success(self):
        # Setup mock client
        mock_client_instance = MagicMock()
        mock_openai.OpenAI.return_value = mock_client_instance

        # Setup mock response
        mock_completion = MagicMock()
        mock_completion.choices = [MagicMock()]
        mock_completion.choices[0].message.content = \
            "# Bienvenido\nEsto es una prueba."
        mock_client_instance.chat.completions.create.return_value = \
            mock_completion

        test_md = "# Welcome\nThis is a test."
        result = translate(test_md)

        self.assertFalse(result["error"])
        self.assertEqual(result["text"], "# Bienvenido\nEsto es una prueba.")

        # Verify prompt content (partial check)
        args, kwargs = mock_client_instance.chat.completions.create.call_args
        system_msg = kwargs['messages'][0]['content']
        self.assertIn("CRITICAL RULES", system_msg)
        self.assertIn("PRESERVE MARKDOWN STRUCTURE", system_msg)

    @patch.dict(os.environ, {}, clear=True)
    def test_missing_api_key(self):
        result = translate("test")
        self.assertTrue(result["error"])
        self.assertIn("OPENAI_API_KEY env variable not set",
                      result["error_message"])


if __name__ == "__main__":
    unittest.main()
