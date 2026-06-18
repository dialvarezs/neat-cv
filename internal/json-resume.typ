// JSON Resume (https://jsonresume.org/schema) → neat-cv data-shape
// adapter. Validation runs through @preview/gairm-import (which aborts
// compile on schema errors); the remap fans the canonical document out
// across neat-cv's split `author` dict + per-section body.

#import "@preview/gairm-import:0.8.1": parse as _parse, resume-schema-strict


// ---- Helpers ----

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
  (
    firstname: parts.at(0),
    lastname: parts.slice(1).join(" "),
  )
}

/// Two-line collapse of the structured JSON Resume location into the
/// content shape neat-cv's `address` accepts.
///
/// -> content | none
#let _format-address(location) = {
  if location == none or type(location) != dictionary {
    return none
  }
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

  if line1 == "" and line2 == "" {
    return none
  }
  if line2 == "" {
    return [#line1]
  }
  if line1 == "" {
    return [#line2]
  }
  [#line1 \ #line2]
}

/// One-line collapse for `entry()`'s `location` slot.
///
/// -> string
#let _format-location-inline(loc) = {
  if loc == none { return "" }
  if type(loc) == str { return loc }
  if type(loc) == dictionary {
    return (
      loc.at("city", default: none),
      loc.at("region", default: none),
      loc.at("countryCode", default: none),
    ).filter(p => p != none and p != "").join(", ")
  }
  ""
}

/// Iso8601 → short human label. Malformed input has already been
/// rejected upstream by gairm-import's schema.
///
/// -> string
#let _months = (
  "Jan", "Feb", "Mar", "Apr", "May", "Jun",
  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
)

#let _format-date(d) = {
  if d == none or d == "" { return "" }
  let parts = d.split("-")
  if parts.len() == 1 { return parts.at(0) }
  if parts.len() >= 2 {
    let year = parts.at(0)
    let month = int(parts.at(1))
    if month >= 1 and month <= 12 {
      return _months.at(month - 1) + " " + year
    }
    return year
  }
  d
}

/// Open-ended entries (no `endDate`) render as "… – present", matching
/// the convention in `template/cv.typ`.
///
/// -> string
#let _format-date-range(start, end) = {
  let s = _format-date(start)
  let e = if end == none or end == "" {
    "present"
  } else {
    _format-date(end)
  }
  if s == "" and e == "present" { return "" }
  if s == "" { return e }
  s + " – " + e
}

/// Bucket profiles into ones `cv()` knows (return usernames so its
/// social helpers can build canonical URLs) vs the rest (return full
/// URLs via `custom-links`).
///
/// -> dictionary
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

#let _classify-profiles(profiles) = {
  let out = (:)
  let custom = ()
  if profiles == none { return (known: out, custom: custom) }
  for p in profiles {
    let net = p.at("network", default: "")
    let username = p.at("username", default: "")
    let url = p.at("url", default: "")
    let key = _known-networks.at(lower(net), default: none)
    if key != none and username != "" {
      out.insert(key, username)
    } else {
      // Unknown network → custom-link; URL preferred, username as fallback.
      let label = if net != "" { net } else { username }
      let target = if url != "" { url } else { username }
      if target != "" {
        custom.push((label: label, url: target))
      }
    }
  }
  (known: out, custom: custom)
}


// ---- Public API ----

/// Validate + reshape. Returns `(author, sections)` — `author` plugs
/// into `cv()`'s `author:` kwarg; `sections` is the parsed resume for
/// body rendering.
///
/// -> dictionary
#let from-json-resume(data) = {
  let resume = _parse(data, schema: resume-schema-strict)
  let basics = resume.at("basics", default: (:))

  let name-parts = _split-name(basics.at("name", default: ""))

  let profile-info = _classify-profiles(basics.at("profiles", default: ()))

  let author = (:)
  author.insert("firstname", name-parts.firstname)
  author.insert("lastname", name-parts.lastname)

  let label = basics.at("label", default: none)
  if label != none and label != "" {
    author.insert("position", label)
  }

  let email = basics.at("email", default: none)
  if email != none { author.insert("email", email) }

  let phone = basics.at("phone", default: none)
  if phone != none { author.insert("phone", phone) }

  let website = basics.at("url", default: none)
  if website != none { author.insert("website", website) }

  let address = _format-address(basics.at("location", default: none))
  if address != none { author.insert("address", address) }

  for (key, value) in profile-info.known.pairs() {
    author.insert(key, value)
  }
  if profile-info.custom.len() > 0 {
    author.insert("custom-links", profile-info.custom)
  }

  (
    author: author,
    sections: resume,
  )
}
