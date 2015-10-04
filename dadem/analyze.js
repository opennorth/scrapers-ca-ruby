function sorted(id, operators, options, printer) {
  var clone;
  if (operators === undefined) {
    clone = [];
  }
  else {
    clone = operators.slice(0);
  }
  if (options === undefined) {
    options = {};
  }

  clone.push({
    $group: {
      _id: id,
      hits: {$sum: 1}
    }
  });

  sortPrint(db.representatives.aggregate(clone), options, printer);
}

function sortPrint(result, options, printer) {
  var list = [];
  if (!options.map) {
    options.map = {}
  }
  if (options.threshold) {
    var counts = {};
    result.forEach(function (e) {
      if (e._id >= options.threshold) {
        counts[options.threshold + '+'] = (counts[options.threshold + '+'] || 0) + e.hits;
      }
      else {
        counts[e._id] = e.hits;
      }
    });
    result = Object.keys(counts).map(function (_id) {
      return {_id: _id, hits: counts[_id]};
    });
  }
  if (printer === undefined) {
    printer = function (e) {
      var key;
      if (options.map[e[0]]) {
        key = e[0] + ' ' + options.map[e[0]];
      }
      else {
        key = e[0];
      }
      print('       '.substring(0, 7 - e[1].toString().length) + e[1] + '  ' + key);
    }
  }
  result.forEach(function (e) {
    list.push([e._id, e.hits]);
  });
  list.sort(function (a, b) {
    return a[1] - b[1];
  }).forEach(printer);
}

var operators
  , edit_times_threshold = {threshold: 1}
  // @see https://github.com/mysociety/internal-services/blob/master/services/mapit-dadem-loading/dadem_csv_load
  , scraped_types = [
      // EU
      'EUR',
      // Northern Ireland Assembly
      'NIE',
      // Scottish Parliament
      'SPC', 'SPE',
      // Welsh Assembly
      'WAC', 'WAE',
      // UK Parliament
      'WMC', 'HOC',
      // London ward
      'LAC', 'LBW',
    ]
  , date_ranges = [
      ['<2004', {whencreated: {$lt: 1104537600}}],
      ['2005', {whencreated: {$gte: 1104537600, $lt: 1136073600}}],
      ['2006', {whencreated: {$gte: 1136073600, $lt: 1167609600}}],
      ['2007', {whencreated: {$gte: 1167609600, $lt: 1199145600}}],
      ['2008', {whencreated: {$gte: 1199145600, $lt: 1230768000}}],
      ['2009', {whencreated: {$gte: 1230768000, $lt: 1262304000}}],
      ['2010', {whencreated: {$gte: 1262304000, $lt: 1293840000}}],
      ['2011', {whencreated: {$gte: 1293840000, $lt: 1325376000}}],
      ['2012', {whencreated: {$gte: 1325376000, $lt: 1356998400}}],
      ['2013', {whencreated: {$gte: 1356998400, $lt: 1388534400}}],
      ['2014', {whencreated: {$gte: 1388534400, $lt: 1420070400}}],
      ['2015', {whencreated: {$gte: 1420070400, $lt: 1451606400}}],
    ]
  , area_types = { // http://mapit.mysociety.org/#api-by_area_id
      CTY: 'county council',
      CED: 'county ward',
      COI: 'Isles of Scilly',
      COP: 'Isles of Scilly parish',
      CPC: 'civil parish/community',
      CPW: 'civil parish/community ward',
      DIS: 'district council',
      DIW: 'district ward',
      EUR: 'Euro region',
      GLA: 'London Assembly',
      LAC: 'London Assembly constituency',
      LBO: 'London borough',
      LBW: 'London ward',
      LGD: 'NI council',
      LGE: 'NI electoral area',
      LGW: 'NI ward',
      MTD: 'Metropolitan district',
      MTW: 'Metropolitan ward',
      NIE: 'NI Assembly constituency',
      OLF: 'Lower Layer Super Output Area, Full',
      OLG: 'Lower Layer Super Output Area, Generalised',
      OMF: 'Middle Layer Super Output Area, Full',
      OMG: 'Middle Layer Super Output Area, Generalised',
      SPC: 'Scottish Parliament constituency',
      SPE: 'Scottish Parliament region',
      UTA: 'Unitary authority',
      UTE: 'Unitary authority electoral division',
      UTW: 'Unitary authority ward',
      WAC: 'Welsh Assembly constituency',
      WAE: 'Welsh Assembly region',
      WMC: 'UK Parliamentary constituency',
    };

print('\ndeleted:');
sorted('$deleted');

print('\nNONDELETED');
operators = [{
  $match: {
    deleted: 0,
  }
}];

print('\nedit_times:');
sorted('$edit_times', operators, edit_times_threshold);
print('\nlast_editor:');
sorted('$last_editor', operators);
print('\nmethod:');
sorted('$method', operators);

print('\nNONPERSON');
operators = [{
  $match: {
    deleted: 0,
    party: 'NOT A PERSON',
  }
}];

print('\nedit_times:');
sorted('$edit_times', operators, edit_times_threshold);
print('\nlast_editor:');
sorted('$last_editor', operators);
print('\nmethod:');
sorted('$method', operators);
print('\nname:');
sorted('$name', operators);

/*
date_ranges.forEach(function (args) {
  print('\nEMAIL MANUAL ' + args[0]);

  var match = {
    type: {$nin: scraped_types},
    email: {$exists: true},
  };
  for (var key in args[1]) {
    match[key] = args[1][key];
  }

  var operators = [{$match: match}];

  print('\nedit_times:');
  sorted('$edit_times', operators, edit_times_threshold);
  print('\nlast_editor:');
  sorted('$last_editor', operators);
  print('\nmethod:');
  sorted('$method', operators);
  print('\ntype:');
  sorted('$type', operators, {map: area_types});
});
*/

print('\nEMAIL');
operators = [{
  $match: {
    deleted: 0,
    email: {$exists: true},
  }
}];

print('\nedit_times:');
sorted('$edit_times', operators, edit_times_threshold);
print('\nlast_editor:');
sorted('$last_editor', operators);
print('\nmethod:');
sorted('$method', operators);
print('\ntype:');
sorted('$type', operators, {map: area_types});

print('\nEMAIL MANUAL');
operators = [{
  $match: {
    type: {$nin: scraped_types},
    email: {$exists: true},
  }
}];

print('\nedit_times:');
sorted('$edit_times', operators, edit_times_threshold);
print('\nlast_editor:');
sorted('$last_editor', operators);
print('\nmethod:');
sorted('$method', operators);
print('\ntype:');
sorted('$type', operators, {map: area_types});

print('\nWHENCREATED');

date_ranges.forEach(function (args) {
  var match = {
    type: {$nin: scraped_types},
    email: {$exists: true},
  };
  for (var key in args[1]) {
    match[key] = args[1][key];
  }

  var count = db.representatives.count(match);
  print('       '.substring(0, 7 - count.toString().length) + count + ' ' + args[0]);
});

// print('\ntype:');
// sorted('$type', operators, {map: area_types});
// print('\nparty:');
// sorted('$party', operators);
