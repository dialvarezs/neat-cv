// Unit tests for the private helpers in `internal/json-resume.typ`.
// Compile this file to run the assertions:
//
//   typst compile tests/json_resume_helpers.typ /tmp/sink.pdf --root .

#import "../internal/json-resume-mapping.typ": _split-name, _classify-profiles


// ---- _split-name ----

#assert.eq(_split-name("Emmett Brown"), (firstname: "Emmett", lastname: "Brown"))
#assert.eq(
  _split-name("Emmett Lathrop Brown"),
  (firstname: "Emmett", lastname: "Lathrop Brown"),
)
#assert.eq(_split-name("Doc"), (firstname: "Doc", lastname: ""))
#assert.eq(_split-name(""), (firstname: "", lastname: ""))
#assert.eq(_split-name(none), (firstname: "", lastname: ""))


// ---- _classify-profiles ----

// Known networks are folded to lowercase and surface as usernames so
// neat-cv's social helpers can build canonical URLs themselves.
#assert.eq(
  _classify-profiles((
    (network: "GitHub",   username: "docbrown", url: "https://github.com/docbrown"),
    (network: "LinkedIn", username: "doc-brown", url: "https://linkedin.com/in/doc-brown"),
    (network: "X",        username: "docbrown1955", url: "https://x.com/docbrown1955"),
  )),
  (known: (github: "docbrown", linkedin: "doc-brown", twitter: "docbrown1955"), custom: ()),
)

// Unknown networks become `custom-links` with full URLs.
#assert.eq(
  _classify-profiles((
    (network: "DeLorean", username: "", url: "https://example.com/dl"),
  )),
  (known: (:), custom: ((label: "DeLorean", url: "https://example.com/dl"),)),
)

// Empty input is the identity.
#assert.eq(_classify-profiles(()), (known: (:), custom: ()))
#assert.eq(_classify-profiles(none), (known: (:), custom: ()))

// "Google Scholar" — multi-word known network folds to `scholar`.
#assert.eq(
  _classify-profiles(((network: "Google Scholar", username: "abc"),)),
  (known: (scholar: "abc"), custom: ()),
)

// Known network without a username falls through to custom (so its URL
// is still surfaced).
#assert.eq(
  _classify-profiles(((network: "GitHub", url: "https://github.com/x"),)),
  (known: (:), custom: ((label: "GitHub", url: "https://github.com/x"),)),
)

// A small empty page so typst-compile produces a valid artifact.
#set page(width: 5cm, height: 5cm)
helpers ok
