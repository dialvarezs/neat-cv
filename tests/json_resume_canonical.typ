// Backward-compat smoke test: a vanilla JSON Resume document (no
// neat-cv-specific extensions) must still render. Guards against the
// adapter accidentally requiring an extension field for its mainline
// rendering path.
//
//   typst compile tests/json_resume_canonical.typ /tmp/neat-cv-canonical.pdf --root .

#import "../lib.typ": neat-cv-from-json

#set text(lang: "en")

#neat-cv-from-json(json("fixtures/canonical_resume.json"))
