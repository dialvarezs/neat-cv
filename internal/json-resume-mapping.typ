// Pure data → data mapping from a JSON Resume document to the dict
// shape neat-cv's `cv()` expects. No Typst content emitted here — the
// rendering layer lives in `json-resume.typ`.

/// Split on first space — neat-cv renders firstname / lastname with
/// different weights so they can't be collapsed.
///
/// -> dictionary
#let _split-name(name) = {
  if name == none or name == "" {
    return (firstname: "", lastname: "")
  }
  let parts = name.split(" ")
  if parts.len() == 1 {
    return (firstname: parts.at(0), lastname: "")
  }
  (firstname: parts.at(0), lastname: parts.slice(1).join(" "))
}

/// Two-line collapse of the structured JSON Resume location into the
/// content shape neat-cv's `address` accepts.
///
/// -> content | none
#let _format-address(location) = {
  if location == none or type(location) != dictionary { return none }
  let line1-parts = (
    location.at("address", default: none),
    location.at("city", default: none),
    location.at("region", default: none),
  ).filter(p => p != none and p != "")
  let line2-parts = (
    location.at("postalCode", default: none),
    location.at("countryCode", default: none),
  ).filter(p => p != none and p != "")
  let line1 = line1-parts.join(", ")
  let line2 = line2-parts.join(" ")
  if line1 == "" and line2 == "" { return none }
  if line2 == "" { return [#line1] }
  if line1 == "" { return [#line2] }
  [#line1 \ #line2]
}

#let _known-networks = (
  twitter: "twitter",
  x: "twitter",
  mastodon: "mastodon",
  github: "github",
  gitlab: "gitlab",
  linkedin: "linkedin",
  researchgate: "researchgate",
  scholar: "scholar",
  "google scholar": "scholar",
  orcid: "orcid",
)

/// Bucket profiles into ones `cv()` knows (return usernames so its
/// social helpers can build canonical URLs) vs the rest (return full
/// URLs via `custom-links`). The `icon` extension on unknown-network
/// profiles flows through to the custom-link's `icon-name`.
///
/// -> dictionary
#let _classify-profiles(profiles) = {
  let known = (:)
  let custom = ()
  if profiles == none { return (known: known, custom: custom) }
  for p in profiles {
    let net = p.at("network", default: "")
    let username = p.at("username", default: "")
    let url = p.at("url", default: "")
    let key = _known-networks.at(lower(net), default: none)
    if key != none and username != "" {
      known.insert(key, username)
    } else {
      // Unknown network → custom-link; URL preferred, username as fallback.
      let label = if net != "" { net } else { username }
      let target = if url != "" { url } else { username }
      if target == "" { continue }
      let link = (label: label, url: target)
      let icon = p.at("icon", default: none)
      if icon != none { link.insert("icon-name", icon) }
      custom.push(link)
    }
  }
  (known: known, custom: custom)
}

/// Build the `author` kwarg for neat-cv's `cv()` from JSON Resume
/// `basics`. Absent fields are dropped (rather than emitted as empty)
/// so the renderer's `"key" in author` checks stay honest. The
/// `positions` extension overrides the canonical single-string `label`
/// when present.
///
/// -> dictionary
#let basics-to-author(basics) = {
  let parts = _split-name(basics.at("name", default: ""))
  let profile-info = _classify-profiles(basics.at("profiles", default: ()))

  let author = (firstname: parts.firstname, lastname: parts.lastname)
  let positions = basics.at("positions", default: none)
  if positions != none and positions.len() > 0 {
    author.insert("position", positions)
  } else {
    let label = basics.at("label", default: none)
    if label != none and label != "" { author.insert("position", label) }
  }
  let email = basics.at("email", default: none)
  if email != none { author.insert("email", email) }
  let phone = basics.at("phone", default: none)
  if phone != none { author.insert("phone", phone) }
  let website = basics.at("url", default: none)
  if website != none { author.insert("website", website) }
  let address = _format-address(basics.at("location", default: none))
  if address != none { author.insert("address", address) }
  for (k, v) in profile-info.known.pairs() { author.insert(k, v) }
  if profile-info.custom.len() > 0 {
    author.insert("custom-links", profile-info.custom)
  }
  author
}
