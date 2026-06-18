// Smoke test: load a canonical JSON Resume document through the
// neat-cv adapter and verify it compiles end-to-end. Run with:
//
//   typst compile tests/json_resume.typ /tmp/neat-cv-json-resume.pdf --root .

#import "../lib.typ": neat-cv-from-json

#set text(lang: "en")

#neat-cv-from-json(json("fixtures/canonical_resume.json"))
