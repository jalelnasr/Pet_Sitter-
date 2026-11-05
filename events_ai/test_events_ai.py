import unittest
from main import SuggestRequest, fallback_response, clean_json_response

class TestEventsAi(unittest.TestCase):

    def test_clean_json_response(self):
        markdown_wrapped = '```json\n{"titles": ["Titre 1"]}\n```'
        self.assertEqual(clean_json_response(markdown_wrapped), '{"titles": ["Titre 1"]}')

    def test_fallback_response(self):
        req = SuggestRequest(
            title="Sortie Chiot au Parc",
            keywords=["chiot", "parc"],
            category="Éducation",
            location="Tunis"
        )
        res = fallback_response(req)
        self.assertEqual(res.source, "fallback")
        self.assertEqual(res.suggestedCategory, "Éducation")
        self.assertEqual(len(res.titles), 3)
        self.assertTrue(len(res.checklist) >= 4)
        self.assertTrue(len(res.tags) >= 3)
        self.assertTrue(len(res.summary) <= 120)
        self.assertTrue(len(res.description) > 20)

if __name__ == "__main__":
    unittest.main()
