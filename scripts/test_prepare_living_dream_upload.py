import tempfile
import unittest
from pathlib import Path
from PIL import Image
from prepare_living_dream_upload import convert


class PhotoUploadTest(unittest.TestCase):
    def test_avif_crops_and_audit(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            incoming = root / 'incoming' / 'showday'
            incoming.mkdir(parents=True)
            Image.new('RGB', (1800, 1200), (120, 85, 45)).save(incoming / 'load_van.avif')
            results = convert(root / 'incoming', root / 'approved')
            self.assertEqual(len(results), 1)
            self.assertEqual(len(results[0]['outputs']), 2)
            self.assertFalse(results[0]['human_visual_approval'])
            for kind, size in (('wide', (1600, 900)), ('portrait', (900, 1400))):
                with Image.open(root / 'approved' / f'load_van_{kind}.webp') as image:
                    self.assertEqual(image.size, size)
            self.assertTrue((root / 'approved' / 'owner_upload_audit.json').exists())

    def test_duplicate_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            incoming = root / 'incoming' / 'songwriting'
            incoming.mkdir(parents=True)
            Image.new('RGB', (900, 900)).save(incoming / 'spark.png')
            Image.new('RGB', (900, 900)).save(incoming / 'spark.webp')
            with self.assertRaisesRegex(ValueError, 'Duplicate'):
                convert(root / 'incoming', root / 'approved')

    def test_provenance_gate(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            incoming = root / 'incoming' / 'songwriting'
            incoming.mkdir(parents=True)
            Image.new('RGB', (1200, 1000)).save(incoming / 'spark.png')
            with self.assertRaisesRegex(ValueError, 'Missing original photo source'):
                convert(root / 'incoming', root / 'approved', strict_provenance=True)


if __name__ == '__main__':
    unittest.main()
