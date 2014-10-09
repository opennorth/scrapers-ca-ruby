// @see https://github.com/opennorth/represent-canada-quality/blob/master/scripts/log_analyze.js
function sorted(id, operators, threshold) {
  var clone;
  if (operators === undefined) {
    clone = [];
  }
  else {
    clone = operators.slice(0);
  }

  clone.push({
    $group: {
      _id: id,
      hits: {$sum: 1}
    }
  });

  sortPrint(db.speeches.aggregate(clone).result, threshold);
}
function sortPrint(result, threshold) {
  var list = []
  if (threshold === undefined) {
    threshold = 0;
  }
  result.forEach(function (e) {
    if (e.hits >= threshold) {
      list.push([e._id, e.hits]);
    }
  });
  list.sort(function (a, b) {
    return a[1] - b[1];
  }).forEach(function (e) {
    print('       '.substring(0, 7 - e[1].toString().length) + e[1] + '  ' + e[0]);
  });
}

var selector, count;

// Find unexpected square brackets. (Should be empty. 18 known.)
// Ignore [Deputy], [sic] and Hansard references.
selector = {text: /[^cy\d]][^<]*\w/}
count = db.speeches.count(selector)
if (count) {
  print(count + " unexpected square brackets: db.speeches.distinct('html', {text: " + selector.text + "})")
}

// Find attributes on non-a tags. (Should be empty. 1 known use of class="hsd_center".)
selector = {text: /<[^a][^> ]* /}
count = db.speeches.count(selector)
if (count) {
  print(count + " attributes on non-a tags: db.speeches.distinct('html', {text: " + selector.text + "})")
}

// Find non-href attributes on a tags. (Should be empty.)
selector = {$or: [{text: /<a [^h]/}, {text: /<a href="\S+" /}]}
count = db.speeches.count(selector)
if (count) {
  print(count + " attributes on non-a tags: db.speeches.distinct('html', {text: " + selector.text + "})")
}

// Find unexpected tags. (Should be empty.)
//
// * a
// * b
// * blockquote
// * i
// * li
// * p
// * sup
// * u
// * ul
//
// @see https://developer.mozilla.org/en/docs/Web/HTML/Element
[ {text: /<[^\/abilpstu]/},
  {text: /<a\B/}, // a
  {text: /<b[^>l]/}, // b, blockquote (blink)
  {text: /<i\B/}, // i
  {text: /<l[^i]/}, // li (link, listing)
  {text: /<p\B/}, // p
  {text: /<s[^u]/},
  {text: /<su[^p]/}, // sup
  {text: /<t[^adr]/}, // table, td, tr (track)
  {text: /<u[^>l]/} // u, ul
].forEach(function (selector) {
  if (db.speeches.count(selector)) {
    print("New tag found: db.speeches.distinct('html', {text: " + selector.text + "})")
  }
});

// Find b tags, which may indicate a heading within a non-heading.
[ {element: 'heading'},
  {element: 'answer'}, // References to the questions being answered (15)
  {element: 'narrative'}, // 2011-12-09: Repeats a heading when continuing the debate (1)
  {element: 'other'}, // bills under Introduction of Bills
  {element: 'question'}, // 2011-11-02: "ANSWER:" at beginning of two paragraphs (2)
  {element: 'speech'}, // Throne Speech, Budget, Clerk or Assistant Clerk reading bills to Lieutenant Governor (19)
  {division: true},
].forEach(function (selector) {
  if (selector.element == 'speech') {
    selector.text = {$regex: /<b\b/, $not: /\bmet and considered the following bill|\bRULING\b|\bHydro\b/}; // Speaker's Ruling, Hydro-Québec
  }
  else {
    selector.text = /<b\b/;
  }
  var count = db.speeches.count(selector);
  if (count) {
    var criteria = JSON.stringify(selector);
    if (selector.element == 'speech') {
      criteria = criteria.replace('{}', selector.text.$regex).replace('{}', selector.text.$not);
    }
    else {
      criteria = criteria.replace('{}', selector.text);
    }
    print(count + " b tags found: db.speeches.distinct('text', " + criteria + ").sort()");
  }
});

print('Popular headings:');
sorted('$text', [{
  $match: {
    element: 'heading',
    text: {
      $not: /^(Bill|QUESTION|RESOLUTION) /
    }
  }
}], 30);



// If you need to take a close look at specific kinds of speeches:

// {element: 'speech', num: null, fuzzy: true}
// {element: 'speech', num: null, fuzzy: {$ne: true}}
// {element: 'speech', num: {$ne: null}, fuzzy: true} // Resolution
// {element: 'speech', num: {$ne: null}, fuzzy: {$ne: true}} // Resolution
// {from_id: null, from_as: null, from: {$ne: null}} // AN HON. MEMBER:, ANOTHER HON. MEMBER:
// {from_id: null, from: null, from_as: {$ne: null}} // The honourable, SPEAKER'S RULING:
