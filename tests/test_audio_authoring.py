import copy
import io
import json
import math
import struct
import tempfile
import unittest
import wave
from contextlib import redirect_stdout, redirect_stderr
from pathlib import Path
from unittest.mock import patch

from tools.audio_authoring import core
from tools.audio_authoring.__main__ import main
from tools.audio_authoring.sample_renderer import validate_score, events_for_track, verify_sources

ROOT = Path(__file__).resolve().parents[1]
EXAMPLES = ROOT / "tools/audio_authoring/examples"


class SampleScoreTests(unittest.TestCase):
    def score(self):
        return {'schema_version':1,'id':'test-score','style':'indie','sample_rate':48000,
                'duration_seconds':12,'tail_seconds':2.4,'rights_receipt':'reviewed.json',
                'authoring_authority':'Explicit local study',
                'tracks':[{'id':'guitar','instrument':'electric_guitar','role':'rhythm',
                           'sfz':'subset.sfz','sfz_sha256':'a'*64,
                           'source_manifest':'sources.json','source_manifest_sha256':'b'*64,
                           'voices':2,'gain':.1,'notes':[
                               {'at':0,'off':.5,'pitch':50,'velocity':70,'voice':0},
                               {'at':.5,'off':1,'pitch':57,'velocity':60,'voice':0},
                               {'at':0,'off':1,'pitch':62,'velocity':80,'voice':1}]}]}

    def test_same_string_overlap_refused_but_independent_strings_can_ring(self):
        score=self.score(); validate_score(score)
        score['tracks'][0]['notes'][1]['at']=.4
        with self.assertRaisesRegex(core.AuthoringError,'Overlapping'): validate_score(score)

    def test_off_precedes_retrigger_at_exact_sample_and_keeps_stroke_offsets(self):
        events=events_for_track(validate_score(self.score())['tracks'][0],48000)
        same=[e for e in events if e[0]==24000]
        self.assertEqual([e[1] for e in same],[0,1])
        self.assertEqual([e[3] for e in same],[50,57])

    def test_tail_and_invalid_midi_or_nonfinite_score_are_rejected(self):
        mutations=[('off',11),('at',float('nan')),('pitch',128),('voice',2),('velocity',True)]
        for key,value in mutations:
            score=self.score();score['tracks'][0]['notes'][0][key]=value
            with self.subTest(key=key),self.assertRaises(core.AuthoringError):validate_score(score)
        score=self.score();score['tracks'][0]['gain']=float('inf')
        with self.assertRaises(core.AuthoringError):validate_score(score)

    def test_instrument_and_style_interface_is_data_not_guitar_hardcoding(self):
        score=self.score();score['style']='future_jazz';score['tracks'][0]['instrument']='bass'
        score['tracks'][0]['role']='bassline';self.assertEqual(validate_score(score)['style'],'future_jazz')
        # Representable is not evidence that this instrument or style has been heard.

    def test_source_hash_and_undeclared_sfz_sample_are_refused(self):
        import hashlib
        with tempfile.TemporaryDirectory() as td:
            root=Path(td);(root/'instrument').mkdir();sample=root/'instrument/note.wav';sample.write_bytes(pcm())
            sfz=root/'instrument/subset.sfz';sfz.write_text('<region>\nsample=note.wav\nkey=60\n')
            manifest=root/'sources.json';manifest.write_text(json.dumps({'complete':True,'license':'CC0-1.0','rows':[
                {'path':'note.wav','bytes':sample.stat().st_size,'sha256':hashlib.sha256(sample.read_bytes()).hexdigest()}]}))
            track=self.score()['tracks'][0]
            track.update(sfz=str(sfz),source_manifest=str(manifest),
                         sfz_sha256=hashlib.sha256(sfz.read_bytes()).hexdigest(),
                         source_manifest_sha256=hashlib.sha256(manifest.read_bytes()).hexdigest())
            self.assertEqual(verify_sources(track)['files'],1)
            sample.write_bytes(pcm((0,1,2)))
            with self.assertRaisesRegex(core.AuthoringError,'sample changed'):verify_sources(track)
            sample.write_bytes(pcm());sfz.write_text('<region>\nsample=missing.wav\n')
            track['sfz_sha256']=hashlib.sha256(sfz.read_bytes()).hexdigest()
            with self.assertRaises((core.AuthoringError,FileNotFoundError)):verify_sources(track)


def pcm(samples=(0, -32768, 16384), *, width=2, rate=8000):
    stream = io.BytesIO()
    with wave.open(stream, "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(width)
        wav.setframerate(rate)
        wav.writeframes(b"".join(bytes([x + 128]) if width == 1 else x.to_bytes(width, "little", signed=True) for x in samples))
    return stream.getvalue()


class AudioAuthoringTests(unittest.TestCase):
    def setUp(self):
        self.catalog = core.load_catalog()
        self.request = core.load_json(EXAMPLES / "indie_audition.json")

    def test_raw_and_derived_are_charged_even_when_backend_is_blocked(self):
        plan = core.plan_request(self.request, self.catalog)
        self.assertFalse(plan["generation_allowed"])
        self.assertIn("study_budget_exceeded", plan["holds"])
        self.assertIn("isolated_instrument_capability_unverified", plan["holds"])
        self.assertEqual(plan["budget"]["files"], 6)
        self.assertAlmostEqual(plan["budget"]["seconds"], 46.097392)
        self.assertIn("files", plan["budget"]["exceeded"])
        self.assertIn("seconds", plan["budget"]["exceeded"])

    def test_backend_clearance_flags_never_enable_an_executable_renderer(self):
        backend = self.catalog["backends"][self.request["backend"]]
        backend.update(runtime_available=True, capability_clearance="cleared", rights_clearance="cleared", cost_clearance="cleared", isolation="verified")
        plan = core.plan_request(self.request, self.catalog)
        self.assertFalse(plan["generation_allowed"])
        self.assertIn("no_executable_renderer_configured", plan["holds"])

    def test_tails_are_inside_complete_duration_and_not_added_twice(self):
        self.request["tail_seconds"] = 5
        with self.assertRaises(core.AuthoringError): core.validate_request(self.request, self.catalog)
        self.request["tail_seconds"] = 0.6
        plan = core.plan_request(self.request, self.catalog)
        self.assertAlmostEqual(plan["musical_seconds_before_tail"], 3.4)
        self.assertEqual(plan["planned_assets"][1]["frames"], 176400)

    def test_full_ensemble_future_study_is_representable_but_not_authorised(self):
        request = core.load_json(EXAMPLES / "indie_song_snippet.json")
        plan = core.plan_request(request, self.catalog)
        self.assertEqual(len(plan["request"]["instruments"]), 4)
        self.assertEqual(len(plan["planned_assets"]), 1)  # same physical source/review asset
        self.assertEqual(plan["planned_assets"][0]["duration_seconds"], 30)
        self.assertIn("study_contract_not_adopted", plan["holds"])
        self.assertIsNone(plan["budget"])

    def test_new_style_is_data_not_a_code_change(self):
        self.request["style"] = "future_jazz"
        with self.assertRaises(core.AuthoringError): core.validate_request(self.request, self.catalog)
        self.catalog["styles"]["future_jazz"] = {"label": "Future style proposal", "guidance": ["An authored future style profile; not yet a listening proof"]}
        self.assertEqual(core.validate_request(self.request, self.catalog)["style"], "future_jazz")

    def test_unknown_versions_typos_numbers_and_non_musical_grades_refused(self):
        mutations = [("schema_version", 2), ("duration_seconds", True), ("duration_seconds", float("nan")), ("duration_seconds", -1), ("instruments", []), ("tail_seconds", -0.1), ("review_mode", "erase_raw")]
        for key, value in mutations:
            request = copy.deepcopy(self.request); request[key] = value
            with self.subTest(key=key, value=value), self.assertRaises(core.AuthoringError): core.validate_request(request, self.catalog)
        for skills in ({"reliability": "high"}, {"collaboration": "high"}, {"technique": 80}):
            request = copy.deepcopy(self.request); request["musicianship"] = skills
            with self.assertRaises(core.AuthoringError): core.validate_request(request, self.catalog)
        request = copy.deepcopy(self.request); request["duraton_seconds"] = 4
        with self.assertRaises(core.AuthoringError): core.validate_request(request, self.catalog)

    def test_same_asset_cannot_hide_a_longer_raw_file(self):
        self.request["review_mode"] = "same_asset"
        plan = core.plan_request(self.request, self.catalog)
        self.assertIn("same_asset_requires_identical_complete_duration_and_format", plan["holds"])
        self.assertEqual(plan["planned_assets"][0]["duration_seconds"], 10)
        self.assertEqual(len(plan["planned_assets"]), 2)
        self.assertEqual(plan["budget"]["files"], 6)

    def test_malformed_catalog_is_a_controlled_error(self):
        for catalog in ({}, {**self.catalog, "styles": []},
                        {**self.catalog, "backends": {"bad": "not an object"}},
                        {**self.catalog, "studies": {"bad": {"max_files": 1}}}):
            with self.subTest(catalog=catalog), self.assertRaises(core.AuthoringError):
                core.plan_request(self.request, catalog)

    def test_voice_scope_is_separate_from_generic_instrument_support(self):
        self.request["contains_voice"] = True
        self.assertIn("voices_outside_study_scope", core.plan_request(self.request, self.catalog)["holds"])
        self.request["contains_voice"] = "yes"
        with self.assertRaises(core.AuthoringError): core.validate_request(self.request, self.catalog)

    def test_duration_overflow_and_invalid_frame_rate_are_controlled(self):
        for value in ("1e10000", "inf", "nan"):
            with self.subTest(value=value), self.assertRaises(core.AuthoringError): core.seconds(value)
        with self.assertRaises(core.AuthoringError):
            core.budget_totals([{"frames": 1, "sample_rate": 0, "bytes": 46}],
                              {"max_files": 1, "max_seconds": 1, "max_bytes": 100})

    def test_exact_frame_budget_boundary_and_container_bytes(self):
        policy = {"max_files": 1, "max_seconds": 1, "max_bytes": 16044, "charged": {}}
        one = {"frames": 8000, "sample_rate": 8000, "bytes": 16044}
        self.assertTrue(core.budget_totals([one], policy)["within_budget"])
        one["frames"] += 1
        self.assertIn("seconds", core.budget_totals([one], policy)["exceeded"])
        one["frames"] = 8000; one["bytes"] += 1
        self.assertIn("bytes", core.budget_totals([one], policy)["exceeded"])

    def test_integer_pcm_widths_and_measurement_limits(self):
        for width in (1, 2, 3, 4):
            peak = 1 << (8 * width - 1)
            data = pcm((0, -peak, peak // 2), width=width)
            info = core.inspect_wav_stream(io.BytesIO(data))
            self.assertEqual(info["container_bytes"], len(data))
            self.assertEqual(info["frames"], 3)
            self.assertEqual(info["sample_peak_dbfs"], 0)
            self.assertFalse(info["true_peak_measured"])
            self.assertFalse(info["LUFS_measured"])
            self.assertFalse(info["listening_acceptance"])

    def test_silence_and_truncated_wav_do_not_produce_false_measurements(self):
        info = core.inspect_wav_stream(io.BytesIO(pcm((0, 0))))
        self.assertTrue(info["silent"])
        self.assertIsNone(info["rms_dbfs"])
        data = pcm()
        with self.assertRaises(core.AuthoringError): core.inspect_wav_stream(io.BytesIO(data[:-2]))
        with self.assertRaises(core.AuthoringError): core.inspect_wav_stream(io.BytesIO(b"not a wave"))
        with self.assertRaises(core.AuthoringError): core.inspect_wav_stream(io.BytesIO(pcm(())))

    def test_actual_container_metadata_counts_and_stream_is_unchanged(self):
        data = bytearray(pcm() + b"JUNK" + struct.pack("<I", 6) + b"extra!")
        struct.pack_into("<I", data, 4, len(data) - 8)  # metadata is inside the RIFF container
        stream = io.BytesIO(data)
        info = core.inspect_wav_stream(stream)
        self.assertEqual(info["container_bytes"], len(data))
        self.assertEqual(stream.getvalue(), data)

    def test_corrupt_riff_byte_rate_and_block_alignment_are_rejected(self):
        for offset, fmt, value in ((4, "<I", 1), (28, "<I", 123), (32, "<H", 7)):
            data = bytearray(pcm())
            struct.pack_into(fmt, data, offset, value)
            with self.subTest(offset=offset), self.assertRaises(core.AuthoringError):
                core.inspect_wav_stream(io.BytesIO(data))
        with self.assertRaises(core.AuthoringError):
            core.inspect_wav_stream(io.BytesIO(pcm() + b"undeclared trailing data"))

    def test_changing_input_cannot_bind_old_hash_to_new_pcm(self):
        class Changing(io.BytesIO):
            armed = False
            changed = False
            def read(self, size=-1):
                if self.armed and not self.changed and size == 12:
                    view = self.getbuffer(); view[44] ^= 1; view.release()
                    self.changed = True
                result = super().read(size)
                if not result: self.armed = True
                return result
        with self.assertRaisesRegex(core.AuthoringError, "changed"):
            core.inspect_wav_stream(Changing(pcm()))

    def test_growing_input_has_a_bounded_read(self):
        class Growing(io.BytesIO):
            def read(self, size=-1):
                position = self.tell()
                if position == len(self.getvalue()):
                    self.write(b"extra"); self.seek(position)
                return super().read(size)
        with self.assertRaisesRegex(core.AuthoringError, "changed"):
            core.inspect_wav_stream(Growing(pcm()))

    def test_review_cannot_outlast_raw_and_fraction_default_is_not_rounded(self):
        self.request["duration_seconds"] = 30
        self.assertIn("source_shorter_than_review_requires_separate_transformation_contract",
                      core.plan_request(self.request, self.catalog)["holds"])
        self.request.pop("source_duration_seconds")
        self.request.pop("source_format")
        self.request.update(duration_seconds="1/3", tail_seconds=0, output_format={"sample_rate": 3, "channels": 1, "sample_width_bytes": 2})
        self.catalog["backends"][self.request["backend"]]["min_seconds"] = 0
        plan = core.plan_request(self.request, self.catalog)
        self.assertNotIn("source_shorter_than_review_requires_separate_transformation_contract", plan["holds"])
        self.assertEqual(plan["planned_assets"][0]["frames"], 1)

    def test_duplicate_json_keys_and_oversized_json_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "request.json"
            path.write_text('{"schema_version":1,"schema_version":2}')
            with self.assertRaisesRegex(core.AuthoringError, "Duplicate JSON"):
                core.load_json(path)
            path.write_text(" " * (1024 * 1024 + 1))
            with self.assertRaisesRegex(core.AuthoringError, "input limit"):
                core.load_json(path)

    def test_provenance_missing_parent_cycle_and_duplicate_path_refused(self):
        source = {"id": "raw", "path": "/not-read-source.wav", "role": "source", "parents": []}
        review = {"id": "review", "path": "/not-read-review.wav", "role": "review", "parents": ["raw"]}
        manifest = {"schema_version": 1, "study": "AU01", "assets": [review]}
        with self.assertRaises(core.AuthoringError): core.audit_bundle(manifest, self.catalog)
        source["parents"] = ["review"]; manifest["assets"] = [source, review]
        with self.assertRaises(core.AuthoringError): core.audit_bundle(manifest, self.catalog)
        source["parents"] = []; review["path"] = source["path"]
        with self.assertRaises(core.AuthoringError): core.audit_bundle(manifest, self.catalog)

    def test_actual_bundle_charges_source_and_review_and_requires_rights(self):
        # Actual WAV parsing occurs in memory; no musical/source WAV files are created.
        manifest = {"schema_version": 1, "study": "AU01", "assets": [
            {"id": "raw", "path": "/memory/raw.wav", "role": "source", "parents": []},
            {"id": "review", "path": "/memory/review.wav", "role": "review", "parents": ["raw"]}]}
        with patch.object(core, "inspect_wav", side_effect=lambda path: core.inspect_wav_stream(io.BytesIO(pcm()))):
            report = core.audit_bundle(manifest, self.catalog)
        self.assertEqual(report["budget"]["files"], 6)
        self.assertFalse(report["technical_audit_pass"])
        self.assertFalse(report["integration_allowed"])
        self.assertIn("output_rights_evidence_required:raw", report["holds"])

    def test_cli_plan_is_offline_report_and_unknown_render_is_not_a_command(self):
        output = io.StringIO()
        with redirect_stdout(output):
            self.assertEqual(main(["plan", str(EXAMPLES / "indie_audition.json")]), 0)
        self.assertFalse(json.loads(output.getvalue())["generation_allowed"])
        with redirect_stderr(io.StringIO()), self.assertRaises(SystemExit) as exc:
            main(["render", str(EXAMPLES / "indie_audition.json")])
        self.assertEqual(exc.exception.code, 2)


if __name__ == "__main__":
    unittest.main()
