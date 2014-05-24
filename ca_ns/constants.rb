# Names are not linked if there are errors in the given name or family name, if
# the honorary prefix is missing, unabbreviated or missing a period, or if the
# name is of a role.
TYPOS = {
  # http://nslegislature.ca/index.php/proceedings/hansard/C94/house_14may01/ given name
  'pan eyking' => 'http://nslegislature.ca/index.php/people/members/pam_eyking',
  # http://nslegislature.ca/index.php/proceedings/hansard/C94/house_14apr28/ given name, family name
  'michael samson' => 'http://nslegislature.ca/index.php/people/members/michel_p_samson1',
  'stephen macneil' => 'http://nslegislature.ca/index.php/people/members/Stephen_McNeil',
  # http://nslegislature.ca/index.php/proceedings/hansard/C94/house_14apr16/ family name
  'sterling bellieau' => 'http://nslegislature.ca/index.php/people/members/sterling_belliveau1',
  # http://nslegislature.ca/index.php/proceedings/hansard/C94/house_14mar31/ given name
  'gordon gosse' => 'http://nslegislature.ca/index.php/people/members/gordie_gosse1',
  # http://nslegislature.ca/index.php/proceedings/hansard/C94/house_13dec11/ given name
  'diane whalen' => 'http://nslegislature.ca/index.php/people/members/diana_whalen1',
  # http://nslegislature.ca/index.php/proceedings/hansard/C90/house_13may09/
  'michele raymond' => 'http://nslegislature.ca/index.php/people/members/Michele_Raymond',
  # http://nslegislature.ca/index.php/proceedings/hansard/C90/house_13may08/ given name
  'mailyn more' => 'http://nslegislature.ca/index.php/people/members/Marilyn_More',
  # http://nslegislature.ca/index.php/proceedings/hansard/C89/house_12nov27/ given name
  'sterlng belliveau' => 'http://nslegislature.ca/index.php/people/members/sterling_belliveau1',
  # http://nslegislature.ca/index.php/proceedings/hansard/C89/house_12nov07/ family name
  'bellieveau' => 'http://nslegislature.ca/index.php/people/members/sterling_belliveau1',
  # http://nslegislature.ca/index.php/proceedings/hansard/C89/house_12nov08/ given name
  'jaimie baillie' => 'http://nslegislature.ca/index.php/people/members/jamie_baillie',
  # http://nslegislature.ca/index.php/proceedings/hansard/C89/house_12oct31/ given name
  'bekcy kent' => 'http://nslegislature.ca/index.php/people/members/Becky_Kent',
  # http://nslegislature.ca/index.php/proceedings/hansard/C89/house_12oct25/ family name
  "d'entremount" => 'http://nslegislature.ca/index.php/people/members/christopher_a_dentremont1',
  # http://nslegislature.ca/index.php/proceedings/hansard/C89/house_12may10/ given name
  'mariyln more' => 'http://nslegislature.ca/index.php/people/members/Marilyn_More',
  # http://nslegislature.ca/index.php/proceedings/hansard/C89/house_12apr17/ family name
  'peterson-rayfuse' => 'http://nslegislature.ca/index.php/people/members/Denise_Peterson-Rafuse',
  # http://nslegislature.ca/index.php/proceedings/hansard/C89/house_12apr10/ family name
  'macneil' => 'http://nslegislature.ca/index.php/people/members/Stephen_McNeil',
  # http://nslegislature.ca/index.php/proceedings/hansard/C89/house_12apr04/ family name
  "d'enteremont" => 'http://nslegislature.ca/index.php/people/members/christopher_a_dentremont1',
  # http://nslegislature.ca/index.php/proceedings/hansard/C81/house_12mar29/ role-based
  'sergeant-at-arms' => 'http://nslegislature.ca/index.php/people/offices/sergeant-at-arms',
  # http://nslegislature.ca/index.php/proceedings/hansard/C81/house_11dec06/ given name, role-based
  'vickie conrad' => 'http://nslegislature.ca/index.php/people/members/Vicki_Conrad',
  # Chairman always seems to refer to the Speaker.
  'chairman' => 'http://nslegislature.ca/index.php/people/speaker',
  # http://nslegislature.ca/index.php/proceedings/hansard/C89/house_12dec04/ family name
  'ross laundry' => 'http://nslegislature.ca/index.php/people/members/Ross_Landry',
  # http://nslegislature.ca/index.php/proceedings/hansard/C81/house_11dec02/ family name
  'harold therault' => 'http://nslegislature.ca/index.php/people/members/Harold_Theriault',
  # http://nslegislature.ca/index.php/proceedings/hansard/C81/house_11nov25/ family name
  "christopher d'entromont" => 'http://nslegislature.ca/index.php/people/members/christopher_a_dentremont1',
  # http://nslegislature.ca/index.php/proceedings/hansard/C81/house_11nov23/ family name, family name
  'sterling bellieveau' => 'http://nslegislature.ca/index.php/people/members/sterling_belliveau1',
  'maureen macdonld' => 'http://nslegislature.ca/index.php/people/members/Maureen_MacDonald',
  # http://nslegislature.ca/index.php/proceedings/hansard/C81/house_11nov01/ both names
  'william estabooks' => 'http://nslegislature.ca/index.php/people/members/Bill_Estabrooks',
}

HEADING_TYPOS = {
  'MOTIONS UNDER RULE 5(5)' => 'MOTION UNDER RULE 5(5)',
  'NOTICE OF QUESTION FOR WRITTEN ANSWERS' => 'NOTICE OF QUESTIONS FOR WRITTEN ANSWERS',
  'NOTICES OF MOTION UNDER RULE (32)(3)' => 'NOTICES OF MOTION UNDER RULE 32(3)',
  'ORAL QUESTION PUT BY MEMBERS' => 'ORAL QUESTIONS PUT BY MEMBERS',
  'PRESENTING REPORT OF COMMITTEES' => 'PRESENTING REPORTS OF COMMITTEES',
  'PRESENTING REPORTS OF COMMIITTEES' => 'PRESENTING REPORTS OF COMMITTEES',
  'PRESENTING REPORTS OF COMMITEES' => 'PRESENTING REPORTS OF COMMITTEES',
  'TABLING REPORTS, REGLATIONS AND OTHER PAPERS' => 'TABLING REPORTS, REGULATIONS AND OTHER PAPERS',
  /\AQUESTION No\b/ => 'QUESTION NO',
  /\ARESOLTUION\b/ => 'RESOLUTION',
  /\ARESOLTUTION\b/ => 'RESOLUTION',
  /\ARESOLUION\b/ => 'RESOLUTION',
  /\ARESOLUTION (?=\d)/ => 'RESOLUTION NO. ',
  /\ARESOLUTION NO.(?! )/ => 'RESOLUTION NO. ',
  /\ARESOLUTIONNO\b/ => 'RESOLUTION NO',
  /\ARESOLUTIONS NO\b/ => 'RESOLUTION NO',
  /\ARESOLUTON\b/ => 'RESOLUTION',
}

# @todo count occurrences of each
HEADINGS = [
  'ADJOURNMENT',
  'ANSWERS TO WRITTEN QUESTIONS',
  'COLLABORATIVE EMERGENCY CENTRES',
  'COMMITTEE ON ASSEMBLY MATTERS',
  'COMMUNITY SERVICES',
  'ECONOMIC DEVELOPMENT',
  'ELIGIBILITY BREAKDOWN',
  'GOVERNMENT BUSINESS',
  'GOVERNMENT MOTIONS',
  'GOVERNMENT NOTICES OF MOTION',
  'HUMAN RESOURCES',
  'INQUIRY TERMS OF REF.',
  'INTL. DAY FOR ELIMINATION OF VIOLENCE AGAINST WOMEN',
  'INTERNAL AFFAIRS',
  'INTRODUCTION OF BILLS',
  'LAW AMENDMENTS',
  'MOTION UNDER RULE 43',
  'MOTION UNDER RULE 5(5)',
  'MOTIONS OTHER THAN GOVERNMENT MOTIONS',
  'NOTICE OF QUESTIONS FOR WRITTEN ANSWERS',
  'NOTICES OF MOTION',
  'NOTICES OF MOTION UNDER RULE 32(3)',
  'ON MOTION FOR SUPPLY',
  "OPPOSITION MEMBERS' BUSINESS",
  'ORAL QUESTIONS PUT BY MEMBERS',
  'ORAL QUESTIONS PUT BY MEMBERS TO MINISTERS',
  'ORDERS OF THE DAY',
  'PRESENTING AND READING PETITIONS',
  'PRESENTING REPORTS OF COMMITTEES',
  'PRIVATE AND LOCAL BILLS',
  'PRIVATE AND LOCAL BILLS FOR SECOND READING',
  'PRIVATE AND LOCAL BILLS FOR THIRD READING',
  "PRIVATE MEMBERS' PUBLIC BILLS FOR SECOND READING",
  "PRIVATE MEMBERS' PUBLIC BILLS FOR THIRD READING",
  'PUBLIC ACCOUNTS',
  'PUBLIC BILLS FOR SECOND READING',
  'PUBLIC BILLS FOR THIRD READING',
  'PURSUANT TO RULE 30',
  'RESOURCES',
  'RESPONSIBILITY ASSUME',
  'STANDING COMMITTEES OF THE HOUSE OF ASSEMBLY',
  'STATEMENTS BY MINISTERS',
  'TABLING REPORTS, REGULATIONS AND OTHER PAPERS',
  'VETERANS AFFAIRS',
]

HEADINGS_RE = [
  /\ABill No\. \d+ - /,
  /\AQUESTION NO\. \d+\z/,
  /\ARESOLUTION NO\. \d+\z/,
  /\ATabled \S+ \d{1,2}, 201\d\z/,
]