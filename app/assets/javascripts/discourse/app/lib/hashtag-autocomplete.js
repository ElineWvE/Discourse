import { findRawTemplate } from "discourse-common/lib/raw-templates";
import discourseLater from "discourse-common/lib/later";
import { INPUT_DELAY, isTesting } from "discourse-common/config/environment";
import { cancel } from "@ember/runloop";
import { CANCELLED_STATUS } from "discourse/lib/autocomplete";
import { ajax } from "discourse/lib/ajax";
import discourseDebounce from "discourse-common/lib/debounce";
import {
  caretPosition,
  caretRowCol,
  inCodeBlock,
} from "discourse/lib/utilities";
import { search as searchCategoryTag } from "discourse/lib/category-tag-search";

export function setupHashtagAutocomplete(
  orderedContextTypes,
  $textArea,
  siteSettings,
  afterComplete
) {
  if (siteSettings.enable_experimental_hashtag_autocomplete) {
    _setupExperimental(
      orderedContextTypes,
      $textArea,
      siteSettings,
      afterComplete
    );
  } else {
    _setup($textArea, siteSettings, afterComplete);
  }
}

export function hashtagTriggerRule(textarea, opts) {
  const result = caretRowCol(textarea);
  const row = result.rowNum;
  let col = result.colNum;
  let line = textarea.value.split("\n")[row - 1];

  if (opts && opts.backSpace) {
    col = col - 1;
    line = line.slice(0, line.length - 1);

    // Don't trigger autocomplete when backspacing into a `#category |` => `#category|`
    if (/^#{1}\w+/.test(line)) {
      return false;
    }
  }

  // Don't trigger autocomplete when ATX-style headers are used
  if (col < 6 && line.slice(0, col) === "#".repeat(col)) {
    return false;
  }

  if (inCodeBlock(textarea.value, caretPosition(textarea))) {
    return false;
  }

  return true;
}

const checkedHashtags = new Set();
let seenHashtags = {};
export function fetchUnseenHashtagsInContext(orderedContextTypes, slugs) {
  return ajax("/hashtags", {
    data: { slugs, order: orderedContextTypes },
  }).then((response) => {
    seenHashtags = Object.assign(seenHashtags, response);
    slugs.forEach(checkedHashtags.add, checkedHashtags);
  });
}

export function linkSeenHashtagsInContext(orderedContextTypes, elem) {
  const hashtagSpans = [...(elem?.querySelectorAll("span.hashtag") || [])];
  if (hashtagSpans.length === 0) {
    return [];
  }
  const slugs = [...hashtagSpans.map((hashtag) => hashtag.innerText.slice(1))];

  hashtagSpans.forEach((hashtagSpan, index) => {
    let slug = slugs[index];

    // remove type suffixes
    orderedContextTypes.forEach((type) => {
      const typePostfix = `::${type}`;
      if (slug.endsWith(typePostfix)) {
        slug = slug.slice(0, slug.length - typePostfix.length);
      }

      const matchingSeenHashtag = seenHashtags[type].find(
        (ht) => ht.slug === slug
      );
      if (matchingSeenHashtag) {
        // TODO (martin) Replace jquery usage here
        $(hashtagSpan).replaceWith(
          `<a href="${matchingSeenHashtag.url}" class="hashtag" data-type="${type}">#<span>${matchingSeenHashtag.text}</span></a>`
        );
      }
    });
  });

  return slugs
    .map((slug) => slug.toLowerCase())
    .uniq()
    .filter((slug) => !checkedHashtags.has(slug));
}

function _setupExperimental(
  orderedContextTypes,
  $textArea,
  siteSettings,
  afterComplete
) {
  $textArea.autocomplete({
    template: findRawTemplate("hashtag-autocomplete"),
    key: "#",
    afterComplete,
    treatAsTextarea: $textArea[0].tagName === "INPUT",
    transformComplete: (obj) => obj.ref,
    dataSource: (term) => {
      if (term.match(/\s/)) {
        return null;
      }
      return _searchGeneric(term, siteSettings, orderedContextTypes);
    },
    triggerRule: (textarea, opts) => hashtagTriggerRule(textarea, opts),
  });
}

function _setup($textArea, siteSettings, afterComplete) {
  $textArea.autocomplete({
    template: findRawTemplate("category-tag-autocomplete"),
    key: "#",
    afterComplete,
    transformComplete: (obj) => obj.text,
    dataSource: (term) => {
      if (term.match(/\s/)) {
        return null;
      }
      return searchCategoryTag(term, siteSettings);
    },
    triggerRule: (textarea, opts) => hashtagTriggerRule(textarea, opts),
  });
}

let searchCache = {};
let searchCacheTime;
let currentSearch;

function _updateSearchCache(term, results) {
  searchCache[term] = results;
  searchCacheTime = new Date();
  return results;
}

function _searchGeneric(term, siteSettings, orderedContextTypes) {
  if (currentSearch) {
    currentSearch.abort();
    currentSearch = null;
  }
  if (new Date() - searchCacheTime > 30000) {
    searchCache = {};
  }
  const cached = searchCache[term];
  if (cached) {
    return cached;
  }

  return new Promise((resolve) => {
    let timeoutPromise = isTesting()
      ? null
      : discourseLater(() => {
          resolve(CANCELLED_STATUS);
        }, 5000);

    if (term === "") {
      return resolve(CANCELLED_STATUS);
    }

    const debouncedSearch = (q, ctx, resultFunc) => {
      discourseDebounce(this, _searchRequest, q, ctx, resultFunc, INPUT_DELAY);
    };

    debouncedSearch(term, orderedContextTypes, (result) => {
      cancel(timeoutPromise);
      resolve(_updateSearchCache(term, result));
    });
  });
}

function _searchRequest(term, orderedContextTypes, resultFunc) {
  currentSearch = ajax("/hashtags/search.json", {
    data: { term, order: orderedContextTypes },
  });
  currentSearch
    .then((r) => {
      resultFunc(r.results || CANCELLED_STATUS);
    })
    .finally(() => {
      currentSearch = null;
    });
  return currentSearch;
}
