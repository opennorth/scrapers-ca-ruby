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
// Find non-hret attributes on a tags. (Should be empty.)
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
[ {element: 'question'},
  {element: 'answer'},
  {note: 'resolution'},
  {element: 'speech', note: {$ne: 'resolution'}, fuzzy: {$ne: true}},
  {element: 'speech', note: {$ne: 'resolution'}, fuzzy: true},
  {note: 'division'},
  {element: 'recordedTime'},
  {element: 'heading'},
  {element: 'narrative'}
].forEach(function (selector) {
  selector.text = /<b\b/
  var count = db.speeches.count(selector)
  if (count) {
    print(count + " b tags found: db.speeches.distinct('text', " + JSON.stringify(selector).replace('{}', selector.text) + ")")
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

// {element: 'question'}
// {element: 'answer'}
// {note: 'resolution'}
// {element: 'speech', note: {$ne: 'resolution'}, fuzzy: {$ne: true}}
// {element: 'speech', note: {$ne: 'resolution'}, fuzzy: true}
// {note: 'division'}
// {element: 'recordedTime'}
// {element: 'heading'}
// {element: 'narrative'}

// {from_id: null, from_as: null, from: {$ne: null}} // AN HON. MEMBER:, ANOTHER HON. MEMBER:
// {from_id: null, from: null, from_as: {$ne: null}} // The honourable, SPEAKER'S RULING:
