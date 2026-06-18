// Adapter from a JSON Resume document to neat-cv's `cv()` shape.
//
// Pattern mirrors smur89/alta-typst PR #154: validation goes through
// `@preview/gairm-import` so the resume is normalised (and aborts compile
// on schema errors). Unlike alta — which natively consumes the JSON
// Resume shape — neat-cv's `cv()` takes a split `author` dict and an
// imperative body, so this adapter also reshapes the data. The one-call
// wrapper `neat-cv-from-json` lives in lib.typ since it composes `cv`.

#import "@preview/gairm-import:0.8.1": (
  parse as _parse,
  resume-schema-strict,
)


// ---- Helpers ----

/// Split `basics.name` on the first space. Single-word names go entirely
/// into `firstname` with an empty `lastname`. neat-cv displays both in
/// the header with different weights, so we cannot collapse one into
/// the other.
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

/// Format a JSON Resume `location` dict into neat-cv's `address`. The
/// JSON Resume shape is structured (`address`, `city`, `region`,
/// `postalCode`, `countryCode`); neat-cv accepts either a string or
/// content with linebreaks. We render two lines: street/city/region,
/// then postcode + country.
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

/// Compact a JSON Resume `location` dict into a one-line string for use
/// in `entry()`'s `location` slot (work, education, etc.).
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

/// Format a JSON Resume date string ("YYYY", "YYYY-MM", "YYYY-MM-DD")
/// into a short human label. Falls back to the raw string if the shape
/// is unexpected — gairm-import's strict schema already rejected truly
/// malformed values.
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

/// Render a start/end range. Open-ended entries (no `endDate`) render as
/// "Jan 2022 – present" to match the conventions in `template/cv.typ`.
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

/// Map JSON Resume profile `network` values to the keys neat-cv's
/// `cv()` author dict recognises (`twitter`, `mastodon`, `github`,
/// `gitlab`, `linkedin`, `researchgate`, `scholar`, `orcid`). The
/// `username` field is preferred so neat-cv's social helpers can build
/// canonical URLs; for networks we don't know, we keep them as
/// `custom-links` with their full URL.
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
      // Unknown network → custom-link with full URL (falls back to
      // username if no URL is present).
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

/// Validate and reshape a parsed JSON Resume document.
///
/// Returns a dict with `author` (the `cv()` author kwarg) and
/// `sections` (the parsed resume, ready for body rendering).
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
